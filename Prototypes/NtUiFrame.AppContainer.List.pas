unit NtUiFrame.AppContainer.List;

{
  This module provides a frame for showing a list of AppContainer profiles.
}

interface

uses
  Vcl.Controls, System.Classes, Vcl.Forms, VirtualTrees,
  NtUtilsUI.VirtualTreeEx, NtUtilsUI.DevirtualizedTree, NtUiFrame.Search,
  NtUtils, NtUiCommon.Interfaces, NtUiBackend.AppContainers, Vcl.Menus,
  NtUiFrame;

type
  TAppContainerListFrame = class (TFrame, ICanConsumeEscape,
    IObservesActivation, IHasDefaultCaption, IAllowsDefaultNodeAction,
    IHasModalResult, IHasModalResultObservation)
    PopupMenu: TPopupMenu;
    cmInspect: TMenuItem;
    procedure cmInspectClick(Sender: TObject);
    procedure TreeNodeDblClick(Sender: TBaseVirtualTree;
      const HitInfo: THitInfo);
  published
    SearchBox: TSearchFrame;
    Tree: TDevirtualizedTree;
    procedure FrameMainActionSet(Sender: TObject);
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    property BackendImpl: TTreeNodeInterfaceProvider read Backend implements IHasModalResult, IHasModalResultObservation, IAllowsDefaultNodeAction;
    property SearchImpl: TSearchFrame read SearchBox implements ICanConsumeEscape, IObservesActivation;
    function GetDefaultCaption: String;
  protected
    procedure Loaded; override;
  public
    procedure LoadForUser(const User: ISid);
  end;

implementation

uses
  NtUtils.Errors, NtUiCommon.Prototypes, System.SysUtils, Winapi.Windows;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

{ TAppContainersFrame }

procedure TAppContainerListFrame.cmInspectClick(Sender: TObject);
var
  NodeProvider: INodeProvider;
  AppContainerNode: IAppContainerNode;
begin
  if not Assigned(NtUiLibShowAppContainer) then
    Exit;

  NodeProvider := Backend.FocusedNode;

  if Assigned(NodeProvider) and NodeProvider.QueryInterface(IAppContainerNode,
    AppContainerNode).IsSuccess then
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
  Backend := TTreeNodeInterfaceProvider.Create(Tree, [teSelectionChange]);
  BackendRef := Backend; // Make an owning reference

  if Assigned(NtUiLibShowAppContainer) then
  begin
    Tree.PopupMenuEx := PopupMenu;
    Backend.OnMainActionSet := FrameMainActionSet;
  end;
end;

procedure TAppContainerListFrame.LoadForUser;
var
  Parents, Children: TArray<IAppContainerNode>;
  Parent, Child: IAppContainerNode;
  Status: TNtxStatus;
begin
  Backend.BeginUpdateAuto;
  Backend.ClearItems;

  // Enumerate parent AppContainers
  Status := UiLibEnumerateAppContainers(Parents, User);
  Backend.SetStatus(Status);

  if not Status.IsSuccess then
    Exit;

  for Parent in Parents do
  begin
    Backend.AddItem(Parent);

    // Enumerate child AppContainers
    if UiLibEnumerateAppContainers(Children, User, Parent.Info.Sid).IsSuccess then
      for Child in Children do
        Backend.AddItem(Child, Parent);
  end;
end;

procedure TAppContainerListFrame.TreeNodeDblClick;
begin
  if cmInspect.Default then
    cmInspectClick(Sender);
end;

{ Integration }

function Initializer(const User: ISid): TFrameInitializer;
begin
  Result := function (AOwner: TComponent): TFrame
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
  if not Assigned(NtUiLibHostFrameShow) then
    raise ENotSupportedException.Create('Frame host not available');

  NtUiLibHostFrameShow(Initializer(User));
end;

function NtUiLibSelectAppContainer(
  Owner: TComponent;
  const User: ISid
): TRtlxAppContainerInfo;
var
  ProfileNode: IAppContainerNode;
begin
  if not Assigned(NtUiLibHostFramePick) then
    raise ENotSupportedException.Create('Frame host not available');

  Profilenode := NtUiLibHostFramePick(Owner, Initializer(User)) as IAppContainerNode;
  Result := ProfileNode.Info;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowAppContainers := NtUiLibShowAppContainers;
  NtUiCommon.Prototypes.NtUiLibSelectAppContainer := NtUiLibSelectAppContainer;
end.
