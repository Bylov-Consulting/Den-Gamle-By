codeunit 90006 "Media Export Mgt."
{
    /// <summary>
    /// Exports images from the configured media field on the specified table.
    /// </summary>
    /// <param name="TableId">The table ID to export from.</param>
    procedure ExportImages(TableId: Integer)
    var
        ExportConfig: Record "Media Export Configuration";
        ZipBlob: Codeunit "Temp Blob";
        ExportedCount: Integer;
        ZipName: Text;
        ContinueExport: Boolean;
        TotalRemaining: Integer;
        BatchSize: Integer;
        ImageFieldNo: Integer;
        FileNameFieldNo: Integer;
        LastSystemId: Guid;
    begin
        if not ExportConfig.Get(TableId) then
            Error(NoExportConfigErr, TableId);

        ImageFieldNo := ExportConfig."Image Field ID";
        FileNameFieldNo := ExportConfig."File Name Field ID";
        BatchSize := GetBatchSize();
        TotalRemaining := CountEligibleRecords(TableId, ImageFieldNo, FileNameFieldNo, LastSystemId);
        if TotalRemaining = 0 then begin
            ShowNoImagesMessage();
            exit;
        end;

        ContinueExport := true;
        while ContinueExport and (TotalRemaining > 0) do begin
            ExecuteBatch(TableId, ImageFieldNo, FileNameFieldNo, BatchSize, ZipName, ZipBlob, ExportedCount, LastSystemId);

            if ExportedCount = 0 then begin
                ShowNoImagesMessage();
                exit;
            end;

            DownloadZip(ZipName, ZipBlob);
            ContinueExport := ConfirmContinueExport();
            if not ContinueExport then
                exit;

            TotalRemaining := CountEligibleRecords(TableId, ImageFieldNo, FileNameFieldNo, LastSystemId);
        end;
    end;

    /// <summary>
    /// Gets the count of eligible records to export for the specified table.
    /// </summary>
    /// <param name="TableId">The table ID to count records for.</param>
    /// <returns>The number of records with unexported media.</returns>
    procedure GetEligibleRecordsCount(TableId: Integer): Integer
    var
        ExportConfig: Record "Media Export Configuration";
        ImageFieldNo: Integer;
        FileNameFieldNo: Integer;
        LastSystemId: Guid;
    begin
        if not ExportConfig.Get(TableId) then
            exit(0);

        ImageFieldNo := ExportConfig."Image Field ID";
        FileNameFieldNo := ExportConfig."File Name Field ID";
        exit(CountEligibleRecords(TableId, ImageFieldNo, FileNameFieldNo, LastSystemId));
    end;

    local procedure ExecuteBatch(TableId: Integer; ImageFieldNo: Integer; FileNameFieldNo: Integer; BatchSize: Integer; var ZipName: Text; var ZipBlob: Codeunit "Temp Blob"; var ExportedCount: Integer; var LastSystemId: Guid)
    begin
        Clear(ZipBlob);
        ExportedCount := 0;
        ZipName := '';
        ExportBatch(TableId, ImageFieldNo, FileNameFieldNo, BatchSize, ZipName, ZipBlob, ExportedCount, LastSystemId);
    end;

    local procedure ShowNoImagesMessage()
    begin
        Message(NoImagesMsg);
    end;

    local procedure ConfirmContinueExport(): Boolean
    begin
        exit(Confirm(ContinueExportQst, true));
    end;

    local procedure ExportBatch(TableId: Integer; ImageFieldNo: Integer; FileNameFieldNo: Integer; BatchSize: Integer; var ZipName: Text; var ZipBlob: Codeunit "Temp Blob"; var ExportedCount: Integer; var LastSystemId: Guid)
    var
        DataCompression: Codeunit "Data Compression";
        RecRef: RecordRef;
        EntryOutStream: OutStream;
        ProgressDialog: Dialog;
        BaseFileName: Text;
        BatchTimestamp: DateTime;
        RecordSystemId: Guid;
    begin
        if ImageFieldNo = 0 then
            Error(ImageFieldNotFoundErr, ImageFieldNo, TableId);

        DataCompression.CreateZipArchive();
        ProgressDialog.Open(ExportingImagesTxt);
        BatchTimestamp := CurrentDateTime();

        OpenRecordView(TableId, RecRef, LastSystemId);
        if RecRef.FindSet() then
            repeat
                if not RecordHasMedia(RecRef, ImageFieldNo) then
                    continue;

                RecordSystemId := GetRecordSystemId(RecRef);
                LastSystemId := RecordSystemId;
                BaseFileName := GetRecordFileName(RecRef, FileNameFieldNo, RecordSystemId);
                ExportedCount += AddMediaEntries(TableId, RecordSystemId, RecRef, ImageFieldNo, BaseFileName, DataCompression, BatchTimestamp);
                if ExportedCount > 0 then begin
                    ProgressDialog.Update(1, ExportedCount);
                    ProgressDialog.Update(2, BatchSize);

                    if ExportedCount >= BatchSize then
                        break;
                end;
            until RecRef.Next() = 0;

        ProgressDialog.Close();
        RecRef.Close();

        if ExportedCount > 0 then begin
            ZipName := BuildZipName(TableId, ExportedCount);
            ZipBlob.CreateOutStream(EntryOutStream);
            DataCompression.SaveZipArchive(EntryOutStream);
            UpdateZipNameForBatch(TableId, BatchTimestamp, ZipName);
        end;
    end;

    local procedure AddMediaEntries(TableId: Integer; RecordSystemId: Guid; var RecRef: RecordRef; ImageFieldNo: Integer; BaseFileName: Text; var DataCompression: Codeunit "Data Compression"; BatchTimestamp: DateTime): Integer
    var
        TenantMediaSet: Record "Tenant Media Set";
        PictureTempBlob: Codeunit "Temp Blob";
        MediaId: Guid;
        MediaSetId: Guid;
        PictureInStream: InStream;
        PictureOutStream: OutStream;
        EntryName: Text;
        ExportedInRecord: Integer;
    begin
        if GetMediaValue(RecRef, ImageFieldNo, MediaId) then begin
            EntryName := BaseFileName + '.jpg';
            if not IsImageExported(TableId, RecordSystemId, EntryName) then begin
                AddMediaById(MediaId, EntryName, DataCompression);
                LogExport(TableId, RecordSystemId, BatchTimestamp, EntryName, '');
                exit(1);
            end;

            exit(0);
        end;

        if GetMediaSetValue(RecRef, ImageFieldNo, MediaSetId) then begin
            TenantMediaSet.SetRange(ID, MediaSetId);
            if TenantMediaSet.FindSet() then
                repeat
                    Clear(PictureTempBlob);
                    PictureTempBlob.CreateOutStream(PictureOutStream);
                    TenantMediaSet."Media ID".ExportStream(PictureOutStream);
                    PictureTempBlob.CreateInStream(PictureInStream);
                    EntryName := StrSubstNo(MediaSetEntryNameLbl, BaseFileName, TenantMediaSet."Media Index");
                    if not IsImageExported(TableId, RecordSystemId, EntryName) then begin
                        DataCompression.AddEntry(PictureInStream, EntryName);
                        LogExport(TableId, RecordSystemId, BatchTimestamp, EntryName, '');
                        ExportedInRecord += 1;
                    end;
                until TenantMediaSet.Next() = 0;
        end;

        exit(ExportedInRecord);
    end;

    local procedure GetMediaValue(var RecRef: RecordRef; ImageFieldNo: Integer; var MediaId: Guid): Boolean
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(ImageFieldNo);
        if FieldRef.Type = FieldType::Media then begin
            MediaId := FieldRef.Value;
            exit(not IsNullGuid(MediaId));
        end;

        exit(false);
    end;

    local procedure GetMediaSetValue(var RecRef: RecordRef; ImageFieldNo: Integer; var MediaSetId: Guid): Boolean
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(ImageFieldNo);
        if FieldRef.Type = FieldType::MediaSet then begin
            MediaSetId := FieldRef.Value;
            exit(not IsNullGuid(MediaSetId));
        end;

        exit(false);
    end;

    local procedure RecordHasMedia(var RecRef: RecordRef; ImageFieldNo: Integer): Boolean
    var
        TenantMediaSet: Record "Tenant Media Set";
        MediaId: Guid;
        MediaSetId: Guid;
    begin
        if GetMediaValue(RecRef, ImageFieldNo, MediaId) then
            exit(true);

        if GetMediaSetValue(RecRef, ImageFieldNo, MediaSetId) then begin
            TenantMediaSet.SetRange(ID, MediaSetId);
            exit(not TenantMediaSet.IsEmpty());
        end;

        exit(false);
    end;

    local procedure AddMediaById(MediaId: Guid; EntryName: Text; var DataCompression: Codeunit "Data Compression")
    var
        TenantMedia: Record "Tenant Media";
        PictureInStream: InStream;
    begin
        if IsNullGuid(MediaId) then
            exit;

        if not TenantMedia.Get(MediaId) then
            exit;

        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateInStream(PictureInStream);
        DataCompression.AddEntry(PictureInStream, EntryName);
    end;

    local procedure LogExport(TableId: Integer; RecordSystemId: Guid; ExportTimestamp: DateTime; ImageFileName: Text; ZipFileName: Text)
    var
        ExportLog: Record "Media Export Log";
    begin
        if ExportLog.Get(TableId, RecordSystemId, ImageFileName) then
            exit;

        ExportLog.Init();
        ExportLog."Table ID" := TableId;
        ExportLog."System ID" := RecordSystemId;
        ExportLog."Export Timestamp" := ExportTimestamp;
        ExportLog."Image File Name" := CopyStr(ImageFileName, 1, MaxStrLen(ExportLog."Image File Name"));
        ExportLog."Zip File Name" := CopyStr(ZipFileName, 1, MaxStrLen(ExportLog."Zip File Name"));
        ExportLog.Insert(true);
    end;

    local procedure IsImageExported(TableId: Integer; RecordSystemId: Guid; ImageFileName: Text): Boolean
    var
        ExportLog: Record "Media Export Log";
    begin
        exit(ExportLog.Get(TableId, RecordSystemId, ImageFileName));
    end;

    local procedure UpdateZipNameForBatch(TableId: Integer; BatchTimestamp: DateTime; ZipName: Text)
    var
        ExportLog: Record "Media Export Log";
    begin
        ExportLog.SetRange("Table ID", TableId);
        ExportLog.SetRange("Export Timestamp", BatchTimestamp);
        ExportLog.ModifyAll("Zip File Name", CopyStr(ZipName, 1, MaxStrLen(ExportLog."Zip File Name")));
    end;

    local procedure CountEligibleRecords(TableId: Integer; ImageFieldNo: Integer; FileNameFieldNo: Integer; StartSystemId: Guid): Integer
    var
        RecRef: RecordRef;
        Counter: Integer;
        BaseFileName: Text;
        RecordSystemId: Guid;
    begin
        if ImageFieldNo = 0 then
            exit(0);

        OpenRecordView(TableId, RecRef, StartSystemId);
        if RecRef.FindSet() then
            repeat
                if RecordHasMedia(RecRef, ImageFieldNo) then begin
                    RecordSystemId := GetRecordSystemId(RecRef);
                    BaseFileName := GetRecordFileName(RecRef, FileNameFieldNo, RecordSystemId);
                    Counter += CountUnexportedImages(TableId, RecordSystemId, RecRef, ImageFieldNo, BaseFileName);
                end;
            until RecRef.Next() = 0;

        RecRef.Close();
        exit(Counter);
    end;

    local procedure CountUnexportedImages(TableId: Integer; RecordSystemId: Guid; var RecRef: RecordRef; ImageFieldNo: Integer; BaseFileName: Text): Integer
    var
        TenantMediaSet: Record "Tenant Media Set";
        MediaId: Guid;
        MediaSetId: Guid;
        EntryName: Text;
        Remaining: Integer;
    begin
        if GetMediaValue(RecRef, ImageFieldNo, MediaId) then begin
            EntryName := BaseFileName + '.jpg';
            if not IsImageExported(TableId, RecordSystemId, EntryName) then
                exit(1);

            exit(0);
        end;

        if GetMediaSetValue(RecRef, ImageFieldNo, MediaSetId) then begin
            TenantMediaSet.SetRange(ID, MediaSetId);
            if TenantMediaSet.FindSet() then
                repeat
                    EntryName := StrSubstNo(MediaSetEntryNameLbl, BaseFileName, TenantMediaSet."Media Index");
                    if not IsImageExported(TableId, RecordSystemId, EntryName) then
                        Remaining += 1;
                until TenantMediaSet.Next() = 0;
        end;

        exit(Remaining);
    end;

    local procedure OpenRecordView(TableId: Integer; var RecRef: RecordRef; StartSystemId: Guid)
    begin
        RecRef.Open(TableId);
        ApplyStartSystemIdFilter(RecRef, StartSystemId);
    end;

    local procedure ApplyStartSystemIdFilter(var RecRef: RecordRef; StartSystemId: Guid)
    var
        FieldRef: FieldRef;
    begin
        if IsNullGuid(StartSystemId) then
            exit;

        FieldRef := RecRef.Field(2000000000);
        FieldRef.SetFilter('>%1', Format(StartSystemId));
    end;

    local procedure GetRecordSystemId(var RecRef: RecordRef): Guid
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(2000000000);
        exit(FieldRef.Value);
    end;

    local procedure GetRecordFileName(var RecRef: RecordRef; FileNameFieldNo: Integer; RecordSystemId: Guid): Text
    var
        RecordIdText: Text;
        FileNameValue: Text;
    begin
        if FileNameFieldNo <> 0 then
            if RecRef.Field(FileNameFieldNo).Type in [FieldType::Code, FieldType::Text] then
                FileNameValue := Format(RecRef.Field(FileNameFieldNo).Value);

        if FileNameValue = '' then
            FileNameValue := Format(RecordSystemId);

        RecordIdText := SanitizeFileName(FileNameValue);
        if RecordIdText = '' then
            RecordIdText := SanitizeFileName(Format(RecordSystemId));

        exit(RecordIdText);
    end;

    local procedure SanitizeFileName(FileName: Text): Text
    begin
        exit(ConvertStr(FileName, '\/:*?"<>|', '_________'));
    end;

    local procedure BuildZipName(TableId: Integer; ExportedCount: Integer): Text
    begin
        exit(StrSubstNo(ZipNamePatternLbl, TableId, ExportedCount, Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2><Seconds,2>')));
    end;

    local procedure DownloadZip(ZipName: Text; var ZipBlob: Codeunit "Temp Blob")
    var
        InS: InStream;
    begin
        ZipBlob.CreateInStream(InS);
        DownloadFromStream(InS, '', '', '', ZipName);
    end;

    /// <summary>
    /// Returns the configured batch size from Media Export Setup.
    /// </summary>
    procedure GetBatchSize(): Integer
    var
        ExportSetup: Record "Media Export Setup";
    begin
        if not ExportSetup.Get() then
            Error(BatchSizeNotConfiguredErr);

        if ExportSetup."Batch Size" <= 0 then
            Error(BatchSizeNotConfiguredErr);

        exit(ExportSetup."Batch Size");
    end;

    var
        NoExportConfigErr: Label 'No export configuration found for table %1.', Comment = '%1 = Table ID.';
        NoImagesMsg: Label 'No images found to export.';
        ContinueExportQst: Label 'Do you want to continue exporting the next batch of records?';
        ImageFieldNotFoundErr: Label 'Image field %1 not found on table %2.', Comment = '%1 = Field ID, %2 = Table ID.';
        ExportingImagesTxt: Label 'Exporting images...\\Processed #1#### of #2####.', Comment = '#1 = Processed count, #2 = Batch size.';
        MediaSetEntryNameLbl: Label '%1_%2.jpg', Comment = '%1 = Base file name, %2 = Media index.';
        ZipNamePatternLbl: Label 'Export_%1_%2_%3.zip', Comment = '%1 = Table ID, %2 = Exported count, %3 = Timestamp.';
        BatchSizeNotConfiguredErr: Label 'Batch size is not configured. Open the Media Export Setup page and set a batch size.';
}
