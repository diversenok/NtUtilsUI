unit NtUiFrame.Security.Acl;

{
  This module provides a control for viewing/editing ACLs on securable objects.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, NtUiFrame,
  NtUiFrame.Acl, Ntapi.WinNt, NtUtils, NtUiCommon.Prototypes, System.Actions,
  Vcl.ActnList, NtUiCommon.Interfaces;

type
  TAclType = (aiDacl, aiLabel, aiTrust, aiSacl, aiAttribute, aiScope, aiFilter);

  TAclSecurityFrame = class(TFrame, IHasDefaultCaption, ICanConsumeEscape, IObservesActivation)
    AclFrame: TAclFrame;
    btnRefresh: TButton;
    btnApply: TButton;
    GroupBox: TGroupBox;
    cbxInherited: TCheckBox;
    cbxProtected: TCheckBox;
    cbxInheritReq: TCheckBox;
    cbxDefaulted: TCheckBox;
    cbxPresent: TCheckBox;
    ActionList: TActionList;
    ActionRefresh: TAction;
    procedure btnRefreshClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
  private
    FAclType: TAclType;
    FContext: TNtUiLibSecurityContext;
    function GetControlFlags: TSecurityDescriptorControl;
    procedure SetControlFlags(const Value: TSecurityDescriptorControl);
    function Refresh: TNtxStatus;
    function Apply: TNtxStatus;
    function GetDefaultCaption: String;
    procedure SetActive(Active: Boolean);
    function GetCanConsumeEscapeImpl: ICanConsumeEscape;
    property CanConsumeEscapeImpl: ICanConsumeEscape read GetCanConsumeEscapeImpl implements ICanConsumeEscape;
  public
    procedure LoadFor(
      AclType: TAclType;
      const Context: TNtUiLibSecurityContext
    );
  end;

// Construct a frame initilizer for an ACL security editor
function NtUiLibAclSecurityFrameInitializer(
  AclType: TAclType;
  const Context: TNtUiLibSecurityContext
): TFrameInitializer;

implementation

uses
  NtUtils.Security;

{$R *.dfm}

const
  FLAG_PRESENT: array [Boolean] of TSecurityDescriptorControl = (
    SE_SACL_PRESENT, SE_DACL_PRESENT);

  FLAG_DEFAULTED: array [Boolean] of TSecurityDescriptorControl = (
    SE_SACL_DEFAULTED, SE_DACL_DEFAULTED);

  FLAG_INHERIT_REQ: array [Boolean] of TSecurityDescriptorControl = (
    SE_SACL_AUTO_INHERIT_REQ, SE_DACL_AUTO_INHERIT_REQ);

  FLAG_INHERITED: array [Boolean] of TSecurityDescriptorControl = (
    SE_SACL_AUTO_INHERITED, SE_DACL_AUTO_INHERITED);

  FLAG_PROTECTED: array [Boolean] of TSecurityDescriptorControl = (
    SE_SACL_PROTECTED, SE_DACL_PROTECTED);

  SECURITY_INFORMATION: array [TAclType] of TSecurityInformation = (
    DACL_SECURITY_INFORMATION, LABEL_SECURITY_INFORMATION,
    PROCESS_TRUST_LABEL_SECURITY_INFORMATION, SACL_SECURITY_INFORMATION,
    ATTRIBUTE_SECURITY_INFORMATION, SCOPE_SECURITY_INFORMATION,
    ACCESS_FILTER_SECURITY_INFORMATION
  );

  ACL_CAPTIONS: array [TAclType] of String = (
    'DACL', 'Mandatory Label', 'Trust Label', 'SACL', 'Resource Attributes',
    'Scoped Policy', 'Access Filter'
  );

{ TAclSecurityFrame }

function TAclSecurityFrame.Apply;
var
  hxObject: IHandle;
  SD: TSecurityDescriptorData;
  SecDesc: ISecurityDescriptor;
begin
  if not Assigned(FContext.HandleProvider) or
    not Assigned(FContext.QueryFunction) then
    raise Exception.Create('ACL Security frame not initialized');

  // Start building a security descriptor
  SD := Default(TSecurityDescriptorData);
  SD.Control := GetControlFlags;

  if FAclType = aiDacl then
    Result := AclFrame.GetAcl(SD.Dacl)
  else
    Result := AclFrame.GetAcl(SD.Sacl);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxAllocateSecurityDescriptor(SD, SecDesc);

  if not Result.IsSuccess then
    Exit;

  // Open the handle
  Result := FContext.HandleProvider(hxObject, SecurityReadAccess(
    SECURITY_INFORMATION[FAclType]));

  if not Result.IsSuccess then
    Exit;

  // Apply the security descriptor
  Result := FContext.SetFunction(hxObject.Handle,
    SECURITY_INFORMATION[FAclType], SecDesc.Data);

  if not Result.IsSuccess then
    Exit;

  Refresh;
end;

procedure TAclSecurityFrame.btnApplyClick;
begin
  Apply.RaiseOnError;
end;

procedure TAclSecurityFrame.btnRefreshClick;
begin
  Refresh.RaiseOnError;
end;

function TAclSecurityFrame.GetCanConsumeEscapeImpl;
begin
  Result := AclFrame;
end;

function TAclSecurityFrame.GetControlFlags;
begin
  Result := 0;

  if cbxPresent.Checked then
    Result := Result or FLAG_PRESENT[FAclType = aiDacl];

  if cbxDefaulted.Checked then
    Result := Result or FLAG_DEFAULTED[FAclType = aiDacl];

  if cbxInheritReq.Checked then
    Result := Result or FLAG_INHERIT_REQ[FAclType = aiDacl];

  if cbxInherited.Checked then
    Result := Result or FLAG_INHERITED[FAclType = aiDacl];

  if cbxProtected.Checked then
    Result := Result or FLAG_PROTECTED[FAclType = aiDacl];
end;

function TAclSecurityFrame.GetDefaultCaption;
begin
  Result := ACL_CAPTIONS[FAclType];
end;

procedure TAclSecurityFrame.LoadFor;
begin
  if AclType > High(TAclType) then
    raise Exception.Create('Invalid ACL type');

  FAclType := AclType;
  FContext := Context;
  Refresh;
end;

function TAclSecurityFrame.Refresh;
var
  hxObject: IHandle;
  SecDesc: ISecurityDescriptor;
  SD: TSecurityDescriptorData;
begin
  if not Assigned(FContext.HandleProvider) or
    not Assigned(FContext.QueryFunction) then
    raise Exception.Create('ACL Security frame not initialized');

  // Reset UI state
  SetControlFlags(0);
  AclFrame.LoadAcl(nil, FContext.AccessMaskType, FContext.GenericMapping);

  // Open the handle
  Result := FContext.HandleProvider(hxObject, SecurityReadAccess(
    SECURITY_INFORMATION[FAclType]));

  if not Result.IsSuccess then
  begin
    AclFrame.SetStatus(Result);
    Exit;
  end;

  // Query the security descriptor
  Result := FContext.QueryFunction(hxObject.Handle,
    SECURITY_INFORMATION[FAclType], SecDesc);

  if not Result.IsSuccess then
  begin
    AclFrame.SetStatus(Result);
    Exit;
  end;

  // Parse the data
  Result := RtlxCaptureSecurityDescriptor(SecDesc.Data, SD);

  if not Result.IsSuccess then
  begin
    AclFrame.SetStatus(Result);
    Exit;
  end;

  // Update the controls
  SetControlFlags(SD.Control);
  AclFrame.SetStatus(Result);

  if FAclType = aiDacl then
    AclFrame.LoadAcl(SD.Dacl, FContext.AccessMaskType, FContext.GenericMapping)
  else
    AclFrame.LoadAcl(SD.Sacl, FContext.AccessMaskType, FContext.GenericMapping);
end;

procedure TAclSecurityFrame.SetActive;
begin
  if Active then
    ActionList.State := asNormal
  else
    ActionList.State := asSuspended;

  (AclFrame as IObservesActivation).SetActive(Active);
end;

procedure TAclSecurityFrame.SetControlFlags;
begin
  cbxPresent.Checked := BitTest(Value and FLAG_PRESENT[FAclType = aiDacl]);
  cbxDefaulted.Checked := BitTest(Value and FLAG_DEFAULTED[FAclType = aiDacl]);
  cbxInheritReq.Checked := BitTest(Value and FLAG_INHERIT_REQ[FAclType = aiDacl]);
  cbxInherited.Checked := BitTest(Value and FLAG_INHERITED[FAclType = aiDacl]);
  cbxProtected.Checked := BitTest(Value and FLAG_PROTECTED[FAclType = aiDacl]);
end;

{ Integration }

function NtUiLibAclSecurityFrameInitializer;
begin
  Result := function (AOwner: TComponent): TFrame
    var
      Frame: TAclSecurityFrame absolute Result;
    begin
      Frame := TAclSecurityFrame.Create(AOwner);
      try
        Frame.LoadFor(AclType, Context)
      except
        Frame.Free;
        raise;
      end;
    end;
end;

end.
