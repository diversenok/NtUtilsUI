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

  // Indicates a component that can prevent Escape from closing the dialog
  ICanConsumeEscape = interface
    ['{4280FDBC-97C0-41DC-9C96-98142BCABADF}']
    function ConsumesEscape: Boolean;
  end;

  // Indicates a component that can show a message when no data is available
  ICanShowEmptyMessage = interface
    ['{A56C56BB-9839-4B48-B727-03610765C488}']
    procedure SetEmptyMessage(const Value: String);
  end;

  // Indicates a component that suggest a modal dialog caption
  IHasDefaultCaption = interface
    ['{C6238589-5504-461B-8539-F391A4DCC52B}']
    function GetDefaultCaption: String;
  end;

  // Indicates a control that can be activates/disactivated (such as disabling
  // shortcuts when hidden)
  IObservesActivation = interface
    ['{1BE74A0E-C934-4315-A9F0-A7E3C281487E}']
    procedure SetActive(Active: Boolean);
  end;

  // Indicates a control that can delay initialization until unhidden
  IDelayedLoad = interface
    ['{B095F57F-79C5-4205-B9F8-5EE3618AD8CA}']
    procedure DelayedLoad;
  end;

  { Tree interfaces }

  // Indicates a component that allows enumerating all devirtualized nodes
  IHasNodes = interface
    ['{4B2C5DD6-52AF-4C3B-A831-B985DFA0B10E}']
    function NodeCount(const ProviderId: TGuid): Cardinal;
    function Nodes(const ProviderId: TGuid): TArray<INodeProvider>;
  end;

  // Indicates a component that allows enumerating selected devirtualized nodes
  IHasSelectedNodes = interface
    ['{E7D0A799-5719-4CA0-A76C-819C1AEF45EB}']
    function SelectedNodeCount(const ProviderId: TGuid): Cardinal;
    function SelectedNodes(const ProviderId: TGuid): TArray<INodeProvider>;
  end;

  // Indicates a component that allows observing node selection changes
  IHasSelectedNodesObservation = interface (IHasSelectedNodes)
    ['{CE3DD21D-BD55-44E8-B923-12DF4F62233D}']
    function GetOnSelectionChange: TNotifyEvent;
    procedure SetOnSelectionChange(const Callback: TNotifyEvent);
    property OnSelectionChange: TNotifyEvent read GetOnSelectionChange write SetOnSelectionChange;
  end;

  // Indicates a component that allows enumerating checked devirtualized nodes
  IHasCheckedNodes = interface
    ['{7E5EF7D7-2A31-4DD2-A643-6DAE99F4F032}']
    function CheckedNodeCount(const ProviderId: TGuid): Cardinal;
    function CheckedNodes(const ProviderId: TGuid): TArray<INodeProvider>;
  end;

  // Indicates a component that allows observing node check state changes
  IHasCheckedNodesObservation = interface (IHasCheckedNodes)
    ['{E0F17AE7-E36D-4B6A-A495-5D495026D60D}']
    function GetOnCheckedChange: TNotifyEvent;
    procedure SetOnCheckedChange(const Callback: TNotifyEvent);
    property OnCheckedChange: TNotifyEvent read GetOnCheckedChange write SetOnCheckedChange;
  end;

  // Indicates a component allowing to retrieve the focused devirtualized node
  IHasFocusedNode = interface
    ['{3B4E5A9A-C832-429B-9440-F2FC2399214E}']
    function FocusedNode: INodeProvider;
  end;

  // Indicates a component that allows modifying devirtualized nodes
  IAllowsEditingNodes = interface
    ['{05DA3293-63D8-42CB-B26A-AFA502C56A42}']
    function BeginUpdateAuto: IAutoReleasable;
    procedure ClearItems;
    procedure AddItem(const Item: INodeProvider; const Parent: INodeProvider = nil);
  end;

  TNodeProviderEvent = procedure (const Node: INodeProvider) of object;

  // Indicates a component that allows controlling default tree menu action
  IAllowsDefaultNodeAction = interface
    ['{2B8590CB-A205-4018-9975-97CB0C0F87BD}']
    function GetOnMainAction: TNodeProviderEvent;
    procedure SetOnMainAction(const Value: TNodeProviderEvent);
    function GetMainActionCaption: String;
    procedure SetMainActionCaption(const Value: String);
    property OnMainAction: TNodeProviderEvent read GetOnMainAction write SetOnMainAction;
    property MainActionCaption: String read GetMainActionCaption write SetMainActionCaption;
  end;

  { Modal dialog support }

  // Indicates a component that controls button caption for the modal dialog host
  IHasModalCaptions = interface
    ['{730893B5-A88C-42A0-9AC3-C7CD1867CA48}']
    function GetConfirmationCaption: String;
    function GetCancellationCaption: String;
    property ConfirmationCaption: String read GetConfirmationCaption;
    property CancellationCaption: String read GetCancellationCaption;
  end;

  // Indicates a component that allows returning a result from a modal dialog
  IHasModalResult = interface
    ['{F5CFA05F-11FE-46BD-8004-01696E95103D}']
    function GetModalResult: IInterface;
    property ModalResult: IInterface read GetModalResult;
  end;

  // Indicates ability to observe changes to modal result availability
  IHasModalResultObservation = interface (IHasModalResult)
    ['{54D9BDA1-4689-4650-828E-174D1C14897F}']
    function GetOnModalResultChanged: TNotifyEvent;
    procedure SetOnModalResultChanged(const Callback: TNotifyEvent);
    property OnModalResultChanged: TNotifyEvent
      read GetOnModalResultChanged
      write SetOnModalResultChanged;
  end;

