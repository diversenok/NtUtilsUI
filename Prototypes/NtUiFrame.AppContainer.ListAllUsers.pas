unit NtUiFrame.AppContainer.ListAllUsers;

{
  This module provides a frame for showing AppContainer profiles for all users.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, NtUtils, NtUiFrame.AppContainer.List,
  NtUiCommon.Interfaces, NtUtilsUI, NtUtilsUI.StdCtrls, NtUtilsUI.Base,
  NtUiBackend.AppContainers;

type
  [DefaultCaption('AppContainer Profiles')]
  TAppContainerListAllUsersFrame = class (TFrame, IAllowsDefaultNodeAction,
    IModalResult<IAppContainerNode>, IModalResultAvailability)
  published
    lblUsers: TLabel;
    tbxUser: TUiLibEdit;
    btnSelectUser: TButton;
    AppContainersFrame: TAppContainerListFrame;
    procedure btnSelectUserClick(Sender: TObject);
  private
    FUser: ISid;
    function GetModalResult: IAppContainerNode;
    function GetNodeDefaultActionImpl: IAllowsDefaultNodeAction;
    function GetModalResultAvailability: IModalResultAvailability;
    property NodeDefaultActionImpl: IAllowsDefaultNodeAction read GetNodeDefaultActionImpl implements IAllowsDefaultNodeAction;
    property ModalResultAvailabilityImpl: IModalResultAvailability read GetModalResultAvailability implements IModalResultAvailability;
  public
    procedure LoadForUser([opt] const SelectedUser: ISid);
  end;

implementation

uses
  DelphiUiLib.LiteReflection, NtUiCommon.Prototypes, NtUtilsUI.Components;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

procedure TAppContainerListAllUsersFrame.btnSelectUserClick;
begin
  if Assigned(NtUiLibSelectUserProfile) then
    LoadForUser(NtUiLibSelectUserProfile(Self).User);
end;

function TAppContainerListAllUsersFrame.GetModalResult;
begin
  Result := (AppContainersFrame as IModalResult<IAppContainerNode>).ModalResult;
end;

function TAppContainerListAllUsersFrame.GetModalResultAvailability;
begin
  Result := AppContainersFrame;
end;

function TAppContainerListAllUsersFrame.GetNodeDefaultActionImpl;
begin
  Result := AppContainersFrame;
end;

procedure TAppContainerListAllUsersFrame.LoadForUser;
var
  UserReflection: TRttixFullReflection;
begin
  if not Assigned(SelectedUser) then
    FUser := UiLibGetDefaultUser
  else
    FUser := SelectedUser;

  UserReflection := Rttix.FormatFull(FUser);
  tbxUser.Text := UserReflection.Text;
  tbxUser.Hint := UserReflection.Hint;
  AppContainersFrame.LoadForUser(SelectedUser);
end;

{ Integration }

function Initializer([opt] const DefaultUser: ISid): TWinControlFactory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      Frame: TAppContainerListAllUsersFrame absolute Result;
    begin
      Frame := TAppContainerListAllUsersFrame.Create(AOwner);
      try
        Frame.LoadForUser(DefaultUser);
      except
        Frame.Free;
        raise;
      end;
    end;
end;

procedure NtUiLibShowAppContainersAllUsers(
  const User: ISid
);
begin
  UiLibHost.Show(Initializer(User));
end;

function NtUiLibSelectAppContainerAllUsers(
  Owner: TComponent;
  [opt] const DefaultUser: ISid
): TRtlxAppContainerInfo;
var
  ProfileNode: IAppContainerNode;
begin
  ProfileNode := UiLibHost.Pick<IAppContainerNode>(Owner,
    Initializer(DefaultUser));
  Result := ProfileNode.Info;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowAppContainersAllUsers :=
    NtUiLibShowAppContainersAllUsers;
  NtUiCommon.Prototypes.NtUiLibSelectAppContainerAllUsers :=
    NtUiLibSelectAppContainerAllUsers;
end.
