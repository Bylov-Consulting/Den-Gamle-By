pageextension 90011 ExportCardOwnerPictures extends "Admission Card Owners"
{
    actions
    {
        addafter(RenewAdmCard)
        {
            action(CopyToDGB)
            {
                Caption = 'Copy to DGB Table';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Copy;
                ApplicationArea = All;
                ToolTip = 'Executes the Copy to DGB Table action.';
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
                ToolTip = 'Executes the Copy Selected to DGB Table action.';
                trigger OnAction()
                var
                    AdmissionCardOwner: Record "Admission Card Owner";
                    AdmissionCardOwnerMigration: Codeunit "Admission Card Owner Migration";
                begin
                    CurrPage.SetSelectionFilter(AdmissionCardOwner);
                    if AdmissionCardOwner.FindFirst() then
                        AdmissionCardOwnerMigration.CopySingleToDGBTable(AdmissionCardOwner."No.");
                end;
            }
        }
    }
}