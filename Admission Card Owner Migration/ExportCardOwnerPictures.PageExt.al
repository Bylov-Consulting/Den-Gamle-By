pageextension 90011 ExportCardOwnerPictures extends "Admission Card Owners"
{
    actions
    {
        addafter(RenewAdmCard)
        {
            action(ExportAllTenantMedia)
            {
                Caption = 'Export Admission Card Owner Pictures';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Export;
                ApplicationArea = All;
                trigger OnAction()
                var
                    InS: InStream;
                    OutS: OutStream;
                    TempBlob: Codeunit "Temp Blob";
                    PictureTempBlob: Codeunit "Temp Blob";
                    FileName: Text;
                    ZipFileName: Text;
                    DataCompression: Codeunit "Data Compression";
                    AdmissionCardOwners: Record "Admission Card Owner";
                    AdmissionCardOwnersCounter: record "Admission Card Owner";
                    PictureInStream: InStream;
                    PictureOutStream: OutStream;
                    ProgressDialog: Dialog;
                    Counter: Integer;
                    TotalRecords: Integer;
                    PicturesProcessed: Integer;
                    PercentComplete: Decimal;
                    ExitExport: Boolean;
                    CountingCounter: Integer;
                    TotalOwners: Integer;
                    CountingPercent: Decimal;
                    StartTime: DateTime;
                    EndTime: DateTime;
                    Duration: Duration;
                    DurationMsg: Text;
                begin
                    StartTime := CurrentDateTime;
                    DataCompression.CreateZipArchive();
                    ZipFileName := 'AdmissionCardOwnerPictures - ' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2><Seconds,2>') + '.zip';

                    // Count records with pictures
                    TotalOwners := AdmissionCardOwnersCounter.Count();
                    CountingCounter := 0;
                    ProgressDialog.Open('Counting admission card owners with pictures...\Checked #1#### of #2####. Progress: #3##%');
                    TotalRecords := 0;
                    if AdmissionCardOwnersCounter.FindSet() then
                        repeat
                            CountingCounter += 1;
                            CountingPercent := Round(CountingCounter / TotalOwners * 100, 1);
                            ProgressDialog.Update(1, CountingCounter);
                            ProgressDialog.Update(2, TotalOwners);
                            ProgressDialog.Update(3, CountingPercent);

                            if AdmissionCardOwnersCounter.Picture.HasValue then
                                TotalRecords += 1;
                        until AdmissionCardOwnersCounter.Next() = 0;
                    ProgressDialog.Close();

                    Counter := 0;
                    PicturesProcessed := 0;

                    ProgressDialog.Open('Exporting pictures...\Processed #1#### of #2####. Progress: #3##%');

                    if AdmissionCardOwners.FindSet() then
                        repeat
                            Counter += 1;
                            PercentComplete := Round(Counter / TotalRecords * 100, 1);

                            ProgressDialog.Update(1, Counter);
                            ProgressDialog.Update(2, TotalRecords);
                            ProgressDialog.Update(3, PercentComplete);

                            if AdmissionCardOwners.Picture.HasValue then begin
                                PicturesProcessed += 1;

                                // Export picture to a TempBlob
                                Clear(PictureTempBlob);
                                PictureTempBlob.CreateOutStream(PictureOutStream);
                                AdmissionCardOwners.Picture.ExportStream(PictureOutStream);

                                // Get InStream from the TempBlob and add to ZIP
                                PictureTempBlob.CreateInStream(PictureInStream);
                                FileName := AdmissionCardOwners."No." + '.jpg';
                                DataCompression.AddEntry(PictureInStream, FileName);

                                // Check if 100 pictures have been processed
                                if PicturesProcessed = 1000 then begin
                                    ProgressDialog.Close();
                                    ExitExport := Confirm('100 pictures have been processed.\Do you want to download the current file and exit?', true);
                                    if not ExitExport then
                                        ProgressDialog.Open('Exporting pictures...\Processed #1#### of #2####. Progress: #3##%');
                                end;

                            end;

                        until (AdmissionCardOwners.Next() = 0) or ExitExport;

                    if not ExitExport then
                        ProgressDialog.Close();

                    // Save ZIP to TempBlob and download
                    TempBlob.CreateOutStream(OutS);
                    DataCompression.SaveZipArchive(OutS);
                    TempBlob.CreateInStream(InS);
                    DownloadFromStream(InS, '', '', '', ZipFileName);

                    // Calculate and display duration
                    EndTime := CurrentDateTime;
                    Duration := EndTime - StartTime;
                    DurationMsg := StrSubstNo('Export completed!\\Pictures exported: %1\Duration: %2', PicturesProcessed, Format(Duration));
                    Message(DurationMsg);
                end;
            }
            action(CopyToDGB)
            {
                Caption = 'Copy to DGB Table';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Copy;
                ApplicationArea = All;
                trigger OnAction()
                var
                    AdmissionCardOwnerMigration: Codeunit "Admission Card Owner Migration";
                begin
                    AdmissionCardOwnerMigration.CopyToDGBTable();
                end;
            }
            action(CopySingleToDGB)
            {
                Caption = 'Copy Selected to DGB Table';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = CopyItem;
                ApplicationArea = All;
                trigger OnAction()
                var
                    AdmissionCardOwnerMigration: Codeunit "Admission Card Owner Migration";
                    AdmissionCardOwner: Record "Admission Card Owner";
                begin
                    CurrPage.SetSelectionFilter(AdmissionCardOwner);
                    if AdmissionCardOwner.FindFirst() then
                        AdmissionCardOwnerMigration.CopySingleToDGBTable(AdmissionCardOwner."No.");
                end;
            }
        }
    }
}