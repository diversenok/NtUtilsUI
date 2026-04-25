unit NtUiCommon.Interfaces;

{
  This module provides interfaces for better integrating UI components.
}

interface

uses
  NtUtilsUI.DevirtualizedTree, VirtualTrees, System.Classes,
  DelphiUtils.AutoObjects, NtUtils, NtUtilsUI;

type
  { Common interfaces }

  // Indicates a component that can show a message when no data is available
  ICanShowEmptyMessage = interface
    ['{A56C56BB-9839-4B48-B727-03610765C488}']
    procedure SetEmptyMessage(const Value: String);
  end;

  // Indicates a control that can delay initialization until unhidden
  IDelayedLoad = interface
    ['{B095F57F-79C5-4205-B9F8-5EE3618AD8CA}']
    procedure DelayedLoad;
  end;

  { Tree interfaces }

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
  IHasModalButtonCaptions = interface
    ['{730893B5-A88C-42A0-9AC3-C7CD1867CA48}']
    function GetConfirmationCaption: String;
    function GetCancellationCaption: String;
    property ConfirmationCaption: String read GetConfirmationCaption;
    property CancellationCaption: String read GetCancellationCaption;
  end;

  // Allows a tree node to opt-out of being returned as a modal result
  IOptionalModalResultNode = interface
    ['{0B51C7F3-0E9A-4691-A1B0-6EF1769E05F2}']
    function GetAllowsModalReturn: Boolean;
    property AllowsModalReturn: Boolean read GetAllowsModalReturn;
  end;

{ Delegatable implementation }

type
  TTreeEventSubscription = set of (
    teSelectionChange,
    teCheckedChange
  );

  TBaseTreeExtension = class abstract (TInterfacedObject)
  private
    [Weak] FTree: TDevirtualizedTree;
  protected
    function Attached: Boolean;
    property Tree: TDevirtualizedTree read FTree;
    constructor Create(Tree: TDevirtualizedTree);
  end;

  TTreeNodeInterfaceProvider = class (TBaseTreeExtension, ICanShowEmptyMessage,
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
    procedure TreeMainAction(Node: INodeProvider);
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
    function GetHasModalResult: Boolean;
    function GetOnModalResultChanged: TNotifyEvent;
    procedure SetOnModalResultChanged(const Callback: TNotifyEvent);
    property ModalResultFilter: TGuid read FModalResultFilter write FModalResultFilter;
    constructor Create(Tree: TDevirtualizedTree; SubscribeTo: TTreeEventSubscription = []);
  end;

implementation

uses
  VirtualTrees.Types, NtUtils.Errors, NtUiLib.Errors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TBaseTreeExtension }

function TBaseTreeExtension.Attached;
begin
  Result := Assigned(FTree);
end;

constructor TBaseTreeExtension.Create;
begin
  FTree := Tree;
end;

{ TTreeNodeInterfaceProvider }

procedure TTreeNodeInterfaceProvider.AddItem;
begin
  if not Attached then
    Exit;

  Tree.AddChild(Item, Parent);
end;

function TTreeNodeInterfaceProvider.BeginUpdateAuto;
begin
  if not Attached then
    Exit(nil);

  Tree.BeginUpdate;

  Result := Auto.Defer(
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
    Tree.Clear;
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

function TTreeNodeInterfaceProvider.GetHasModalResult;
begin
  // Our implementation of GetModalResult is simple enough so there is nothing
  // to optimize here, but other code might benefit from it.
  Result := Assigned(GetModalResult());
end;

function TTreeNodeInterfaceProvider.GetMainActionCaption;
begin
  if Attached then
    Result := FTree.MainActionMenuText
  else
    Result := '';
end;

function TTreeNodeInterfaceProvider.GetModalResult;
var
  ModalChecker: IOptionalModalResultNode;
begin
  // Rertieve the focused node and test it against the modal return filter
  if not Attached or (FTree.SelectedCount <> 1) or not
    FTree.FocusedNode.TryGetProvider(FModalResultFilter, Result) then
    Exit(nil);

  // Ask the node if it's okay with being returned as a modal result
  if Result.QueryInterface(IOptionalModalResultNode, ModalChecker).IsSuccess and
    not ModalChecker.AllowsModalReturn then
    Exit(nil);
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
    Tree.EmptyListMessage := Value;
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
begin
  if Assigned(FOnMainAction) then
    FOnMainAction(Node);
end;

procedure TTreeNodeInterfaceProvider.TreeSelectionChanged;
begin
  if Assigned(FOnNodeSelectionChange) then
    FOnNodeSelectionChange(Sender);

  if Assigned(FOnModalResultChange) then
    FOnModalResultChange(Sender);
end;

end.
