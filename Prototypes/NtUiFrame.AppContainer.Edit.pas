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
  Ntapi.ntseapi, NtUtils.Tokens, NtUtils.Tokens.Info, NtUtils.Security.Sid,
  NtUtils.SysUtils, NtUiLib.Errors, NtUiFrame.AppContainer.ListAllUsers,
  NtUiDialog.NodeSelection, Vcl.ComCtrls;

{$R *.dfm}

{ TAppContainerFieldFrame }

procedure TAppContainerFieldFrame.btnSelectClick;
var
  NodeProvider: IAppContainerNode;
  Info: TAppContainerInfo;
begin
  if not Assigned(FUser) then
    NtxQuerySidToken(NtxCurrentEffectiveToken, TokenUser, FUser).RaiseOnError;

  // Show a modal dialog with AppContainer list
  NodeProvider := TNodeSelectionDialog.Pick(Self,
    function (AOwner: TForm): TFrame
    var
      AppContainerFrame: TAppContainerListAllUsersFrame absolute Result;
    begin
      AppContainerFrame := TAppContainerListAllUsersFrame.Create(AOwner);
      AppContainerFrame.LoadForUser(FUser);
    end
  ) as IAppContainerNode;

  Info := NodeProvider.Info;
  FUser := Info.User;
  FSid := Info.Sid;
  tbxMoniker.Text := Info.FullMoniker;
  tbxMoniker.Hint := NodeProvider.Hint;
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
  // Use cached value when possible
  if Assigned(FSid) then
    Exit(FSid);

  if tbxMoniker.Text = '' then
    Exit(nil);

  // Derive/convert the SID from text
  if RtlxPrefixString('S-1-', tbxMoniker.Text) then
    RtlxStringToSid(tbxMoniker.Text, Result).RaiseOnError
  else
    RtlxDeriveFullAppContainerSid(tbxMoniker.Text, Result).RaiseOnError;

  // Cache for future use
  FSid := Result;
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
