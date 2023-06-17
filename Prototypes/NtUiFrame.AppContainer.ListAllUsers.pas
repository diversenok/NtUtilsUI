unit NtUiFrame.AppContainer.ListAllUsers;

{
  This module provides a frame for showing AppContainer profiles for all users.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, NtUtils, NtUiFrame.AppContainer.List,
  NtUiCommon.Interfaces;

type
  TAppContainerListAllUsersFrame = class (TFrame, IHasSearch, ICanConsumeEscape,
    IGetFocusedNode, IOnNodeSelection, IHasDefaultCaption, INodeDefaultAction)
  published
    lblUsers: TLabel;
    tbxUser: TEdit;
    btnSelectUser: TButton;
    AppContainersFrame: TAppContainerListFrame;
    procedure btnSelectUserClick(Sender: TObject);
  private
    FUser: ISid;
    function GetHasSearchImpl: IHasSearch;
    function GetCanConsumeEscapeImpl: ICanConsumeEscape;
    function GetFocusedNodeImpl: IGetFocusedNode;
    function GetOnNodeSelectionImpl: IOnNodeSelection;
    function GetNodeDefaultActionImpl: INodeDefaultAction;
    property HasSearchImpl: IHasSearch read GetHasSearchImpl implements IHasSearch;
    property CanConsumeEscapeImpl: ICanConsumeEscape read GetCanConsumeEscapeImpl implements ICanConsumeEscape;
    property FocusedNodeImpl: IGetFocusedNode read GetFocusedNodeImpl implements IGetFocusedNode;
    property OnNodeSelectionImpl: IOnNodeSelection read GetOnNodeSelectionImpl implements IOnNodeSelection;
    property NodeDefaultActionImpl: INodeDefaultAction read GetNodeDefaultActionImpl implements INodeDefaultAction;
    property Impl: TAppContainerListFrame read AppContainersFrame implements IHasDefaultCaption;
  public
    procedure LoadForUser([opt] const SelectedUser: ISid);
  end;

implementation

uses
  DelphiUiLib.Reflection, NtUiBackend.AppContainers, NtUiCommon.Prototypes;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

procedure TAppContainerListAllUsersFrame.btnSelectUserClick;
begin
  if Assigned(NtUiLibSelectUserProfile) then
    LoadForUser(NtUiLibSelectUserProfile(Self).User);
end;

function TAppContainerListAllUsersFrame.GetCanConsumeEscapeImpl;
begin
  Result := AppContainersFrame;
end;

function TAppContainerListAllUsersFrame.GetFocusedNodeImpl;
begin
  Result := AppContainersFrame;
end;

function TAppContainerListAllUsersFrame.GetHasSearchImpl;
begin
  Result := AppContainersFrame;
end;

function TAppContainerListAllUsersFrame.GetNodeDefaultActionImpl;
begin
  Result := AppContainersFrame;
end;

function TAppContainerListAllUsersFrame.GetOnNodeSelectionImpl;
begin
  Result := AppContainersFrame;
end;

procedure TAppContainerListAllUsersFrame.LoadForUser;
var
  Representation: TRepresentation;
begin
  if not Assigned(SelectedUser) then
    FUser := UiLibGetDefaultUser
  else
    FUser := SelectedUser;

  Representation := TType.Represent(FUser);
  tbxUser.Text := Representation.Text;
  tbxUser.Hint := Representation.Hint;
  AppContainersFrame.LoadForUser(SelectedUser);
end;

{ Integration }

function Initializer([opt] const DefaultUser: ISid): TFrameInitializer;
begin
  Result := function (AOwner: TForm): TFrame
    var
      UserFrame: TAppContainerListAllUsersFrame absolute Result;
    begin
      UserFrame := TAppContainerListAllUsersFrame.Create(AOwner);
      try
        UserFrame.LoadForUser(DefaultUser);
      except
        UserFrame.Free;
        raise;
      end;
    end;
end;

procedure NtUiLibShowAppContainersAllUsers(
  const User: ISid
);
begin
  if not Assigned(NtUiLibHostFrameShow) then
    raise ENotSupportedException.Create('Frame host not available');

  NtUiLibHostFrameShow(Initializer(User));
end;

function NtUiLibSelectAppContainerAllUsers(
  Owner: TComponent;
  [opt] const DefaultUser: ISid
): TAppContainerInfo;
var
  ProfileNode: IAppContainerNode;
begin
  if not Assigned(NtUiLibHostFramePick) then
    raise ENotSupportedException.Create('Frame host not available');

  Profilenode := NtUiLibHostFramePick(Owner,
    Initializer(DefaultUser)) as IAppContainerNode;

  Result := ProfileNode.Info;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowAppContainersAllUsers :=
    NtUiLibShowAppContainersAllUsers;
  NtUiCommon.Prototypes.NtUiLibSelectAppContainerAllUsers :=
    NtUiLibSelectAppContainerAllUsers;
end.
