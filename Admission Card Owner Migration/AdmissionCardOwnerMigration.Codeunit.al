codeunit 90011 "Admission Card Owner Migration"
{
    /// <summary>
    /// Copies all admission card owners to the DGB table.
    /// </summary>
    procedure CopyToDGBTable()
    var
        AdmissionCardOwner: Record "Admission Card Owner";
        AdmissionCardOwnerDGB: Record "Admission Card Owner DGB";
        ProgressDialog: Dialog;
        Counter: Integer;
        TotalRecords: Integer;
        RecordsSkipped: Integer;
        RecordsCopied: Integer;
        RecordsFailed: Integer;
        PercentComplete: Decimal;
        CommitBatchSize: Integer;
    begin
        CommitBatchSize := 100; // Commit every 100 records
        TotalRecords := AdmissionCardOwner.Count();
        Counter := 0;
        RecordsSkipped := 0;
        RecordsCopied := 0;
        RecordsFailed := 0;

        ProgressDialog.Open(CopyingRecordsTxt);

        if AdmissionCardOwner.FindSet() then
            repeat
                Counter += 1;
                PercentComplete := Round(Counter / TotalRecords * 100, 1);
                ProgressDialog.Update(1, Counter);
                ProgressDialog.Update(2, TotalRecords);
                ProgressDialog.Update(3, PercentComplete);

                // Check if record already exists in DGB table
                if not AdmissionCardOwnerDGB.Get(AdmissionCardOwner."No.") then begin
                    // Use error handling for each record
                    if TryCopySingleRecord(AdmissionCardOwner) then
                        RecordsCopied += 1
                    else begin
                        RecordsFailed += 1;
                        // Log error but continue processing
                    end;
                end else
                    RecordsSkipped += 1;

                ProgressDialog.Update(4, RecordsCopied);
                ProgressDialog.Update(5, RecordsSkipped);
                ProgressDialog.Update(6, RecordsFailed);

                // Commit every N records to preserve progress
                if (RecordsCopied mod CommitBatchSize) = 0 then
                    Commit();

            until AdmissionCardOwner.Next() = 0;

        // Final commit for remaining records
        Commit();

        ProgressDialog.Close();
        Message(CopyCompletedMsg, RecordsCopied, RecordsSkipped, RecordsFailed);
    end;

    [TryFunction]
    local procedure TryCopySingleRecord(var SourceRecord: Record "Admission Card Owner")
    var
        DestRecord: Record "Admission Card Owner DGB";
    begin
        DestRecord.Init();
        DestRecord.TransferFields(SourceRecord, true);
        // Clear Picture to avoid shared media reference
        Clear(DestRecord.Picture);
        DestRecord.Insert(true);

        // Copy the picture by creating a new media entry
        CopyPictureToDestination(SourceRecord, DestRecord);
    end;

    local procedure CopyPictureToDestination(var SourceRecord: Record "Admission Card Owner"; var DestRecord: Record "Admission Card Owner DGB")
    var
        TempBlob: Codeunit "Temp Blob";
        PictureInStream: InStream;
        PictureOutStream: OutStream;
    begin
        // Check if source has a picture
        if not SourceRecord.Picture.HasValue then
            exit;

        // Export picture from source to TempBlob
        Clear(TempBlob);
        TempBlob.CreateOutStream(PictureOutStream);
        SourceRecord.Picture.ExportStream(PictureOutStream);

        // Import picture from TempBlob to destination (creates new media entry)
        TempBlob.CreateInStream(PictureInStream);
        DestRecord.Picture.ImportStream(PictureInStream, 'Picture_' + DestRecord."No." + '.jpg');
        DestRecord.Modify(true);
    end;

    /// <summary>
    /// Copies a single admission card owner to the DGB table.
    /// </summary>
    /// <param name="CardOwnerNo">The card owner number to copy.</param>
    /// <returns>True if the record was copied; otherwise, false.</returns>
    procedure CopySingleToDGBTable(CardOwnerNo: Code[20]): Boolean
    var
        AdmissionCardOwner: Record "Admission Card Owner";
        AdmissionCardOwnerDGB: Record "Admission Card Owner DGB";
    begin
        // Check if source record exists
        if not AdmissionCardOwner.Get(CardOwnerNo) then begin
            Message(CardOwnerNotFoundMsg, CardOwnerNo);
            exit(false);
        end;

        // Check if record already exists in DGB table
        if AdmissionCardOwnerDGB.Get(CardOwnerNo) then begin
            Message(RecordAlreadyExistsMsg, CardOwnerNo);
            exit(false);
        end;

        // Copy the record
        AdmissionCardOwnerDGB.Init();
        AdmissionCardOwnerDGB.TransferFields(AdmissionCardOwner, true);
        // Clear Picture to avoid shared media reference
        Clear(AdmissionCardOwnerDGB.Picture);
        AdmissionCardOwnerDGB.Insert(true);

        // Copy the picture by creating a new media entry
        CopyPicture(AdmissionCardOwner, AdmissionCardOwnerDGB);

        Message(RecordCopiedMsg, CardOwnerNo);
        exit(true);
    end;

    local procedure CopyPicture(var SourceRecord: Record "Admission Card Owner"; var DestRecord: Record "Admission Card Owner DGB")
    var
        TempBlob: Codeunit "Temp Blob";
        PictureInStream: InStream;
        PictureOutStream: OutStream;
    begin
        // Check if source has a picture
        if not SourceRecord.Picture.HasValue then
            exit;

        // Export picture from source to TempBlob
        Clear(TempBlob);
        TempBlob.CreateOutStream(PictureOutStream);
        SourceRecord.Picture.ExportStream(PictureOutStream);

        // Import picture from TempBlob to destination (creates new media entry)
        TempBlob.CreateInStream(PictureInStream);
        DestRecord.Picture.ImportStream(PictureInStream, 'Picture_' + DestRecord."No." + '.jpg');
        DestRecord.Modify(true);
    end;
    var
        CopyingRecordsTxt: Label 'Copying records to DGB table...\\Processed #1#### of #2####. Progress: #3##%\\Copied: #4#### | Skipped: #5#### | Failed: #6####';
        CopyCompletedMsg: Label 'Copy completed!\\Records copied: %1\\Records skipped: %2\\Records failed: %3', Comment = '%1 = Copied, %2 = Skipped, %3 = Failed.';
        CardOwnerNotFoundMsg: Label 'Admission Card Owner %1 not found.', Comment = '%1 = Card owner number.';
        RecordAlreadyExistsMsg: Label 'Record %1 already exists in DGB table.', Comment = '%1 = Card owner number.';
        RecordCopiedMsg: Label 'Record %1 successfully copied to DGB table.', Comment = '%1 = Card owner number.';
}
