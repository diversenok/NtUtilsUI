unit NtUiFrame.Security.OwnerGroup;

{
  This module provides a frame for viewing/editing owner and primary group of
  securable objects.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, NtUiFrame,
  UI.Prototypes.Sid.Edit, Vcl.StdCtrls, System.Actions, Vcl.ActnList,
  NtUiCommon.Interfaces, NtUiCommon.Prototypes, NtUtils;

type
  TDescriptorSidType = (dsOwner, dsPrimaryGroup);

  TOwnerGroupSecurityFrame = class(TFrame, IHasDefaultCaption, IObservesActivation)
    SidEditor: TSidEditor;
    GroupBox: TGroupBox;
    cbxDefaulted: TCheckBox;
    btnRefresh: TButton;
    btnApply: TButton;
    ActionList: TActionList;
    ActionRefresh: TAction;
    procedure btnRefreshClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
  private
    FSidType: TDescriptorSidType;
    FContext: TNtUiLibSecurityContext;
    function Refresh: TNtxStatus;
    function Apply: TNtxStatus;
    function GetDefaultCaption: String;
    procedure SetActive(Active: Boolean);
  public
    procedure LoadFor(
      SidType: TDescriptorSidType;
      const Context: TNtUiLibSecurityContext
    );
  end;

// Construct a frame initilizer for an ACL security editor
function NtUiLibSidSecurityFrameInitializer(
  SidType: TDescriptorSidType;
  const Context: TNtUiLibSecurityContext
): TFrameInitializer;

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
begin
  if not Assigned(FContext.HandleProvider) or
    not Assigned(FContext.QueryFunction) then
    raise Exception.Create('SID Security frame not initialized');

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
  Result := FContext.HandleProvider(hxObject, WRITE_OWNER);

  if not Result.IsSuccess then
    Exit;

  // Apply the security descriptor
  Result := FContext.SetFunction(hxObject.Handle,
    SECURITY_INFORMATION[FSidType], SecDesc.Data);

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
  Refresh;
end;

function TOwnerGroupSecurityFrame.Refresh;
var
  hxObject: IHandle;
  SecDesc: ISecurityDescriptor;
  SD: TSecurityDescriptorData;
begin
  if not Assigned(FContext.HandleProvider) or
    not Assigned(FContext.QueryFunction) then
    raise Exception.Create('SID Security frame not initialized');

  // Reset UI state
  cbxDefaulted.Checked := False;
  SidEditor.Sid := nil;

  // Open the handle
  Result := FContext.HandleProvider(hxObject, READ_CONTROL);

  if not Result.IsSuccess then
    Exit;

  // Query the security descriptor
  Result := FContext.QueryFunction(hxObject.Handle,
    SECURITY_INFORMATION[FSidType], SecDesc);

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

procedure TOwnerGroupSecurityFrame.SetActive;
begin
  if Active then
    ActionList.State := asNormal
  else
    ActionList.State := asSuspended;
end;

{ Integration }

function NtUiLibSidSecurityFrameInitializer;
begin
  Result := function (AOwner: TComponent): TFrame
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
