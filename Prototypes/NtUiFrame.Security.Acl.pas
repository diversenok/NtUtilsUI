unit NtUiFrame.Security.Acl;

{
  This module provides a control for viewing/editing ACLs on securable objects.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, NtUiFrame,
  NtUiFrame.Acl, Ntapi.WinNt, NtUtils, NtUiCommon.Prototypes, System.Actions,
  Vcl.ActnList, NtUiCommon.Interfaces, NtUtils.Security.Acl;

type
  TAclType = (aiDacl, aiLabel, aiTrust, aiSacl, aiAttribute, aiScope, aiFilter);

  TAclSecurityFrame = class(TFrame, IHasDefaultCaption, ICanConsumeEscape,
    IObservesActivation, IDelayedLoad)
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
    procedure cbxPresentClick(Sender: TObject);
  private
    FFrameLoaded: Boolean;
    FAclType: TAclType;
    FContext: TNtUiLibSecurityContext;
    function GetControlFlags: TSecurityDescriptorControl;
    procedure SetControlFlags(const Value: TSecurityDescriptorControl);
    function QueryAcl(out Control: TSecurityDescriptorControl; out Aces: TArray<TAceData>): TNtxStatus;
    function Refresh: TNtxStatus;
    function Apply: TNtxStatus;
    function GetDefaultCaption: String;
    procedure SetActive(Active: Boolean);
    procedure DelayedLoad;
    procedure AclChanged(Sender: TObject);
    function GetCanConsumeEscapeImpl: ICanConsumeEscape;
    property CanConsumeEscapeImpl: ICanConsumeEscape read GetCanConsumeEscapeImpl implements ICanConsumeEscape;
  protected
    procedure Loaded; override;
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
  NtUtils.Security, NtUiLib.Errors;

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

  DEFAULT_ACE_TYPE: array [TAclType] of TAceType = (
    ACCESS_ALLOWED_ACE_TYPE, SYSTEM_MANDATORY_LABEL_ACE_TYPE,
    SYSTEM_PROCESS_TRUST_LABEL_ACE_TYPE, SYSTEM_AUDIT_ACE_TYPE,
    SYSTEM_RESOURCE_ATTRIBUTE_ACE_TYPE, SYSTEM_SCOPED_POLICY_ID_ACE_TYPE,
    SYSTEM_ACCESS_FILTER_ACE_TYPE
  );

{ TAclSecurityFrame }

procedure TAclSecurityFrame.AclChanged;
begin
  if Length(AclFrame.Aces) > 0 then
  begin
    // Automatically enable ACL when adding items
    cbxPresent.Checked := True;
    cbxPresentClick(Sender);
  end;
end;

function TAclSecurityFrame.Apply;
var
  hxObject: IHandle;
  SD: TSecurityDescriptorData;
  SecDesc: ISecurityDescriptor;
begin
  if not Assigned(FContext.HandleProvider) or
    not Assigned(FContext.QueryFunction) then
    raise Exception.Create('ACL Security frame not initialized');

  // Open the handle
  Result := FContext.HandleProvider(hxObject, SecurityWriteAccess(
    SECURITY_INFORMATION[FAclType]));

  if not Result.IsSuccess then
    Exit;

  SD := Default(TSecurityDescriptorData);
  SD.Control := GetControlFlags;

  // Make an ACL
  if FAclType = aiDacl then
    Result := RtlxBuildAcl(SD.Dacl, AclFrame.Aces)
  else
    Result := RtlxBuildAcl(SD.Sacl, AclFrame.Aces);

  if not Result.IsSuccess then
    Exit;

  // Make a security descriptor
  Result := RtlxAllocateSecurityDescriptor(SD, SecDesc);

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

procedure TAclSecurityFrame.cbxPresentClick;
begin
  if cbxPresent.Checked then
    AclFrame.SetEmptyMessage('Empty ACL')
  else
    AclFrame.SetEmptyMessage('NULL ACL');
end;

procedure TAclSecurityFrame.DelayedLoad;
begin
  Refresh;
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

procedure TAclSecurityFrame.Loaded;
begin
  inherited;

  if FFrameLoaded then
    Exit;

  FFrameLoaded := True;
  AclFrame.OnAceChange := AclChanged;
end;

procedure TAclSecurityFrame.LoadFor;
begin
  if AclType > High(TAclType) then
    raise Exception.Create('Invalid ACL type');

  FAclType := AclType;
  FContext := Context;
end;

function TAclSecurityFrame.QueryAcl;
var
  hxObject: IHandle;
  SecDesc: ISecurityDescriptor;
  SD: TSecurityDescriptorData;
begin
  // Open the handle
  Result := FContext.HandleProvider(hxObject, SecurityReadAccess(
    SECURITY_INFORMATION[FAclType]));

  if not Result.IsSuccess then
    Exit;

  // Query the security descriptor
  Result := FContext.QueryFunction(hxObject.Handle,
    SECURITY_INFORMATION[FAclType], SecDesc);

  if not Result.IsSuccess then
    Exit;

  // Parse the security descriptor
  Result := RtlxCaptureSecurityDescriptor(SecDesc.Data, SD);

  if not Result.IsSuccess then
    Exit;

  // Parse the ACL
  if FAclType = aiDacl then
    Result := RtlxDumpAcl(SD.Dacl, Aces)
  else
    Result := RtlxDumpAcl(SD.Sacl, Aces);

  if not Result.IsSuccess then
    Exit;

  Control := SD.Control;

  // Allow distinguishing between NULL and empty ACLs
  if (FAclType = aiDacl) and not Assigned(SD.Dacl) then
    Control := Control and not SE_DACL_PRESENT
  else if (FAclType <> aiDacl) and not Assigned(SD.Sacl) then
    Control := Control and not SE_SACL_PRESENT;
end;

function TAclSecurityFrame.Refresh;
var
  Control: TSecurityDescriptorControl;
  Aces: TArray<TAceData>;
begin
  if not Assigned(FContext.HandleProvider) or
    not Assigned(FContext.QueryFunction) then
    raise Exception.Create('ACL Security frame not initialized');

  // Query the ACL
  Result := QueryAcl(Control, Aces);

  if not Result.IsSuccess then
  begin
    Control := 0;
    Aces := nil;
  end;

  // Update the UI state
  SetControlFlags(Control);
  AclFrame.LoadAces(Aces, FContext.AccessMaskType, FContext.GenericMapping,
    DEFAULT_ACE_TYPE[FAclType]);

  if not Result.IsSuccess then
    AclFrame.SetEmptyMessage('Unable to query:'#$D#$A + Result.ToString);
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
  cbxPresentClick(Self);
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
