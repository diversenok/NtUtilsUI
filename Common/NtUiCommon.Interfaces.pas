unit NtUiCommon.Interfaces;

{
  This module provides interfaces for better integrating UI components.
}

interface

uses
  DevirtualizedTree, VirtualTrees, System.Classes;

type
  // Indicates a component with a search bar that should obtain focus on Ctrl+F
  IHasSearch = interface
    ['{987D54D2-1AEA-4FCA-B9B5-890A94B961BD}']
    procedure SetSearchFocus;
  end;

  // Indicates a component that can prevent Escape from closing the dialog
  ICanConsumeEscape = interface
    ['{4280FDBC-97C0-41DC-9C96-98142BCABADF}']
    function ConsumesEscape: Boolean;
  end;

  // Indicates a component that has a collection of devirtualized nodes
  INodeCollection<I: INodeProvider> = interface
    ['{09956A79-29F9-48F6-BB40-033C27F70358}']
    // Non-type-specific information
    function GetTotalNodes: Cardinal;
    function GetTotalSelectedNodes: Cardinal;
    function GetTotalCheckedNodes: Cardinal;

    // Type-specific information
    function GetAllNodesCount: Cardinal;
    function GetAllNodes: TArray<I>;
    function GetSelectedNodesCount: Cardinal;
    function GetSelectedNodes: TArray<I>;
    function GetCheckedNodesCount: Cardinal;
    function GetCheckedNodes: TArray<I>;
    function GetFocusedNode: I;

    // Non-type-specific information
    property TotalNodes: Cardinal read GetTotalNodes;
    property TotalSelectedNodes: Cardinal read GetTotalSelectedNodes;
    property TotalCheckedNodes: Cardinal read GetTotalCheckedNodes;

    // Type-specific information
    property AllNodesCount: Cardinal read GetAllNodesCount;
    property AllNodes: TArray<I> read GetAllNodes;
    property SelectedNodesCount: Cardinal read GetSelectedNodesCount;
    property SelectedNodes: TArray<I> read GetSelectedNodes;
    property CheckedNodesCount: Cardinal read GetCheckedNodesCount;
    property CheckedNodes: TArray<I> read GetCheckedNodes;
    property FocusedNode: I read GetFocusedNode;
  end;
  INodeCollection = INodeCollection<INodeProvider>;

  // A base interaface for a components that allows observing events
  ICallback = interface
    procedure SetCallback(const Callback: TNotifyEvent);
    function GetCallback: TNotifyEvent;
    property Callback: TNotifyEvent read GetCallback write SetCallback;
  end;

  // Indicates a component that allows observing node selection changes
  INodeSelectionCallback = interface (ICallback)
    ['{CE3DD21D-BD55-44E8-B923-12DF4F62233D}']
  end;

// Delegate the implementation of INodeCollection on a devirtualized tree
function NtUiLibDelegateINodeCollection(
  Tree: TDevirtualizedTree;
  const ProviderID: TGuid
): INodeCollection;

// Delegate the implementation of INodeSelectionCallback on a devirtualized tree
function NtUiLibDelegateINodeSelectionCallback(
  Tree: TDevirtualizedTree
): INodeSelectionCallback;

implementation

uses
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TBaseTreeExtension = class (TInterfacedObject)
  private
    FTree: TDevirtualizedTree;
    FTreeWeakRef: Weak<IUnknown>;
  public
    function Attached: Boolean;
    property Tree: TDevirtualizedTree read FTree;
    constructor Create(Tree: TDevirtualizedTree);
  end;

{ TBaseTreeExtension }

function TBaseTreeExtension.Attached;
var
  StrongRef: IUnknown;
begin
  // It's safe to use the tree as long as the weak reference is alive
  Result := FTreeWeakRef.Upgrade(StrongRef);

  if not Result then
    FTree := nil;
end;

constructor TBaseTreeExtension.Create;
begin
  // We store a non-owning typed refernce and a weak interface reference to
  // correctly track object lifetime
  FTree := Tree;
  FTreeWeakRef := Tree;
end;

type
  TNodeCollectionProvider = class (TBaseTreeExtension, INodeCollection)
  private
    FIId: TGuid;
  public
    function GetTotalNodes: Cardinal;
    function GetTotalSelectedNodes: Cardinal;
    function GetTotalCheckedNodes: Cardinal;

    function GetAllNodesCount: Cardinal;
    function GetAllNodes: TArray<INodeProvider>;
    function GetSelectedNodesCount: Cardinal;
    function GetSelectedNodes: TArray<INodeProvider>;
    function GetCheckedNodesCount: Cardinal;
    function GetCheckedNodes: TArray<INodeProvider>;
    function GetFocusedNode: INodeProvider;

    constructor Create(Tree: TDevirtualizedTree; const ProviderID: TGuid);
  end;

