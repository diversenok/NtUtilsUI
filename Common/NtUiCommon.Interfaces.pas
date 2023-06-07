unit NtUiCommon.Interfaces;

{
  This module provides interfaces for better integrating UI components.
}

interface

uses
  DevirtualizedTree, VirtualTrees, System.Classes, DelphiUtils.AutoObjects,
  NtUtils;

type
  { Common interfaces }

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

  // Indicates a component that can show a status of an operation
  ICanShowStatus = interface
    ['{C16901FB-80A0-4430-96AB-CD823BC370CB}']
    procedure SetStatus(const Status: TNtxStatus);
  end;

  // Indicates a component that suggest a modal dialog caption
  IHasDefaultCaption = interface
    ['{C6238589-5504-461B-8539-F391A4DCC52B}']
    function DefaultCaption: String;
  end;

  { Tree interfaces }

  // Indicates a component that allows enumerating all devirtualized nodes
  IGetNodes = interface
    ['{4B2C5DD6-52AF-4C3B-A831-B985DFA0B10E}']
    function NodeCount(const ProviderId: TGuid): Cardinal;
    function Nodes(const ProviderId: TGuid): TArray<INodeProvider>;
  end;

  // Indicates a component that allows enumerating selected devirtualized nodes
  IGetSelectedNodes = interface
    ['{E7D0A799-5719-4CA0-A76C-819C1AEF45EB}']
    function SelectedNodeCount(const ProviderId: TGuid): Cardinal;
    function SelectedNodes(const ProviderId: TGuid): TArray<INodeProvider>;
  end;

  // Indicates a component that allows enumerating checked devirtualized nodes
  IGetCheckedNodes = interface
    ['{7E5EF7D7-2A31-4DD2-A643-6DAE99F4F032}']
    function CheckedNodeCount(const ProviderId: TGuid): Cardinal;
    function CheckedNodes(const ProviderId: TGuid): TArray<INodeProvider>;
  end;

  // Indicates a component allowing to retrieve the focused devirtualized node
  IGetFocusedNode = interface
    ['{3B4E5A9A-C832-429B-9440-F2FC2399214E}']
    function FocusedNode: INodeProvider;
  end;

  // Indicates a component that allows modifying devirtualized nodes
  ISetNodes = interface
    ['{05DA3293-63D8-42CB-B26A-AFA502C56A42}']
    function BeginUpdateAuto: IAutoReleasable;
    procedure ClearItems;
    procedure AddItem(const Item: INodeProvider; const Parent: INodeProvider = nil);
  end;

  // Indicates a component that allows observing node selection changes
  IOnNodeSelection = interface
    ['{CE3DD21D-BD55-44E8-B923-12DF4F62233D}']
    function GetOnSelection: TNotifyEvent;
    procedure SetOnSelection(const Callback: TNotifyEvent);
    property OnSelection: TNotifyEvent read GetOnSelection write SetOnSelection;
  end;

{ Delegatable implementation }

type
  TTreeEventSubscription = set of (
    teSelectionChange
  );

  TBaseTreeExtension = class abstract (TInterfacedObject)
  private
    FTree: TDevirtualizedTree;
    FTreeWeakRef: Weak<IUnknown>;
  protected
    function Attached: Boolean;
    property Tree: TDevirtualizedTree read FTree;
    constructor Create(Tree: TDevirtualizedTree);
  end;

  TTreeNodeInterfaceProvider = class (TBaseTreeExtension, ICanShowStatus,
    IGetNodes, IGetSelectedNodes, IGetCheckedNodes, IGetFocusedNode, ISetNodes,
    IOnNodeSelection)
  private
    FOnNodeSelection: TNotifyEvent;
    procedure TreeSelectionChanged(Sender: TBaseVirtualTree; Node: PVirtualNode);
  public
    procedure SetStatus(const Status: TNtxStatus);
    function NodeCount(const ProviderId: TGuid): Cardinal;
    function Nodes(const ProviderId: TGuid): TArray<INodeProvider>;
    function SelectedNodeCount(const ProviderId: TGuid): Cardinal;
    function SelectedNodes(const ProviderId: TGuid): TArray<INodeProvider>;
    function CheckedNodeCount(const ProviderId: TGuid): Cardinal;
    function CheckedNodes(const ProviderId: TGuid): TArray<INodeProvider>;
    function FocusedNode: INodeProvider;
    function BeginUpdateAuto: IAutoReleasable;
    procedure ClearItems;
    procedure AddItem(const Item: INodeProvider; const Parent: INodeProvider = nil);
    function GetOnSelection: TNotifyEvent;
    procedure SetOnSelection(const Callback: TNotifyEvent);
    constructor Create(Tree: TDevirtualizedTree; SubscribeTo: TTreeEventSubscription = []);
  end;

implementation

