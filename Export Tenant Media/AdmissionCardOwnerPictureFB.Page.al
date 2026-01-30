page 90003 "Adm. Card Owner Picture DGB"
{
    Caption = 'Picture';
    PageType = CardPart;
    SourceTable = "Admission Card Owner DGB";

    layout
    {
        area(content)
        {
            field(Picture; Rec.Picture)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the picture.';
                ShowCaption = false;
            }
        }
    }
}
