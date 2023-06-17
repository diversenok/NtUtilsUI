unit NtUiFrame.UserProfiles;

{
  This module provides a frame for listing user profiles.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, VirtualTrees, VirtualTreesEx, DevirtualizedTree,
  NtUiFrame.Search, NtUiCommon.Interfaces, NtUiBackend.UserProfiles;

type
  TUserProfilesFrame = class(TFrame, IHasSearch, ICanConsumeEscape,
    IGetFocusedNode, IOnNodeSelection, IHasDefaultCaption, INodeDefaultAction)
  published
    Tree: TDevirtualizedTree;
    SearchBox: TSearchFrame;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    property BackendImpl: TTreeNodeInterfaceProvider read Backend implements IGetFocusedNode, IOnNodeSelection, INodeDefaultAction;
    property SearchImpl: TSearchFrame read SearchBox implements IHasSearch, ICanConsumeEscape;
    function DefaultCaption: String;
  protected
    procedure Loaded; override;
  public
    procedure LoadAllUsers;
  end;

implementation

uses
  NtUtils, NtUtils.Profiles, NtUiCommon.Prototypes;

{$R *.dfm}

{ TUserProfilesFrame }

function TUserProfilesFrame.DefaultCaption;
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
  Backend.SetStatus(Status);

  if not Status.IsSuccess then
    Exit;

  Backend.BeginUpdateAuto;
  Backend.ClearItems;

  for Provider in Providers do
    Backend.AddItem(Provider);
end;

procedure TUserProfilesFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree, [teSelectionChange]);
  BackendRef := Backend; // Make an owning reference
end;

{ Integration }

function Initializer(AOwner: TForm): TFrame;
var
  UserFrame: TUserProfilesFrame absolute Result;
begin
  UserFrame := TUserProfilesFrame.Create(AOwner);
  try
    UserFrame.LoadAllUsers;
  except
    UserFrame.Free;
    raise;
  end;
end;

procedure NtUiLibShowUserProfiles;
begin
  if not Assigned(NtUiLibHostFrameShow) then
    raise ENotSupportedException.Create('Frame host not available');

  NtUiLibHostFrameShow(Initializer);
end;

function NtUiLibSelectUserProfile(Owner: TComponent): TProfileInfo;
var
  ProfileNode: IProfileNode;
begin
  if not Assigned(NtUiLibHostFramePick) then
    raise ENotSupportedException.Create('Frame host not available');

  Profilenode := NtUiLibHostFramePick(Owner, Initializer) as IProfileNode;
  Result := ProfileNode.Info;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowUserProfiles := NtUiLibShowUserProfiles;
  NtUiCommon.Prototypes.NtUiLibSelectUserProfile := NtUiLibSelectUserProfile;
end.