uses
  VirtualTrees.Types, NtUiLib.Errors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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

{ TTreeNodeInterfaceProvider }

procedure TTreeNodeInterfaceProvider.AddItem;
var
  ParentNode: PVirtualNode;
begin
  if not Attached then
    Exit;

  if Assigned(Parent) then
    ParentNode := Parent.Node
  else
    ParentNode := Tree.RootNode;

  Tree.AddChildEx(ParentNode, Item);

  if Assigned(Parent) then
  begin
    Tree.Expanded[Parent.Node] := True;
    Tree.TreeOptions.PaintOptions := Tree.TreeOptions.PaintOptions
      + [toShowRoot];
  end;
end;

function TTreeNodeInterfaceProvider.BeginUpdateAuto;
begin
  if not Attached then
    Exit(nil);

  Tree.BeginUpdate;

  Result := Auto.Delay(
    procedure
    begin
      // This will capture the entire object with its weak tree reference
      if Attached then
        Tree.EndUpdate;
    end
  );
end;

function TTreeNodeInterfaceProvider.CheckedNodeCount;
var
  Node: PVirtualNode;
begin
  Result := 0;

  if Attached then
    for Node in FTree.CheckedNodes do
      if Node.HasProvider(ProviderId) then
        Inc(Result);
end;

function TTreeNodeInterfaceProvider.CheckedNodes;
var
  Node: PVirtualNode;
  Provider: INodeProvider;
  Count: Cardinal;
begin
  if not Attached then
    Exit(nil);

  Count := 0;
  SetLength(Result, CheckedNodeCount(ProviderId));

  for Node in FTree.CheckedNodes do
    if Node.TryGetProvider(ProviderId, Provider) then
    begin
      Result[Count] := Provider;
      Inc(Count);
    end;
end;

procedure TTreeNodeInterfaceProvider.ClearItems;
begin
  if Attached then
  begin
    Tree.Clear;
    Tree.TreeOptions.PaintOptions := Tree.TreeOptions.PaintOptions
      - [toShowRoot];
  end;
end;

constructor TTreeNodeInterfaceProvider.Create;
begin
  inherited Create(Tree);

  if Assigned(Tree) and (teSelectionChange in SubscribeTo) then
  begin
    Tree.OnAddToSelection := TreeSelectionChanged;
    Tree.OnRemoveFromSelection := TreeSelectionChanged;
  end;
end;

function TTreeNodeInterfaceProvider.FocusedNode;
begin
  if Attached and (FTree.SelectedCount = 1) then
    Result := FTree.FocusedNode.Provider
  else
    Result := nil;
end;

function TTreeNodeInterfaceProvider.GetOnSelection;
begin
  Result := FOnNodeSelection;
end;

function TTreeNodeInterfaceProvider.NodeCount;
var
  Node: PVirtualNode;
begin
  Result := 0;

  if Attached then
    for Node in FTree.Nodes do
      if Node.HasProvider(ProviderId) then
        Inc(Result);
end;

function TTreeNodeInterfaceProvider.Nodes;
var
  Node: PVirtualNode;
  Provider: INodeProvider;
  Count: Cardinal;
begin
  if not Attached then
    Exit(nil);

  Count := 0;
  SetLength(Result, NodeCount(ProviderId));

  for Node in FTree.Nodes do
    if Node.TryGetProvider(ProviderId, Provider) then
    begin
      Result[Count] := Provider;
      Inc(Count);
    end;
end;

function TTreeNodeInterfaceProvider.SelectedNodeCount;
var
  Node: PVirtualNode;
begin
  Result := 0;

  if Attached then
    for Node in FTree.SelectedNodes do
      if Node.HasProvider(ProviderId) then
        Inc(Result);
end;

function TTreeNodeInterfaceProvider.SelectedNodes;
var
  Node: PVirtualNode;
  Provider: INodeProvider;
  Count: Cardinal;
begin
  if not Attached then
    Exit(nil);

  Count := 0;
  SetLength(Result, SelectedNodeCount(ProviderId));

  for Node in FTree.SelectedNodes do
    if Node.TryGetProvider(ProviderId, Provider) then
    begin
      Result[Count] := Provider;
      Inc(Count);
    end;
end;

procedure TTreeNodeInterfaceProvider.SetOnSelection;
begin
  FOnNodeSelection := Callback;
end;

procedure TTreeNodeInterfaceProvider.SetStatus;
begin
  if not Attached then
    Exit;

  if Status.IsSuccess then
    Tree.NoItemsText := 'No items to display'
  else
    Tree.NoItemsText := 'Unable to query:'#$D#$A + Status.ToString;
end;

procedure TTreeNodeInterfaceProvider.TreeSelectionChanged;
begin
  if Assigned(FOnNodeSelection) then
    FOnNodeSelection(Sender);
end;

end.
