page 90009 "Media Field Lookup"
{
    Caption = 'Media Field Lookup';
    PageType = List;
    SourceTable = Field;
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field number.';
                }
                field("Field Name"; Rec."FieldName")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field name.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field caption.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field type.';
                }
            }
        }
    }
}
