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
  TUserProfilesFrame = class(TFrame, IModalResult<IProfileNode>,
    IModalResultControl)
    Tree: TUiLibTree;
    SearchBox: TUiLibTreeSearchBox;
    procedure TreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeMainAction(Node: INodeProvider);
  private
    FOnModalResultAvailabilityChange: TOnModalResultAvailabilityChange;
    FOnModalComplete: TNotifyEvent;
    function GetModalResult: IProfileNode;
    function GetModalResultType: Pointer;
    procedure SetOnModalResultAvailabilityChange(Event: TOnModalResultAvailabilityChange);
    procedure SetOnModalComplete(Event: TNotifyEvent);
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

function TUserProfilesFrame.GetModalResult;
begin
  Result := Tree.HighlightedNode.Provider as IProfileNode;
end;

function TUserProfilesFrame.GetModalResultType;
begin
  Result := TypeInfo(IProfileNode);
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
end;

procedure TUserProfilesFrame.SetOnModalComplete;
begin
  FOnModalComplete := Event;
  Tree.OnMainAction := TreeMainAction;
  Tree.MainActionMenuText := 'Select';
end;

procedure TUserProfilesFrame.SetOnModalResultAvailabilityChange;
begin
  FOnModalResultAvailabilityChange := Event;
  TreeChange(nil, nil);
end;

procedure TUserProfilesFrame.TreeChange;
begin
  if Assigned(FOnModalResultAvailabilityChange) then
    FOnModalResultAvailabilityChange(Assigned(Tree.HighlightedNode));
end;

procedure TUserProfilesFrame.TreeMainAction;
begin
  if Assigned(FOnModalComplete) then
    FOnModalComplete(Self);
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
