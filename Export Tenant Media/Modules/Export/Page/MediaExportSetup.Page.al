page 90008 "Media Export Setup"
{
    Caption = 'Media Export Setup';
    PageType = Card;
    SourceTable = "Media Export Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Batch Size"; Rec."Batch Size")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many records are exported per batch.';
                }
                field("Allow Export Log Deletion"; Rec."Allow Export Log Deletion")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether records can be deleted from the export log.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert(true);
        end;
    end;
}
