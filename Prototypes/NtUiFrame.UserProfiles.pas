unit NtUiFrame.UserProfiles;

{
  This module provides a frame for listing user profiles.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, VirtualTrees, VirtualTreesEx, DevirtualizedTree,
  NtUiFrame.Search, NtUiCommon.Interfaces, NtUiBackend.UserProfiles, NtUiFrame;

type
  TUserProfilesFrame = class(TFrame, ICanConsumeEscape,
    IHasDefaultCaption, IAllowsDefaultNodeAction, IHasModalResult,
    IHasModalResultObservation)
  published
    Tree: TDevirtualizedTree;
    SearchBox: TSearchFrame;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    property BackendImpl: TTreeNodeInterfaceProvider read Backend implements IHasModalResult, IHasModalResultObservation, IAllowsDefaultNodeAction;
    property SearchImpl: TSearchFrame read SearchBox implements ICanConsumeEscape;
    function GetDefaultCaption: String;
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
  Backend.ModalResultFilter := IProfileNode;
  BackendRef := Backend; // Make an owning reference
end;

{ Integration }

function Initializer(AOwner: TComponent): TFrame;
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
