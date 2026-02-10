table 90001 "Admission Card Owner DGB"
{
    Caption = 'Admission Card Owner DGB';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(2; "First Name"; Text[50])
        {
            Caption = 'First Name';
            DataClassification = CustomerContent;
        }
        field(3; "Last Name"; Text[50])
        {
            Caption = 'Last Name';
            DataClassification = CustomerContent;
        }
        field(4; "Full Name"; Text[100])
        {
            Caption = 'Full Name';
            DataClassification = CustomerContent;
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            DataClassification = CustomerContent;
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            DataClassification = CustomerContent;
        }
        field(7; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            DataClassification = CustomerContent;
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
            DataClassification = CustomerContent;
        }
        field(9; County; Text[30])
        {
            Caption = 'County';
            DataClassification = CustomerContent;
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = CustomerContent;
        }
        field(11; "E-Mail"; Text[80])
        {
            Caption = 'E-mail';
            DataClassification = CustomerContent;
        }
        field(12; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            DataClassification = CustomerContent;
        }
        field(13; "Birth Date"; Date)
        {
            Caption = 'Birth Date';
            DataClassification = CustomerContent;
        }
        field(14; Gender; Enum "Gender DGB")
        {
            Caption = 'Gender';
            DataClassification = CustomerContent;
        }
        field(15; Picture; Media)
        {
            Caption = 'Picture';
            DataClassification = CustomerContent;
        }
        field(16; "Newsletter Consent Date"; Date)
        {
            Caption = 'Newsletter Consent Date';
            DataClassification = CustomerContent;
        }
        field(17; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            DataClassification = CustomerContent;
        }
        field(20; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
        }
        field(30; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = CustomerContent;
        }
        field(31; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            DataClassification = CustomerContent;
        }
        field(32; "Contact Person"; Code[20])
        {
            Caption = 'Contact Person';
            DataClassification = CustomerContent;
        }
        field(40; "Name 2"; Text[100])
        {
            Caption = 'Name 2';
            DataClassification = CustomerContent;
        }
        field(41; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
            DataClassification = CustomerContent;
        }
        field(45; "Linked Cards UID"; Guid)
        {
            Caption = 'Linked Cards UID';
            DataClassification = CustomerContent;
        }
        field(60; Anonymized; Boolean)
        {
            Caption = 'Anonymized';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "First Name", "Last Name")
        {
        }
        fieldgroup(Brick; "No.", "Full Name", City, Picture)
        {
        }
    }
}
