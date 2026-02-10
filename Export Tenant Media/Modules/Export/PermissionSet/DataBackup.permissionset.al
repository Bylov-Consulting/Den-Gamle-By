namespace DGB;

permissionset 90000 DataBackup
{
    Assignable = true;
    Permissions = tabledata "Admission Card Owner DGB" = RIMD,
        table "Admission Card Owner DGB" = X,
    tabledata "Media Export Configuration" = RIMD,
    table "Media Export Configuration" = X,
    tabledata "Media Export Log" = RIMD,
    table "Media Export Log" = X,
    tabledata "Media Export Setup" = RIMD,
    table "Media Export Setup" = X,
        page "Adm. Card Owner Picture DGB" = X,
    page "Media Export Configuration" = X,
    page "Media Export Log" = X,
    page "Media Export Setup" = X,
    page "Media Export Status" = X,
        page "Admission Card Owner DGB Card" = X,
        page "Admission Card Owners DGB" = X;
}