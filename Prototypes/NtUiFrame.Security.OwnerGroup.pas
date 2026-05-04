unit NtUiFrame.Security.OwnerGroup;

{
  This module provides a frame for viewing/editing owner and primary group of
  securable objects.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  UI.Prototypes.Sid.Edit, Vcl.StdCtrls, NtUiCommon.Interfaces,
  NtUiCommon.Prototypes, NtUtils, NtUtilsUI, NtUtilsUI.Base;

type
  TDescriptorSidType = (dsOwner, dsPrimaryGroup);

  TOwnerGroupSecurityFrame = class(TFrame, IDefaultCaption, IDelayedLoad)
    SidEditor: TSidEditor;
    GroupBox: TGroupBox;
    cbxDefaulted: TCheckBox;
    btnRefresh: TButton;
    btnApply: TButton;
    procedure btnRefreshClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
  private
    FSidType: TDescriptorSidType;
    FContext: TNtUiLibSecurityContext;
    FRefreshShortcut: TUiLibShortCut;
    function Refresh: TNtxStatus;
    function Apply: TNtxStatus;
    function GetDefaultCaption: String;
    procedure DelayedLoad;
    procedure OnRefreshShortCut(Sender: TUiLibShortCut; var Handled: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadFor(
      SidType: TDescriptorSidType;
      const Context: TNtUiLibSecurityContext
    );
  end;

// Construct a frame initializer for an ACL security editor
function NtUiLibSidSecurityFrameInitializer(
  SidType: TDescriptorSidType;
  const Context: TNtUiLibSecurityContext
): TWinControlFactory;

implementation

uses
  Ntapi.WinNt, NtUtils.Security;

{$R *.dfm}

const
  FLAG_DEFAULTED: array [TDescriptorSidType] of TSecurityDescriptorControl = (
    SE_OWNER_DEFAULTED, SE_GROUP_DEFAULTED);

  SECURITY_INFORMATION: array [TDescriptorSidType] of TSecurityInformation = (
    OWNER_SECURITY_INFORMATION, GROUP_SECURITY_INFORMATION);

  SID_CAPTIONS: array [TDescriptorSidType] of String = (
    'Owner', 'Primary Group');

{ TOwnerGroupSecurityFrame }

function TOwnerGroupSecurityFrame.Apply;
var
  hxObject: IHandle;
  SD: TSecurityDescriptorData;
  SecDesc: ISecurityDescriptor;
  DesiredAccess: TAccessMask;
begin
  if not Assigned(FContext.HandleProvider) or
    not Assigned(FContext.SetFunction) then
    raise Exception.Create('No callback for setting security is available');

  // Check for custom access mask lookup
  if Assigned(FContext.CustomSetAccessLookup) then
    DesiredAccess := FContext.CustomSetAccessLookup(
      SECURITY_INFORMATION[FSidType])
  else
    DesiredAccess := SecurityWriteAccess(SECURITY_INFORMATION[FSidType]);

  // Start building a security descriptor
  SD := Default(TSecurityDescriptorData);

  if cbxDefaulted.Checked then
    SD.Control := FLAG_DEFAULTED[FSidType];

  if FSidType = dsOwner then
    Result := SidEditor.TryGetSid(SD.Owner)
  else
    Result := SidEditor.TryGetSid(SD.Group);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxAllocateSecurityDescriptor(SD, SecDesc);

  if not Result.IsSuccess then
    Exit;

  // Open the handle
  Result := FContext.HandleProvider(hxObject, DesiredAccess);

  if not Result.IsSuccess then
    Exit;

  // Apply the security descriptor
  Result := FContext.SetFunction(hxObject, SECURITY_INFORMATION[FSidType],
    SecDesc.Data);

  if not Result.IsSuccess then
    Exit;

  Refresh;
end;

procedure TOwnerGroupSecurityFrame.btnApplyClick;
begin
  Apply.RaiseOnError;
end;

procedure TOwnerGroupSecurityFrame.btnRefreshClick;
begin
  Refresh.RaiseOnError;
end;

constructor TOwnerGroupSecurityFrame.Create;
begin
  inherited;
  FRefreshShortcut := TUiLibShortCut.Create(Self);
  FRefreshShortcut.ShortCut := VK_F5;
  FRefreshShortcut.OnExecute := OnRefreshShortCut;
end;

procedure TOwnerGroupSecurityFrame.DelayedLoad;
begin
  Refresh;
end;

function TOwnerGroupSecurityFrame.GetDefaultCaption;
begin
  Result := SID_CAPTIONS[FSidType];
end;

procedure TOwnerGroupSecurityFrame.LoadFor;
begin
  if SidType > High(TDescriptorSidType) then
    raise Exception.Create('Invalid SID type');

  FSidType := SidType;
  FContext := Context;
end;

procedure TOwnerGroupSecurityFrame.OnRefreshShortCut;
begin
  if CanFocus then
  begin
    Refresh.RaiseOnError;
    Handled := True;
  end;
end;

function TOwnerGroupSecurityFrame.Refresh;
var
  hxObject: IHandle;
  SecDesc: ISecurityDescriptor;
  SD: TSecurityDescriptorData;
  DesiredAccess: TAccessMask;
begin
  if not Assigned(FContext.HandleProvider) or
    not Assigned(FContext.QueryFunction) then
    raise Exception.Create('No callback for querying security is available');

  // Check for custom access mask lookup
  if Assigned(FContext.CustomQueryAccessLookup) then
    DesiredAccess := FContext.CustomQueryAccessLookup(
      SECURITY_INFORMATION[FSidType])
  else
    DesiredAccess := SecurityReadAccess(SECURITY_INFORMATION[FSidType]);

  // Reset UI state
  cbxDefaulted.Checked := False;
  SidEditor.Sid := nil;

  // Open the handle
  Result := FContext.HandleProvider(hxObject, DesiredAccess);

  if not Result.IsSuccess then
    Exit;

  // Query the security descriptor
  Result := FContext.QueryFunction(hxObject, SECURITY_INFORMATION[FSidType],
    SecDesc);

  if not Result.IsSuccess then
    Exit;

  // Parse the data
  Result := RtlxCaptureSecurityDescriptor(SecDesc.Data, SD);

  if not Result.IsSuccess then
    Exit;

  // Update the controls
  cbxDefaulted.Checked := BitTest(SD.Control and FLAG_DEFAULTED[FSidType]);

  if FSidType = dsOwner then
    SidEditor.Sid := SD.Owner
  else
    SidEditor.Sid := SD.Group;
end;

{ Integration }

function NtUiLibSidSecurityFrameInitializer;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      Frame: TOwnerGroupSecurityFrame absolute Result;
    begin
      Frame := TOwnerGroupSecurityFrame.Create(AOwner);
      try
        Frame.LoadFor(SidType, Context)
      except
        Frame.Free;
        raise;
      end;
    end;
end;

end.
