pageextension 90007 "Adm Card Owners DGB Exp" extends "Admission Card Owners DGB"
{
    actions
    {
        addlast(Processing)
        {
            action(ExportImages)
            {
                ApplicationArea = All;
                Caption = 'Export Images';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Export images from the current list to a zip file.';
                trigger OnAction()
                var
                    ExportMgt: Codeunit "Media Export Mgt.";
                begin
                    ExportMgt.ExportImages(Database::"Admission Card Owner DGB");
                end;
            }
        }
    }
}
