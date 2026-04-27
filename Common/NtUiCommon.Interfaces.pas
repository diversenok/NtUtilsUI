unit NtUiCommon.Interfaces;

{
  This module provides interfaces for better integrating UI components.
}

interface

uses
  NtUtilsUI.Tree, VirtualTrees, System.Classes,
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
    teSelectionChange
  );

  TBaseTreeExtension = class abstract (TInterfacedObject)
  private
    [Weak] FTree: TUiLibTree;
  protected
    function Attached: Boolean;
    property Tree: TUiLibTree read FTree;
    constructor Create(Tree: TUiLibTree);
  end;

  TTreeNodeInterfaceProvider = class (TBaseTreeExtension, ICanShowEmptyMessage,
    IAllowsDefaultNodeAction, IHasModalResult, IHasModalResultObservation)
  private
    FOnModalResultChange: TNotifyEvent;
    FOnMainAction: TNodeProviderEvent;
    FOnMainActionSet: TNotifyEvent;
    FModalResultFilter: TGuid;
    procedure TreeSelectionChanged(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeMainAction(Node: INodeProvider);
    function GetOnMainActionSet: TNotifyEvent;
    procedure SetOnMainActionSet(const Value: TNotifyEvent);
  public
    procedure SetEmptyMessage(const Value: String);
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
    constructor Create(Tree: TUiLibTree; SubscribeTo: TTreeEventSubscription = []);
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

    FModalResultFilter := INodeProvider;
  end;
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

procedure TTreeNodeInterfaceProvider.TreeMainAction;
begin
  if Assigned(FOnMainAction) then
    FOnMainAction(Node);
end;

procedure TTreeNodeInterfaceProvider.TreeSelectionChanged;
begin
  if Assigned(FOnModalResultChange) then
    FOnModalResultChange(Sender);
end;

end.
