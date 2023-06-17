unit NtUiFrame.AppContainer.Edit;

{
  This module provides a small control for specifying an AppContainer SID.
}

interface

uses
  Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, NtUtils,
  NtUtils.Security.AppContainer;

type
  TAppContainerFieldFrame = class(TFrame)
    tbxMoniker: TEdit;
    btnSelect: TButton;
    pmMenu: TPopupMenu;
    cmClear: TMenuItem;
    procedure btnSelectClick(Sender: TObject);
    procedure cmClearClick(Sender: TObject);
    procedure tbxMonikerChange(Sender: TObject);
  private
    FUser, FSid: ISid;
    function GetSid: ISid;
    procedure FrameEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    procedure Loaded; override;
  public
    function TrySetUserFromToken(const hxToken: IHandle): TNtxStatus;
    [MayReturnNil] property Sid: ISid read GetSid;
  end;

implementation

uses
  Ntapi.ntseapi, NtUtils.Tokens, NtUtils.Tokens.Info, NtUiLib.Errors,
  NtUiBackend.AppContainers, Vcl.ComCtrls, NtUiCommon.Prototypes;

{$R *.dfm}

{ TAppContainerFieldFrame }

procedure TAppContainerFieldFrame.btnSelectClick;
var
  Info: TAppContainerInfo;
begin
  if not Assigned(NtUiLibSelectAppContainerAllUsers) then
    Exit;

  if not Assigned(FUser) then
    NtxQuerySidToken(NtxCurrentEffectiveToken, TokenUser, FUser).RaiseOnError;

  // Show a modal dialog with AppContainer list
  Info := NtUiLibSelectAppContainerAllUsers(Self, FUser);

  FUser := Info.User;
  FSid := Info.Sid;
  tbxMoniker.Text := Info.FullMoniker;
  tbxMoniker.Hint := Info.Hint;
end;

procedure TAppContainerFieldFrame.cmClearClick;
begin
  FSid := nil;
  tbxMoniker.Text := '';
  tbxMoniker.Hint := '';
end;

procedure TAppContainerFieldFrame.FrameEnabledChanged;
begin
  inherited;
  tbxMoniker.Enabled := Enabled;
  btnSelect.Enabled := Enabled;
end;

function TAppContainerFieldFrame.GetSid;
begin
  if Assigned(FSid) then
    Exit(FSid);

  FSid := UiLibDeriveAppContainer(tbxMoniker.Text);
end;

procedure TAppContainerFieldFrame.Loaded;
begin
  inherited;

  // Don't use split button style without manifests; note that the user should
  // still be able to trigger the menu via a right mouse click
  if GetComCtlVersion < ComCtlVersionIE6 then
    btnSelect.Style := bsPushButton;
end;

procedure TAppContainerFieldFrame.tbxMonikerChange;
begin
  FSid := nil;
  tbxMoniker.Hint := '';
end;

function TAppContainerFieldFrame.TrySetUserFromToken;
var
  User: ISid;
begin
  Result := NtxQuerySidToken(hxToken, TokenUser, User);

  if Result.IsSuccess then
    FUser := User;
end;

end.
