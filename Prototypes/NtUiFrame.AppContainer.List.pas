unit NtUiFrame.AppContainer.List;

{
  This module provides a frame for showing a list of AppContainer profiles.
}

interface

uses
  Vcl.Controls, System.Classes, Vcl.Forms, VirtualTrees,
  NtUtilsUI.Tree, NtUtils,
  NtUiCommon.Interfaces, NtUiBackend.AppContainers, Vcl.Menus,
  NtUtilsUI, NtUtilsUI.Base, NtUtilsUI.Tree.Search;

type
  TAppContainerListFrame = class (TFrame, IHasDefaultCaption,
    IAllowsDefaultNodeAction, IModalResult<IAppContainerNode>,
    IModalResultAvailability)
    PopupMenu: TPopupMenu;
    cmInspect: TMenuItem;
    procedure cmInspectClick(Sender: TObject);
    procedure TreeNodeDblClick(Sender: TBaseVirtualTree;
      const HitInfo: THitInfo);
  published
    SearchBox: TUiLibTreeSearchBox;
    Tree: TUiLibTree;
    procedure FrameMainActionSet(Sender: TObject);
  private
    Backend: TTreeNodeInterfaceProviderModal<IAppContainerNode>;
    BackendRef: IUnknown;
    property BackendImpl: TTreeNodeInterfaceProviderModal<IAppContainerNode> read Backend implements IModalResult<IAppContainerNode>, IModalResultAvailability, IAllowsDefaultNodeAction;
    function GetDefaultCaption: String;
  protected
    procedure Loaded; override;
  public
    procedure LoadForUser(const User: ISid);
  end;

implementation

uses
  NtUtils.Errors, NtUiCommon.Prototypes, System.SysUtils, Winapi.Windows,
  NtUiLib.Errors, NtUtilsUI.Components;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

{ TAppContainersFrame }

procedure TAppContainerListFrame.cmInspectClick(Sender: TObject);
var
  Node: PVirtualNode;
  AppContainerNode: IAppContainerNode;
begin
  if not Assigned(NtUiLibShowAppContainer) then
    Exit;

  Node := Tree.HighlightedNode;

  if Node.TryGetProvider(IAppContainerNode, AppContainerNode) then
    NtUiLibShowAppContainer(AppContainerNode.Info);
end;

procedure TAppContainerListFrame.FrameMainActionSet;
begin
  // Demote the inspect menu from the default Enter to Ctrl+Enter
  cmInspect.ShortCut := scCtrl or VK_RETURN;
  cmInspect.Default := False;
  Tree.RefreshPopupMenuShortcuts;
end;

function TAppContainerListFrame.GetDefaultCaption;
begin
  Result := 'AppContainer Profiles'
end;

procedure TAppContainerListFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProviderModal<IAppContainerNode>.Create(Tree, [teSelectionChange]);
  BackendRef := Backend; // Make an owning reference

  if Assigned(NtUiLibShowAppContainer) then
  begin
    Tree.PopupMenu := PopupMenu;
    Backend.OnMainActionSet := FrameMainActionSet;
  end;
end;

procedure TAppContainerListFrame.LoadForUser;
var
  Parents, Children: TArray<IAppContainerNode>;
  Parent, Child: IAppContainerNode;
  Status: TNtxStatus;
begin
  Tree.BeginUpdateAuto;
  Tree.Clear;

  // Enumerate parent AppContainers
  Status := UiLibEnumerateAppContainers(Parents, User);

  if Status.IsSuccess then
    Tree.EmptyListMessage := 'No items to display'
  else
    Tree.EmptyListMessage := 'Unable to query:'#$D#$A + Status.ToString;

  if not Status.IsSuccess then
    Exit;

  for Parent in Parents do
  begin
    Tree.AddChild(Parent);

    // Enumerate child AppContainers
    if UiLibEnumerateAppContainers(Children, User, Parent.Info.Sid).IsSuccess then
      for Child in Children do
        Tree.AddChild(Child, Parent);
  end;
end;

procedure TAppContainerListFrame.TreeNodeDblClick;
begin
  if cmInspect.Default then
    cmInspectClick(Sender);
end;

{ Integration }

function Initializer(const User: ISid): TWinControlFactory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      Frame: TAppContainerListFrame absolute Result;
    begin
      Frame := TAppContainerListFrame.Create(AOwner);
      try
        Frame.LoadForUser(User);
      except
        Frame.Free;
        raise;
      end;
    end;
end;

procedure NtUiLibShowAppContainers(
  const User: ISid
);
begin
  UiLibHost.Show(Initializer(User));
end;

function NtUiLibSelectAppContainer(
  Owner: TComponent;
  const User: ISid
): TRtlxAppContainerInfo;
var
  ProfileNode: IAppContainerNode;
begin
  Profilenode := UiLibHost.Pick<IAppContainerNode>(Owner, Initializer(User));
  Result := ProfileNode.Info;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowAppContainers := NtUiLibShowAppContainers;
  NtUiCommon.Prototypes.NtUiLibSelectAppContainer := NtUiLibSelectAppContainer;
end.