{ Delegatable implementation }

type
  TTreeEventSubscription = set of (
    teSelectionChange,
    teCheckedChange
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

  TTreeNodeInterfaceProvider = class (TBaseTreeExtension, ICanShowEmptyMessage,
    IHasNodes, IHasSelectedNodes, IHasSelectedNodesObservation,
    IHasCheckedNodes, IHasCheckedNodesObservation, IHasFocusedNode, IAllowsEditingNodes,
    IAllowsDefaultNodeAction, IHasModalResult, IHasModalResultObservation)
  private
    FOnNodeSelectionChange: TNotifyEvent;
    FOnNodeCheckedChange: TNotifyEvent;
    FOnModalResultChange: TNotifyEvent;
    FOnMainAction: TNodeProviderEvent;
    FOnMainActionSet: TNotifyEvent;
    FModalResultFilter: TGuid;
    procedure TreeSelectionChanged(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeCheckedChanged(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeMainAction(Node: PVirtualNode);
    function GetOnMainActionSet: TNotifyEvent;
    procedure SetOnMainActionSet(const Value: TNotifyEvent);
  public
    procedure SetStatus(const Status: TNtxStatus);
    procedure SetEmptyMessage(const Value: String);
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
    function GetOnSelectionChange: TNotifyEvent;
    procedure SetOnSelectionChange(const Callback: TNotifyEvent);
    function GetOnCheckedChange: TNotifyEvent;
    procedure SetOnCheckedChange(const Callback: TNotifyEvent);
    function GetOnMainAction: TNodeProviderEvent;
    procedure SetOnMainAction(const Value: TNodeProviderEvent);
    function GetMainActionCaption: String;
    procedure SetMainActionCaption(const Value: String);
    property OnMainActionSet: TNotifyEvent read GetOnMainActionSet write SetOnMainActionSet;
    function GetModalResult: IInterface;
    function GetOnModalResultChanged: TNotifyEvent;
    procedure SetOnModalResultChanged(const Callback: TNotifyEvent);
    property ModalResultFilter: TGuid read FModalResultFilter write FModalResultFilter;
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
  // It's safe to use the tree on the UI thread as long as the weak reference
  // is alive
  Result := FTreeWeakRef.Upgrade(StrongRef);

  if not Result then
    FTree := nil;
end;

constructor TBaseTreeExtension.Create;
begin
  // We store a non-owning typed reference and a weak interface reference to
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

  if Assigned(Tree) then
  begin
    // Selection events
    if teSelectionChange in SubscribeTo then
    begin
      Tree.OnAddToSelection := TreeSelectionChanged;
      Tree.OnRemoveFromSelection := TreeSelectionChanged;
    end;

    // Check state event
    if teCheckedChange in SubscribeTo then
      Tree.OnChecked := TreeCheckedChanged;

    FModalResultFilter := INodeProvider;
  end;
end;

function TTreeNodeInterfaceProvider.FocusedNode;
begin
  if Attached and (FTree.SelectedCount = 1) then
    Result := FTree.FocusedNode.Provider
  else
    Result := nil;
end;

function TTreeNodeInterfaceProvider.GetMainActionCaption;
begin
  if Attached then
    Result := FTree.MainActionMenuText
  else
    Result := '';
end;

function TTreeNodeInterfaceProvider.GetModalResult;
begin
  if not Attached or (FTree.SelectedCount <> 1) or not
    FTree.FocusedNode.TryGetProvider(FModalResultFilter, Result) then
    Result := nil;
end;

function TTreeNodeInterfaceProvider.GetOnCheckedChange;
begin
  Result := FOnNodeCheckedChange;
end;

function TTreeNodeInterfaceProvider.GetOnMainAction;
begin
  Result := FOnMainAction;
end;

function TTreeNodeInterfaceProvider.GetOnMainActionSet;
begin
  Result := FOnMainActionSet;
end;

function TTreeNodeInterfaceProvider.GetOnModalResultChanged;
begin
  Result := FOnModalResultChange;
end;

function TTreeNodeInterfaceProvider.GetOnSelectionChange;
begin
  Result := FOnNodeSelectionChange;
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

procedure TTreeNodeInterfaceProvider.SetEmptyMessage;
begin
  if Attached then
    Tree.NoItemsText := Value;
end;

procedure TTreeNodeInterfaceProvider.SetMainActionCaption;
begin
  if Attached then
    FTree.MainActionMenuText := Value;
end;

procedure TTreeNodeInterfaceProvider.SetOnCheckedChange;
begin
  FOnNodeCheckedChange := Callback;
end;

procedure TTreeNodeInterfaceProvider.SetOnMainAction;
begin
  FOnMainAction := Value;

  if Attached then
  begin
    if Assigned(FOnMainAction) then
      FTree.OnMainAction := TreeMainAction
    else
      FTree.OnMainAction := nil;

    if Assigned(FOnMainActionSet) then
      FOnMainActionSet(Self);
  end;
end;

procedure TTreeNodeInterfaceProvider.SetOnMainActionSet;
begin
  FOnMainActionSet := Value;
end;

procedure TTreeNodeInterfaceProvider.SetOnModalResultChanged;
begin
  FOnModalResultChange := Callback;
end;

procedure TTreeNodeInterfaceProvider.SetOnSelectionChange;
begin
  FOnNodeSelectionChange := Callback;
end;

procedure TTreeNodeInterfaceProvider.SetStatus;
begin
  if not Attached then
    Exit;

  if Status.IsSuccess then
    SetEmptyMessage('No items to display')
  else
    SetEmptyMessage('Unable to query:'#$D#$A + Status.ToString);
end;

procedure TTreeNodeInterfaceProvider.TreeCheckedChanged;
begin
  if Assigned(FOnNodeCheckedChange) then
    FOnNodeCheckedChange(Sender);
end;

procedure TTreeNodeInterfaceProvider.TreeMainAction;
var
  Provider: INodeProvider;
begin
  if Assigned(FOnMainAction) and Node.TryGetProvider(Provider) then
    FOnMainAction(Provider);
end;

procedure TTreeNodeInterfaceProvider.TreeSelectionChanged;
begin
  if Assigned(FOnNodeSelectionChange) then
    FOnNodeSelectionChange(Sender);

  if Assigned(FOnModalResultChange) then
    FOnModalResultChange(Sender);
end;

end.
