pageextension 90012 ExportCardOwnerPicturesDGB extends "Admission Card Owners DGB"
{
    actions
    {
        addfirst(Processing)
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
        }
    }
}