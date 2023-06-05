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
  TInspectAppContainer = procedure (const Node: IAppContainerNode) of object;

  TAppContainersFrame = class(TFrame, IHasSearch, ICanConsumeEscape)
    SearchBox: TSearchFrame;
    Tree: TDevirtualizedTree;
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeRemoveFromSelection(Sender: TBaseVirtualTree;
      Node: PVirtualNode);
  private
    FOnInspect: TInspectAppContainer;
    FOnSelectionChanged: TNotifyEvent;
    procedure InspectNode(Node: PVirtualNode);
    procedure SetOnInspect(const Value: TInspectAppContainer);
    function GetSelectedCount: Integer;
    function GetSelected: TArray<IAppContainerNode>;
    function GetFocusedItem: IAppContainerNode;
    property HasSearchImpl: TSearchFrame read SearchBox implements IHasSearch;
    property CanConsumeEscapeImpl: TSearchFrame read SearchBox implements ICanConsumeEscape;
  protected
    procedure Loaded; override;
  public
    procedure ClearItems;
    function BeginUpdateAuto: IAutoReleasable;
    procedure AddItem(const Item: IAppContainerNode; const Parent: IAppContainerNode = nil);
    property OnInspect: TInspectAppContainer read FOnInspect write SetOnInspect;
    property OnSelectionChanged: TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
    property Selected: TArray<IAppContainerNode> read GetSelected;
    property SelectedCount: Integer read GetSelectedCount;
    property FocusedItem: IAppContainerNode read GetFocusedItem;
    procedure SetNoItemsStatus(const Status: TNtxStatus);
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

function TAppContainersFrame.GetFocusedItem;
begin
  if not Tree.FocusedNode.TryGetProvider(IAppContainerNode, Result) then
    Result := nil;
end;

function TAppContainersFrame.GetSelected;
begin
  Result := TArray.Convert<PVirtualNode, IAppContainerNode>(
    Tree.SelectedNodes.ToArray,
    function (
      const Node: PVirtualNode;
      out Provider: IAppContainerNode
    ): Boolean
    begin
      Result := Node.TryGetProvider(IAppContainerNode, Provider);
    end
  );
end;

function TAppContainersFrame.GetSelectedCount;
begin
  Result := Tree.SelectedCount;
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
