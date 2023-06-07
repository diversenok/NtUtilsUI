unit NtUiFrame.AppContainersEx;

{
  This module provides a frame for showing AppContainer profiles for all users.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, NtUtils, NtUiFrame.AppContainers,
  NtUiCommon.Interfaces;

type
  IAppContainerNode = NtUiFrame.AppContainers.IAppContainerNode;

  TAppContainersExFrame = class (TFrame, IHasSearch, ICanConsumeEscape,
    IGetFocusedNode, IOnNodeSelection, IHasDefaultCaption)
  published
    lblUsers: TLabel;
    tbxUser: TEdit;
    btnSelectUser: TButton;
    AppContainersFrame: TAppContainersFrame;
    procedure btnSelectUserClick(Sender: TObject);
  private
    FUser: ISid;
    function GetHasSearchImpl: IHasSearch;
    function GetCanConsumeEscapeImpl: ICanConsumeEscape;
    function GetFocusedNodeImpl: IGetFocusedNode;
    function GetOnNodeSelectionImpl: IOnNodeSelection;
    property HasSearchImpl: IHasSearch read GetHasSearchImpl implements IHasSearch;
    property CanConsumeEscapeImpl: ICanConsumeEscape read GetCanConsumeEscapeImpl implements ICanConsumeEscape;
    property FocusedNodeImpl: IGetFocusedNode read GetFocusedNodeImpl implements IGetFocusedNode;
    property OnNodeSelectionImpl: IOnNodeSelection read GetOnNodeSelectionImpl implements IOnNodeSelection;
    property Impl: TAppContainersFrame read AppContainersFrame implements IHasDefaultCaption;
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

procedure TAppContainersExFrame.btnSelectUserClick;
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

function TAppContainersExFrame.GetCanConsumeEscapeImpl;
begin
  Result := AppContainersFrame;
end;

function TAppContainersExFrame.GetFocusedNodeImpl;
begin
  Result := AppContainersFrame;
end;

function TAppContainersExFrame.GetHasSearchImpl;
begin
  Result := AppContainersFrame;
end;

function TAppContainersExFrame.GetOnNodeSelectionImpl;
begin
  Result := AppContainersFrame;
end;

procedure TAppContainersExFrame.LoadForUser;
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
