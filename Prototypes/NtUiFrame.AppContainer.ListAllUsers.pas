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
  IAppContainerNode = NtUiFrame.AppContainer.List.IAppContainerNode;

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
    procedure LoadForUser(const User: ISid);
  end;

implementation

uses
  NtUiDialog.NodeSelection, NtUiFrame.UserProfiles, NtUtils.Errors,
  DevirtualizedTree, DelphiUiLib.Reflection;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

procedure TAppContainerListAllUsersFrame.btnSelectUserClick;
var
  Profile: IProfileNode;
begin
  Profile := TNodeSelectionDialog.Pick(Self,
    function (AOwner: TForm): TFrame
    var
      UserFrame: TUserProfilesFrame absolute Result;
    begin
      UserFrame := TUserProfilesFrame.Create(AOwner);
      UserFrame.LoadAllUsers;
    end
  ) as IProfileNode;

  LoadForUser(Profile.Info.User);
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
  FUser := User;
  Representation := TType.Represent(FUser);
  tbxUser.Text := Representation.Text;
  tbxUser.Hint := Representation.Hint;
  AppContainersFrame.LoadForUser(User);
end;

end.
