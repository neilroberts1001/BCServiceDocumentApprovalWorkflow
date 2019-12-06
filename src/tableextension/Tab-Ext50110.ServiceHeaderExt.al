tableextension 50110 "ServiceHeaderExt" extends "Service Header"
{
    fields
    {
        field(50120; "Approval Status"; Option)
        {
            Caption = 'Approval Status';
            OptionMembers = Open,Released,"Pending Approval";
        }
        field(50121; "Amount Including VAT"; Decimal)
        {
            Caption = 'Amount Including VAT';
            FieldClass = FlowField;
            CalcFormula = sum ("Service Line"."Amount Including VAT" where("Document Type" = field("Document Type"), "Document No." = field("No.")));
            Editable = false;
        }

    }
}