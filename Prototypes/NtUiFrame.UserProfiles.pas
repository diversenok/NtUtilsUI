unit NtUiFrame.UserProfiles;

{
  This module provides a frame for listing user profiles.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.Tree, NtUiCommon.Interfaces, NtUiBackend.UserProfiles,
  NtUtilsUI, NtUtilsUI.Base, NtUtilsUI.Tree.Search;

type
  TUserProfilesFrame = class(TFrame, IHasDefaultCaption,
    IAllowsDefaultNodeAction, IHasModalResult, IHasModalResultObservation)
  published
    Tree: TUiLibTree;
    SearchBox: TUiLibTreeSearchBox;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    property BackendImpl: TTreeNodeInterfaceProvider read Backend implements IHasModalResult, IHasModalResultObservation, IAllowsDefaultNodeAction;
    function GetDefaultCaption: String;
  protected
    procedure Loaded; override;
  public
    procedure LoadAllUsers;
  end;

implementation

uses
  NtUtils, NtUtils.Profiles, NtUiCommon.Prototypes, NtUiLib.Errors;

{$R *.dfm}

{ TUserProfilesFrame }

function TUserProfilesFrame.GetDefaultCaption;
begin
  Result := 'User Profiles';
end;

procedure TUserProfilesFrame.LoadAllUsers;
var
  Providers: TArray<IProfileNode>;
  Provider: IProfileNode;
  Status: TNtxStatus;
begin
  Status := UiLibEnumerateProfiles(Providers);

  if Status.IsSuccess then
    Tree.EmptyListMessage := 'No items to display'
  else
    Tree.EmptyListMessage := 'Unable to query:'#$D#$A + Status.ToString;

  if not Status.IsSuccess then
    Exit;

  Tree.BeginUpdateAuto;
  Tree.Clear;

  for Provider in Providers do
    Tree.AddChild(Provider);
end;

procedure TUserProfilesFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree, [teSelectionChange]);
  Backend.ModalResultFilter := IProfileNode;
  BackendRef := Backend; // Make an owning reference
end;

{ Integration }

function Initializer(AOwner: TComponent): TWinControl;
var
  Frame: TUserProfilesFrame absolute Result;
begin
  Frame := TUserProfilesFrame.Create(AOwner);
  try
    Frame.LoadAllUsers;
  except
    Frame.Free;
    raise;
  end;
end;

procedure NtUiLibShowUserProfiles;
begin
  UiLibShow(Initializer);
end;

function NtUiLibSelectUserProfile(Owner: TComponent): TNtUiLibProfileInfo;
var
  ProfileNode: IProfileNode;
begin
  Profilenode := UiLibPick(Owner, Initializer) as IProfileNode;
  Result := ProfileNode.Info;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowUserProfiles := NtUiLibShowUserProfiles;
  NtUiCommon.Prototypes.NtUiLibSelectUserProfile := NtUiLibSelectUserProfile;
end.
