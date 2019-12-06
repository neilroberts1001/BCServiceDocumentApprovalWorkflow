codeunit 50110 "ServiceDocWorkflowEvents"
{
    //Workflow Events
    procedure RunWorkflowOnSendServiceDocumentForApprovalCode(): Code[128];
    begin
        exit(UPPERCASE('RunWorkflowOnSendServiceDocumentForApproval'));
    end;

    procedure RunWorkflowOnCancelServiceDocumentForApprovalCode(): Code[128];
    begin
        exit(UPPERCASE('RunWorkflowOnCancelServiceDocumentApprovalRequest'));
    end;

    procedure SetStatusToPendingApprovalCode(): Code[128];
    begin
        exit(UPPERCASE('SetStatusToServiceDocumentPendingApproval'));
    end;

    procedure OpenDocumentCode(): Code[128];
    begin
        exit(UPPERCASE('OpenServiceDocument'));
    end;

    procedure ReleaseDocumentCode(): Code[128];
    begin
        exit(UPPERCASE('ReleaseServiceDocument'));
    end;

    local procedure SetStatusToPendingApproval(var Variant: Variant);
    var
        ServiceHeader: Record "Service Header";
        RecRef: RecordRef;
    begin
        RecRef.GETTABLE(Variant);

        case RecRef.NUMBER of
            Database::"Service Header":
                begin
                    RecRef.SETTABLE(ServiceHeader);
                    ServiceHeader."Approval Status" := ServiceHeader."Approval Status"::"Pending Approval";
                    ServiceHeader.Modify();
                    Variant := ServiceHeader;
                end;
            else
                Error(UnsupportedRecordTypeErr, RecRef.CAPTION);
        end;
    end;

    local procedure OpenDocument(var Variant: Variant);
    var
        ApprovalEntry: Record "Approval Entry";
        ServiceHeader: Record "Service Header";
        RecRef: RecordRef;
        TargetRecRef: RecordRef;
    begin
        RecRef.GETTABLE(Variant);

        case RecRef.NUMBER of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    TargetRecRef.Get(ApprovalEntry."Record ID to Approve");
                    Variant := TargetRecRef;
                    OpenDocument(Variant);
                end;
            Database::"Service Header":
                begin
                    ServiceHeader := Variant;
                    if ServiceHeader."Approval Status" = ServiceHeader."Approval Status"::Open then begin
                        exit;
                    end;
                    ServiceHeader."Approval Status" := ServiceHeader."Approval Status"::Open;
                    ServiceHeader.Modify(true);
                end;
            else
                Error(UnsupportedRecordTypeErr, RecRef.CAPTION);
        end;
    end;

    local procedure ReleaseDocument(var Variant: Variant);
    var
        ApprovalEntry: Record "Approval Entry";
        ServiceHeader: Record "Service Header";
        RecRef: RecordRef;
        TargetRecRef: RecordRef;
    begin
        RecRef.GETTABLE(Variant);

        case RecRef.NUMBER of
            Database::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    TargetRecRef.Get(ApprovalEntry."Record ID to Approve");
                    Variant := TargetRecRef;
                    ReleaseDocument(Variant);
                end;
            Database::"Service Header":
                begin
                    ServiceHeader := Variant;
                    if ServiceHeader."Approval Status" = ServiceHeader."Approval Status"::Released then begin
                        exit;
                    end;
                    ServiceHeader."Approval Status" := ServiceHeader."Approval Status"::Released;
                    ServiceHeader.Modify(true);
                end;
            else
                Error(UnsupportedRecordTypeErr, RecRef.CAPTION);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    procedure AddEventsToLibrary();
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        //Events
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnSendServiceDocumentForApprovalCode, Database::"Service Header", 'Approval of a service document is requested.', 0, false);
        WorkflowEventHandling.AddEventToLibrary(RunWorkflowOnCancelServiceDocumentForApprovalCode, Database::"Service Header", 'An approval request for a service document is canceled.', 0, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsesToLibrary', '', false, false)]
    procedure AddResponsesToLibrary();
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        //Responses
        WorkflowResponseHandling.AddResponseToLibrary(SetStatusToPendingApprovalCode, 0, 'Set service document approval status to Pending Approval', 'NR50120');
        WorkflowResponseHandling.AddResponseToLibrary(OpenDocumentCode, 0, 'Reopen the service document', 'NR50120');
        WorkflowResponseHandling.AddResponseToLibrary(ReleaseDocumentCode, 0, 'Release the service document', 'NR50120');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsePredecessorsToLibrary', '', false, false)]
    procedure AddWorkflowEventResponseCombinationsToLibrary(ResponseFunctionName: Code[128]);
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        case ResponseFunctionName of
            SetStatusToPendingApprovalCode:
                WorkflowResponseHandling.AddResponsePredecessor(SetStatusToPendingApprovalCode, RunWorkflowOnSendServiceDocumentForApprovalCode);
            OpenDocumentCode:
                WorkflowResponseHandling.AddResponsePredecessor(OpenDocumentCode, RunWorkflowOnCancelServiceDocumentForApprovalCode);
            ReleaseDocumentCode:
                WorkflowResponseHandling.AddResponsePredecessor(ReleaseDocumentCode, RunWorkflowOnSendServiceDocumentForApprovalCode);

            WorkflowResponseHandling.CreateApprovalRequestsCode:
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CreateApprovalRequestsCode, RunWorkflowOnSendServiceDocumentForApprovalCode);
            WorkflowResponseHandling.SendApprovalRequestForApprovalCode:
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.SendApprovalRequestForApprovalCode, RunWorkflowOnSendServiceDocumentForApprovalCode);

            WorkflowResponseHandling.CancelAllApprovalRequestsCode:
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.CancelAllApprovalRequestsCode, RunWorkflowOnCancelServiceDocumentForApprovalCode);

            WorkflowResponseHandling.ApproveAllApprovalRequestsCode:
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.ApproveAllApprovalRequestsCode, RunWorkflowOnSendServiceDocumentForApprovalCode);
            WorkflowResponseHandling.RejectAllApprovalRequestsCode:
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.RejectAllApprovalRequestsCode, RunWorkflowOnSendServiceDocumentForApprovalCode);
            WorkflowResponseHandling.RestrictRecordUsageCode:
                WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponseHandling.RestrictRecordUsageCode, RunWorkflowOnSendServiceDocumentForApprovalCode);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventPredecessorsToLibrary', '', false, false)]
    procedure AddWorkflowEventPredecessorsToLibrary(EventFunctionName: Code[128]);
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        case EventFunctionName of
            WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode:
                begin
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode, RunWorkflowOnSendServiceDocumentForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode, ReleaseDocumentCode);
                end;
            WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode:
                begin
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode, RunWorkflowOnSendServiceDocumentForApprovalCode);
                    WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode, OpenDocumentCode);
                end;
            WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode:
                WorkflowEventHandling.AddEventPredecessor(WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode, RunWorkflowOnSendServiceDocumentForApprovalCode);
        end;

    end;

    procedure OnSendServiceDocumentForApproval(var ServiceHeader: Record "Service Header");
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnSendServiceDocumentForApprovalCode, ServiceHeader);
    end;

    procedure OnCancelServiceDocumentApprovalRequest(var ServiceHeader: Record "Service Header");
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        WorkflowManagement.HandleEvent(RunWorkflowOnCancelServiceDocumentForApprovalCode, ServiceHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    procedure OnExecuteResponse(var ResponseExecuted: Boolean; Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance");
    var
        WorkflowResponse: Record "Workflow Response";
    begin
        if WorkflowResponse.Get(ResponseWorkflowStepInstance."Function Name") then begin
            case WorkflowResponse."Function Name" of
                ReleaseDocumentCode:
                    ReleaseDocument(Variant);
                OpenDocumentCode:
                    OpenDocument(Variant);
                SetStatusToPendingApprovalCode:
                    SetStatusToPendingApproval(Variant);
            end;
        end;
        ResponseExecuted := true;
    end;

    procedure OnCheckRestriction(var Rec: Record "Service Header");
    var
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        RecordRestrictionMgt.CheckRecordHasUsageRestrictions(Rec);
    end;

    procedure CheckServiceDocumentApprovalWorkflowEnabled(var ServiceHeader: Record "Service Header"): Boolean;
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        if not WorkflowManagement.CanExecuteWorkflow(ServiceHeader, RunWorkflowOnSendServiceDocumentForApprovalCode) then begin
            Error(NoWorkflowEnabledErr);
        end;

        exit(true);
    end;

    //Event Subscribers
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnAfterIsSufficientApprover', '', false, false)]
    local procedure OnAfterIsSufficientApprover(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"; var IsSufficient: Boolean)
    begin
        case ApprovalEntryArgument."Table ID" of
            Database::"Service Header":
                IsSufficient := IsSufficientServiceApprover(UserSetup, ApprovalEntryArgument."Amount (LCY)");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', false, false)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        case RecRef.Number of
            Database::"Service Header":
                begin
                    RecRef.SetTable(ServiceHeader);

                    ApprovalEntryArgument."Document Type" := ServiceHeader."Document Type";
                    ApprovalEntryArgument."Document No." := ServiceHeader."No.";
                    ApprovalEntryArgument."Salespers./Purch. Code" := ServiceHeader."Salesperson Code";
                    ApprovalEntryArgument."Currency Code" := ServiceHeader."Currency Code";

                    ServiceLine.Reset();
                    ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
                    ServiceLine.SetRange("Document No.", ServiceHeader."No.");
                    if ServiceLine.Find('-') then begin
                        repeat
                            ApprovalEntryArgument.Amount += ServiceLine."Amount Including VAT";
                            ApprovalEntryArgument."Amount (LCY)" += ServiceLine."Amount Including VAT";
                        until ServiceLine.Next() = 0;
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnBeforePostWithLines', '', false, false)]
    local procedure OnBeforePostWithLines(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    begin
        if PassedServHeader."Approval Status" = PassedServHeader."Approval Status"::"Pending Approval" then begin
            Error(Text002);
        end else begin
            ReleaseServiceDoc(PassedServHeader);
        end;
    end;

    //Normal Functions
    local procedure IsSufficientServiceApprover(UserSetup: Record "User Setup"; ApprovalAmountLCY: Decimal): Boolean
    begin
        if UserSetup."User ID" = UserSetup."Approver ID" then
            exit(true);

        if UserSetup."Unlimited Sales Approval" or
           ((ApprovalAmountLCY <= UserSetup."Sales Amount Approval Limit") and (UserSetup."Sales Amount Approval Limit" <> 0))
        then
            exit(true);

        exit(false);
    end;

    procedure ReopenServiceDoc(var ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Approval Status" = ServiceHeader."Approval Status"::Open then begin
            exit;
        end;

        if ServiceHeader."Approval Status" = ServiceHeader."Approval Status"::"Pending Approval" then begin
            Error(Text001);
        end;

        ServiceHeader."Approval Status" := ServiceHeader."Approval Status"::Open;
        ServiceHeader.Modify();
    end;

    procedure ReleaseServiceDoc(var ServiceHeader: Record "Service Header")
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        if ServiceHeader."Approval Status" = ServiceHeader."Approval Status"::Released then begin
            exit;
        end;

        if ServiceHeader."Approval Status" <> ServiceHeader."Approval Status"::Open then begin
            Error(Text002);
        end;

        if WorkflowManagement.CanExecuteWorkflow(ServiceHeader, RunWorkflowOnSendServiceDocumentForApprovalCode) then begin
            Error(Text002);
        end;

        ServiceHeader."Approval Status" := ServiceHeader."Approval Status"::Released;
        ServiceHeader.Modify();
    end;

    var
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        Text001: Label 'The approval process must be cancelled or completed to reopen this document.';
        Text002: Label 'This document can only be released when the approval process is complete.';
        UnsupportedRecordTypeErr: Label 'Record type %1 is not supported by this workflow response.', Comment = 'Record type Customer is not supported by this workflow response.';

}