{ TNodeCollectionProvider }

constructor TNodeCollectionProvider.Create;
begin
  inherited Create(Tree);
  FIId := ProviderID;
end;

function TNodeCollectionProvider.GetAllNodes;
var
  Node: PVirtualNode;
  Provider: INodeProvider;
  Count: Cardinal;
begin
  if not Attached then
    Exit(nil);

  Count := 0;
  SetLength(Result, GetAllNodesCount);

  for Node in FTree.Nodes do
    if Node.TryGetProvider(FIId, Provider) then
    begin
      Result[Count] := Provider;
      Inc(Count);
    end;
end;

function TNodeCollectionProvider.GetAllNodesCount;
var
  Node: PVirtualNode;
begin
  Result := 0;

  if Attached then
    for Node in FTree.Nodes do
      if Node.HasProvider(FIId) then
        Inc(Result);
end;

function TNodeCollectionProvider.GetCheckedNodes;
var
  Node: PVirtualNode;
  Provider: INodeProvider;
  Count: Cardinal;
begin
  if not Attached then
    Exit(nil);

  Count := 0;
  SetLength(Result, GetCheckedNodesCount);

  for Node in FTree.CheckedNodes do
    if Node.TryGetProvider(FIId, Provider) then
    begin
      Result[Count] := Provider;
      Inc(Count);
    end;
end;

function TNodeCollectionProvider.GetCheckedNodesCount;
var
  Node: PVirtualNode;
begin
  Result := 0;

  if Attached then
    for Node in FTree.CheckedNodes do
      if Node.HasProvider(FIId) then
        Inc(Result);
end;

function TNodeCollectionProvider.GetFocusedNode;
begin
  if not Attached or not FTree.FocusedNode.TryGetProvider(FIId, Result) then
    Result := nil;
end;

function TNodeCollectionProvider.GetSelectedNodes;
var
  Node: PVirtualNode;
  Provider: INodeProvider;
  Count: Cardinal;
begin
  if not Attached then
    Exit(nil);

  Count := 0;
  SetLength(Result, GetSelectedNodesCount);

  for Node in FTree.SelectedNodes do
    if Node.TryGetProvider(FIId, Provider) then
    begin
      Result[Count] := Provider;
      Inc(Count);
    end;
end;

function TNodeCollectionProvider.GetSelectedNodesCount;
var
  Node: PVirtualNode;
begin
  Result := 0;

  if Attached then
    for Node in FTree.SelectedNodes do
      if Node.HasProvider(FIId) then
        Inc(Result);
end;

function TNodeCollectionProvider.GetTotalCheckedNodes;
begin
  if not Attached then
    Exit(0);

  Result := FTree.CheckedCount;
end;

function TNodeCollectionProvider.GetTotalNodes;
begin
  if not Attached then
    Exit(0);

  Result := FTree.TotalCount;
end;

function TNodeCollectionProvider.GetTotalSelectedNodes;
begin
  if not Attached then
    Exit(0);

  Result := FTree.SelectedCount;
end;

type
  TBaseTreeEventsProvider = class (TBaseTreeExtension, ICallback)
  private
    FCallback: TNotifyEvent;
  protected
    procedure InvokeCallback(Sender: TObject);
  public
    procedure SetCallback(const Callback: TNotifyEvent);
    function GetCallback: TNotifyEvent;
  end;

{ TBaseTreeEventsProvider }

function TBaseTreeEventsProvider.GetCallback;
begin
  Result := FCallback;
end;

procedure TBaseTreeEventsProvider.InvokeCallback;
begin
  if Assigned(FCallback) then
    FCallback(Sender);
end;

procedure TBaseTreeEventsProvider.SetCallback;
begin
  FCallback := Callback;
end;

type
  TNodeSelectionCallbackProvider = class (TBaseTreeEventsProvider, INodeSelectionCallback)
  private
    procedure TreeCallback(Sender: TBaseVirtualTree; Node: PVirtualNode);
  public
    constructor Create(Tree: TDevirtualizedTree);
  end;

{ TNodeSelectionCallbackProvider }

constructor TNodeSelectionCallbackProvider.Create;
begin
  inherited Create(Tree);

  if Assigned(Tree) then
  begin
    Tree.OnAddToSelection := TreeCallback;
    Tree.OnRemoveFromSelection := TreeCallback;
  end;
end;

procedure TNodeSelectionCallbackProvider.TreeCallback;
begin
  InvokeCallback(Sender);
end;

{ Functions }

function NtUiLibDelegateINodeCollection;
begin
  Result := TNodeCollectionProvider.Create(Tree, ProviderID);
end;

function NtUiLibDelegateINodeSelectionCallback;
begin
  Result := TNodeSelectionCallbackProvider.Create(Tree);
end;

end.
