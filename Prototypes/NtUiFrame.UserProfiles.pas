unit NtUiFrame.UserProfiles;

{
  This module provides a frame for listing user profiles.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, VirtualTrees, NtUtilsUI.Tree, NtUiCommon.Interfaces, NtUiBackend.UserProfiles,
  NtUtilsUI, NtUtilsUI.Base, NtUtilsUI.Tree.Search;

type
  [DefaultCaption('User Profiles')]
  TUserProfilesFrame = class(TFrame, IAllowsDefaultNodeAction,
    IModalResult<IProfileNode>, IModalResultAvailability)
  published
    Tree: TUiLibTree;
    SearchBox: TUiLibTreeSearchBox;
  private
    Backend: TTreeNodeInterfaceProviderModal<IProfileNode>;
    BackendRef: IUnknown;
    property BackendImpl: TTreeNodeInterfaceProviderModal<IProfileNode> read Backend implements IModalResult<IProfileNode>, IModalResultAvailability, IAllowsDefaultNodeAction;
  protected
    procedure Loaded; override;
  public
    procedure LoadAllUsers;
  end;

implementation

uses
  NtUtils, NtUtils.Profiles, NtUiCommon.Prototypes, NtUiLib.Errors,
  NtUtilsUI.Components;

{$R *.dfm}

{ TUserProfilesFrame }

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
  Backend := TTreeNodeInterfaceProviderModal<IProfileNode>.Create(Tree, [teSelectionChange]);
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
  UiLibHost.Show(Initializer);
end;

function NtUiLibSelectUserProfile(Owner: TComponent): TNtUiLibProfileInfo;
var
  ProfileNode: IProfileNode;
begin
  Profilenode := UiLibHost.Pick<IProfileNode>(Owner, Initializer);
  Result := ProfileNode.Info;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowUserProfiles := NtUiLibShowUserProfiles;
  NtUiCommon.Prototypes.NtUiLibSelectUserProfile := NtUiLibSelectUserProfile;
end.
