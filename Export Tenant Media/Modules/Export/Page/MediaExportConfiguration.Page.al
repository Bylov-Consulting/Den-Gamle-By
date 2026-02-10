page 90004 "Media Export Configuration"
{
    Caption = 'Media Export Configuration';
    PageType = List;
    SourceTable = "Media Export Configuration";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table ID to export from.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a descriptive table name.';
                }
                field("Image Field ID"; Rec."Image Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the media field to export.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FieldRec: Record Field;
                        FieldLookup: Page "Media Field Lookup";
                    begin
                        if Rec."Table ID" = 0 then
                            exit(false);

                        FieldRec.SetRange(TableNo, Rec."Table ID");
                        FieldRec.SetFilter(Type, '%1|%2', FieldRec.Type::Media, FieldRec.Type::MediaSet);
                        FieldLookup.SetTableView(FieldRec);
                        FieldLookup.LookupMode(true);

                        if FieldLookup.RunModal() = Action::LookupOK then begin
                            FieldLookup.GetRecord(FieldRec);
                            Rec.Validate("Image Field ID", FieldRec."No.");
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field("Image Field Name"; Rec."Image Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Displays the media field name for the selected field ID.';
                }
                field("File Name Field ID"; Rec."File Name Field ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which field value is used to name the exported files.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FieldRec: Record Field;
                        FieldLookup: Page "Media Field Lookup";
                    begin
                        if Rec."Table ID" = 0 then
                            exit(false);

                        FieldRec.SetRange(TableNo, Rec."Table ID");
                        FieldRec.SetFilter(Type, '%1|%2', FieldRec.Type::Code, FieldRec.Type::Text);
                        FieldLookup.SetTableView(FieldRec);
                        FieldLookup.LookupMode(true);

                        if FieldLookup.RunModal() = Action::LookupOK then begin
                            FieldLookup.GetRecord(FieldRec);
                            Rec.Validate("File Name Field ID", FieldRec."No.");
                            CurrPage.Update(true);
                        end;

                    end;
                }
                field("File Name Field Name"; Rec."File Name Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Displays the file name field for the selected field ID.';
                }
            }
        }
    }
}
