page 90007 "Media Export Status"
{
    Caption = 'Media Export Status';
    PageType = List;
    SourceTable = "Media Export Configuration";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the table containing media to export.';
                }
                field("Image Field Name"; Rec."Image Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the field containing the media.';
                }
                field("File Name Field Name"; Rec."File Name Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the field used for file naming. If blank, System ID will be used.';
                }
                field("Eligible Records Count"; Rec."Eligible Records Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of records with media that have not been exported yet.';
                    Style = Attention;
                    StyleExpr = Rec."Eligible Records Count" > 0;
                }
                field("Exported Records Count"; Rec."Exported Records Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of records that have been exported.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportImages)
            {
                ApplicationArea = All;
                Caption = 'Export Images';
                ToolTip = 'Export images from the selected table configuration.';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    MediaExportMgt: Codeunit "Media Export Mgt.";
                begin
                    MediaExportMgt.ExportImages(Rec."Table ID");
                    CurrPage.Update(false);
                end;
            }
            action(RefreshStatus)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                ToolTip = 'Refresh the eligible records count.';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    UpdateAllCounts();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(ExportLog)
            {
                ApplicationArea = All;
                Caption = 'Export Log';
                ToolTip = 'View the export log for this configuration.';
                Image = Log;
                RunObject = page "Media Export Log";
                RunPageLink = "Table ID" = field("Table ID");
            }
            action(Configuration)
            {
                ApplicationArea = All;
                Caption = 'Edit Configuration';
                ToolTip = 'Edit the export configuration.';
                Image = Setup;
                RunObject = page "Media Export Configuration";
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.UpdateEligibleRecordsCount();
        Rec.CalcFields("Exported Records Count");
    end;

    trigger OnOpenPage()
    begin
        UpdateAllCounts();
    end;

    local procedure UpdateAllCounts()
    begin
        if Rec.FindSet(true) then
            repeat
                Rec.UpdateEligibleRecordsCount();
                Rec.CalcFields("Exported Records Count");
                Rec.Modify();
            until Rec.Next() = 0;
    end;
}
