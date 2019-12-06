codeunit 50111 "InstallServiceDocApproval"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        WorkflowTableRel: Record "Workflow - Table Relation";
        ServiceHeader: Record "Service Header";
        ApprovalEntry: Record "Approval Entry";
    begin
        if not WorkflowTableRel.Get(Database::"Service Header", 0, Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve")) then begin
            WorkflowTableRel.Init();
            WorkflowTableRel.Validate("Table ID", Database::"Service Header");
            WorkflowTableRel.Validate("Field ID", 0);
            WorkflowTableRel.Validate("Related Table ID", Database::"Approval Entry");
            WorkflowTableRel.Validate("Related Field ID", ApprovalEntry.FieldNo("Record ID to Approve"));
            WorkflowTableRel.Insert(true);
        end;
    end;
}