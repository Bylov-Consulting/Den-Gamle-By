table 90005 "Media Export Log"
{
    Caption = 'Media Export Log';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
        }
        field(2; "System ID"; Guid)
        {
            Caption = 'System ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Export Timestamp"; DateTime)
        {
            Caption = 'Export Timestamp';
            DataClassification = SystemMetadata;
        }
        field(4; "Zip File Name"; Text[250])
        {
            Caption = 'Zip File Name';
            DataClassification = SystemMetadata;
        }
        field(5; "Image File Name"; Text[250])
        {
            Caption = 'Image File Name';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Table ID", "System ID", "Image File Name")
        {
            Clustered = true;
        }
    }
}
