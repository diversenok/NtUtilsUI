unit NtUiFrame.AppContainers;

{
  This module provides a frame for showing a list of AppContainer profiles.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, DevirtualizedTree.Provider,
  NtUiFrame.Search, NtUtils, NtUiCommon.Interfaces, NtUiBackend.AppContainers;

type
  IAppContainerNodeCollection = INodeCollection<IAppContainerNode>;

  TInspectAppContainer = procedure (const Node: IAppContainerNode) of object;

  TAppContainersFrame = class(TFrame, IHasSearch, ICanConsumeEscape, IAppContainerNodeCollection)
    SearchBox: TSearchFrame;
    Tree: TDevirtualizedTree;
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeRemoveFromSelection(Sender: TBaseVirtualTree;
      Node: PVirtualNode);
  private
    FOnInspect: TInspectAppContainer;
    FOnSelectionChanged: TNotifyEvent;
    FNodeCollectionImpl: IAppContainerNodeCollection;

    procedure InspectNode(Node: PVirtualNode);
    procedure SetOnInspect(const Value: TInspectAppContainer);

    property HasSearchImpl: TSearchFrame read SearchBox implements IHasSearch;
    property CanConsumeEscapeImpl: TSearchFrame read SearchBox implements ICanConsumeEscape;
    property NodeCollectionImpl: IAppContainerNodeCollection read FNodeCollectionImpl implements IAppContainerNodeCollection;
  protected
    procedure Loaded; override;
  public

    function BeginUpdateAuto: IAutoReleasable;
    procedure ClearItems;
    procedure AddItem(const Item: IAppContainerNode; const Parent: IAppContainerNode = nil);
    procedure SetNoItemsStatus(const Status: TNtxStatus);

    property OnInspect: TInspectAppContainer read FOnInspect write SetOnInspect;
    property OnSelectionChanged: TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
  end;

implementation

uses
  NtUtils.Security.Sid, NtUtils.SysUtils, NtUtils.Packages, DelphiUtils.Arrays,
  NtUiLib.Errors, DelphiUiLib.Reflection.Strings, UI.Helper, VirtualTrees.Types,
  UI.Colors;

{$R *.dfm}

{ TAppContainersFrame }

procedure TAppContainersFrame.AddItem;
var
  ParentNode: PVirtualNode;
begin
  if Assigned(Parent) then
    ParentNode := Parent.Node
  else
    ParentNode := Tree.RootNode;

  Tree.AddChildEx(ParentNode, Item);

  if Assigned(Parent) then
  begin
    Tree.Expanded[Parent.Node] := True;
    Tree.TreeOptions.PaintOptions := Tree.TreeOptions.PaintOptions + [toShowRoot];
  end;
end;

function TAppContainersFrame.BeginUpdateAuto;
begin
  Result := Tree.BeginUpdateAuto;
end;

procedure TAppContainersFrame.ClearItems;
begin
  Tree.Clear;
  Tree.TreeOptions.PaintOptions := Tree.TreeOptions.PaintOptions - [toShowRoot];
end;

procedure TAppContainersFrame.InspectNode;
var
  AppContainerNode: IAppContainerNode;
begin
  if Node.TryGetProvider(IAppContainerNode, AppContainerNode) then
    FOnInspect(AppContainerNode);
end;

procedure TAppContainersFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  INodeCollection(FNodeCollectionImpl) := NtUiLibDelegateINodeCollection(Tree, IAppContainerNode);
end;

procedure TAppContainersFrame.SetNoItemsStatus;
begin
  if Status.IsSuccess then
    Tree.NoItemsText := 'No items to display'
  else
    Tree.NoItemsText := 'Unable to query:'#$D#$A + Status.ToString;
end;

procedure TAppContainersFrame.SetOnInspect;
begin
  FOnInspect := Value;

  if Assigned(Value) then
    Tree.OnInspectNode := InspectNode
  else
    Tree.OnInspectNode := nil;
end;

procedure TAppContainersFrame.TreeAddToSelection;
begin
  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

procedure TAppContainersFrame.TreeRemoveFromSelection;
begin
  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

end.
