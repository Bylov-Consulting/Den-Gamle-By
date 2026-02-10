page 90010 "Media Export Log"
{
    Caption = 'Media Export Log';
    PageType = List;
    SourceTable = "Media Export Log";
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table ID for the exported record.';
                }
                field("System ID"; Rec."System ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the system ID for the exported record.';
                }
                field(RecordIdText; RecordIdText)
                {
                    ApplicationArea = All;
                    Caption = 'Record ID';
                    ToolTip = 'Specifies the record ID resolved from the system ID.';
                }
                field("Export Timestamp"; Rec."Export Timestamp")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the record was exported.';
                }
                field("Zip File Name"; Rec."Zip File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the zip file name that contains the exported image.';
                }
                field("Image File Name"; Rec."Image File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the exported image file name.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RecordIdText := GetRecordIdText();
    end;

    trigger OnOpenPage()
    begin
        AllowLogDeletion := GetAllowLogDeletion();
        CurrPage.Editable := AllowLogDeletion;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if not AllowLogDeletion then
            Error(DeleteNotAllowedErr);

        exit(true);
    end;

    local procedure GetRecordIdText(): Text
    var
        RecordRef: RecordRef;
        ResolvedRecordId: RecordId;
    begin
        if (Rec."Table ID" = 0) or IsNullGuid(Rec."System ID") then
            exit('');

        RecordRef.Open(Rec."Table ID");
        if not RecordRef.GetBySystemId(Rec."System ID") then begin
            RecordRef.Close();
            exit('');
        end;

        ResolvedRecordId := RecordRef.RecordId;
        RecordRef.Close();

        exit(Format(ResolvedRecordId));
    end;

    local procedure GetAllowLogDeletion(): Boolean
    var
        ExportSetup: Record "Media Export Setup";
    begin
        if not ExportSetup.Get() then
            exit(false);

        exit(ExportSetup."Allow Export Log Deletion");
    end;

    var
        RecordIdText: Text;
        AllowLogDeletion: Boolean;
        DeleteNotAllowedErr: Label 'Deletion of export log entries is not allowed by setup.';
}
