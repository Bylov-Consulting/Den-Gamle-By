page 90002 "Admission Card Owner DGB Card"
{
    Caption = 'Admission Card Owner DGB';
    PageType = Card;
    SourceTable = "Admission Card Owner DGB";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the card owner number.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer name.';
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the first name.';
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last name.';
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an alternative name.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company name.';
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the full name.';
                }
                field("Birth Date"; Rec."Birth Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the birth date.';
                }
                field(Gender; Rec.Gender)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the gender.';
                }
                field("Contact Person"; Rec."Contact Person")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the contact person.';
                }
            }
            group(AddressContactGroup)
            {
                Caption = 'Address & Contact';

                group(AddressGroup)
                {
                    Caption = 'Address';

                    field(Address; Rec.Address)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the address.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the country/region code.';
                    }
                    field(County; Rec.County)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the county.';
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the post code.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the city.';
                    }
                }
                group(Contact)
                {
                    Caption = 'Contact';

                    field("Phone No."; Rec."Phone No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the phone number.';
                    }
                    field("E-Mail"; Rec."E-Mail")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the email address.';
                    }
                }
            }
            group(Additional)
            {
                Caption = 'Additional Information';

                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer number.';
                }
                field("Newsletter Consent Date"; Rec."Newsletter Consent Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the newsletter consent date.';
                }
                field("Linked Cards UID"; Rec."Linked Cards UID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the linked cards unique identifier.';
                }
                field(Anonymized; Rec.Anonymized)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the record is anonymized.';
                }
                field("Last Modified Date Time"; Rec."Last Modified Date Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the record was last modified.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series.';
                }
            }
        }
        area(Factboxes)
        {
            part(CardOwnerPicture; "Adm. Card Owner Picture DGB")
            {
                Caption = 'Picture';
                SubPageLink = "No." = field("No.");
                ApplicationArea = All;
            }
            systempart(LinksPart; Links)
            {
                Visible = false;
                ApplicationArea = All;
            }
            systempart(NotesPart; Notes)
            {
                Visible = true;
                ApplicationArea = All;
            }
        }
    }
}
