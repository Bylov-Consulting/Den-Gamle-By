table 90004 "Media Export Configuration"
{
    Caption = 'Media Export Configuration';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
            TableRelation = "AllObjWithCaption"."Object ID" where("Object Type" = const(Table));
        }
        field(2; "Table Name"; Text[100])
        {
            Caption = 'Table Name';
            FieldClass = FlowField;
            CalcFormula = lookup("AllObjWithCaption"."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
        }
        field(3; "Image Field ID"; Integer)
        {
            Caption = 'Image Field ID';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where("TableNo" = field("Table ID"), "Type" = filter(Media | MediaSet));
        }
        field(4; "Image Field Name"; Text[100])
        {
            Caption = 'Image Field Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."FieldName" where("TableNo" = field("Table ID"), "No." = field("Image Field ID")));
        }
        field(5; "File Name Field ID"; Integer)
        {
            Caption = 'File Name Field ID';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where("TableNo" = field("Table ID"), "Type" = filter(Code | Text));
        }
        field(6; "File Name Field Name"; Text[100])
        {
            Caption = 'File Name Field Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."FieldName" where("TableNo" = field("Table ID"), "No." = field("File Name Field ID")));
        }
        field(7; "Eligible Records Count"; Integer)
        {
            Caption = 'Eligible Records Count';
            Editable = false;
            FieldClass = Normal;
        }
        field(8; "Exported Records Count"; Integer)
        {
            Caption = 'Exported Records Count';
            FieldClass = FlowField;
            CalcFormula = count("Media Export Log" where("Table ID" = field("Table ID")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Table ID")
        {
            Clustered = true;
        }
    }

    procedure UpdateEligibleRecordsCount()
    var
        MediaExportMgt: Codeunit "Media Export Mgt.";
    begin
        Rec."Eligible Records Count" := MediaExportMgt.GetEligibleRecordsCount(Rec."Table ID");
    end;
}
