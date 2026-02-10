table 90008 "Media Export Setup"
{
    Caption = 'Media Export Setup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Batch Size"; Integer)
        {
            Caption = 'Batch Size';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if "Batch Size" <= 0 then
                    Error(BatchSizeMustBePositiveErr);
            end;
        }
        field(3; "Allow Export Log Deletion"; Boolean)
        {
            Caption = 'Allow Export Log Deletion';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        BatchSizeMustBePositiveErr: Label 'Batch size must be greater than 0.';
}
