codeunit 50112 "ServiceDocApprovalMgt"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnAfterIsSufficientApprover', '', false, false)]
    local procedure OnAfterIsSufficientApprover(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"; var IsSufficient: Boolean)
    var
        ServiceHeader: Record "Service Header";
        RecRef: RecordRef;
    begin
        RecRef.Get(ApprovalEntryArgument."Record ID to Approve");
        RecRef.SetTable(ServiceHeader);
        IsSufficient := IsSufficientPurchReqAprrover(UserSetup, ApprovalEntryArgument."Amount (LCY)");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', false, false)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ServiceHeader: Record "Service Header";
    begin
        RecRef.SetTable(ServiceHeader);
        ServiceHeader.CalcFields("Amount Including VAT");

        ApprovalEntryArgument."Document Type" := ServiceHeader."Document Type";
        ApprovalEntryArgument."Document No." := ServiceHeader."No.";
        ApprovalEntryArgument."Salespers./Purch. Code" := ServiceHeader."Salesperson Code";
        ApprovalEntryArgument.Amount := ServiceHeader."Amount Including VAT";
        ApprovalEntryArgument."Amount (LCY)" := ServiceHeader."Amount Including VAT";
    end;

    procedure IsSufficientPurchReqAprrover(UserSetup: Record "User Setup"; ApprovalAmountLCY: Decimal): Boolean;
    begin
        if UserSetup."User ID" = UserSetup."Approver ID" then
            exit(true);

        if UserSetup."Unlimited Request Approval" or ((ApprovalAmountLCY <= UserSetup."Request Amount Approval Limit") and (UserSetup."Request Amount Approval Limit" <> 0)) then
            exit(true);

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Notification Management", 'OnGetDocumentTypeAndNumber', '', false, false)]
    local procedure OnGetDocumentTypeAndNumber(var RecRef: RecordRef; var DocumentType: Text; var DocumentNo: Text; var IsHandled: Boolean)
    var
        ServiceHeader: Record "Service Header";
        FieldRef: FieldRef;
    begin
        if RecRef.Number = Database::"Service Header" then begin
            FieldRef := RecRef.Field(ServiceHeader.FieldNo("Document Type"));
            DocumentType := Format(FieldRef.Value);
            FieldRef := RecRef.Field(ServiceHeader.FieldNo("No."));
            DocumentNo := Format(FieldRef.Value());

            IsHandled := true;
        end;
    end;
}