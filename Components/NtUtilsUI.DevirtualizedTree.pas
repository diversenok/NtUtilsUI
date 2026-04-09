unit NtUtilsUI.DevirtualizedTree;

{
  This module provides a full runtime definition for a devirtualized tree view
  based on the virtual tree view where each node has a dedicated provider that
  customizes its appearance.

  NOTE: Keep the published interface in sync with the design-time definition!
}

interface

uses
  VirtualTrees, NtUtilsUI.VirtualTreeEx, Vcl.Graphics, Vcl.Controls,
  System.Classes, System.Types;

type
  PVirtualNode = VirtualTrees.PVirtualNode;

  INodeProvider = interface
    ['{EF28060A-3354-4E43-BE46-5758144219F4}']
    procedure Attach(Node: PVirtualNode);
    procedure Detach;
    procedure Initialize;
    function InitializeChildren: Boolean;
    procedure Invalidate;

    function GetTree: TBaseVirtualTree;
    function GetNode: PVirtualNode;
    function GetColumnText(Column: TColumnIndex): String;
    function GetHint: String;
    function GetHasColor: Boolean;
    function GetColor: TColor;
    function GetHasFontColor: Boolean;
    function GetFontColor: TColor;
    function GetHasFontColorForColumn(Column: TColumnIndex): Boolean;
    function GetFontColorForColumn(Column: TColumnIndex): TColor;
    function GetHasFontStyle: Boolean;
    function GetFontStyle: TFontStyles;
    function GetHasFontStyleForColumn(Column: TColumnIndex): Boolean;
    function GetFontStyleForColumn(Column: TColumnIndex): TFontStyles;
    function GetHasCursor: Boolean;
    function GetCursor: TCursor;
    function GetEnabledMainActionMenu: Boolean;

    property Tree: TBaseVirtualTree read GetTree;
    property Node: PVirtualNode read GetNode;
    property ColumnText[Column: TColumnIndex]: String read GetColumnText;
    property Hint: String read GetHint;
    property HasColor: Boolean read GetHasColor;
    property Color: TColor read GetColor;
    property HasFontColor: Boolean read GetHasFontColor;
    property FontColor: TColor read GetFontColor;
    property HasFontColorForColumn[Column: TColumnIndex]: Boolean read GetHasFontColorForColumn;
    property FontColorForColumn[Column: TColumnIndex]: TColor read GetFontColorForColumn;
    property HasFontStyle: Boolean read GetHasFontStyle;
    property FontStyle: TFontStyles read GetFontStyle;
    property HasFontStyleForColumn[Column: TColumnIndex]: Boolean read GetHasFontStyleForColumn;
    property FontStyleForColumn[Column: TColumnIndex]: TFontStyles read GetFontStyleForColumn;
    property HasCursor: Boolean read GetHasCursor;
    property Cursor: TCursor read GetCursor;
    property EnabledMainActionMenu: Boolean read GetEnabledMainActionMenu;

    procedure NotifyChecked;
    procedure NotifySelected;
    procedure NotifyExpanding(var HasChildren: Boolean);
    procedure NotifyCollapsing(var HasChildren: Boolean);
    function SearchExpression(const UpcasedExpression: String; Column: TColumnIndex): Boolean;
    function SearchNumber(const Value: UInt64; Signed: Boolean; Column: TColumnIndex): Boolean;
  end;

  TVirtualNodeHelper = record helper for TVirtualNode
  private
    procedure SetProvider(const Value: INodeProvider);
    function GetProvider: INodeProvider;
  public
    function HasProvider: Boolean; overload;
    function HasProvider(const IID: TGuid): Boolean; overload;
    function TryGetProvider(out Provider: INodeProvider): Boolean; overload;
    function TryGetProvider(const IID: TGuid; out Provider): Boolean; overload;
    property Provider: INodeProvider read GetProvider write SetProvider;
  end;

  TDevirtualizedTree = class(TVirtualStringTreeEx)
  protected
    procedure DoGetText(var pEventArgs: TVSTGetCellTextEventArgs); override;
    function DoGetNodeHint(Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle): string; override;
    procedure DoBeforeItemErase(Canvas: TCanvas; Node: PVirtualNode; ItemRect: TRect; var Color: TColor; var EraseAction: TItemEraseAction); override;
    procedure DoPaintText(Node: PVirtualNode; const Canvas: TCanvas; Column: TColumnIndex; TextType: TVSTTextType); override;
    procedure DoChecked(Node: PVirtualNode); override;
    procedure DoChange(Node: PVirtualNode); override;
    procedure DoRemoveFromSelection(Node: PVirtualNode); override;
    procedure ValidateNodeDataSize(var Size: Integer); override;
    function DoExpanding(Node: PVirtualNode): Boolean; override;
    function DoCollapsing(Node: PVirtualNode): Boolean; override;
    function DoInitChildren(Node: PVirtualNode; var ChildCount: Cardinal): Boolean; override;
    procedure DoGetCursor(var Cursor: TCursor); override;
    procedure DoFreeNode(Node: PVirtualNode); override;
    procedure DoInitNode(Parent, Node: PVirtualNode; var InitStates: TVirtualNodeInitStates); override;
  public
    function OverrideMainActionMenuEnabled(Node: PVirtualNode): Boolean; override;
    function AddChildEx(Parent: PVirtualNode; const Provider: INodeProvider): INodeProvider;
    function InsertNodeEx(Node: PVirtualNode; Mode: TVTNodeAttachMode; const Provider: INodeProvider): INodeProvider;
    procedure ApplyFilter(const Query: String; UseColumn: TColumnIndex = -1);
  end;

  TNodeProvider = class (TInterfacedObject, INodeProvider)
  protected
    FInitialized: Boolean;
    FHasColor: Boolean;
    FHasFontColor: Boolean;
    FHasFontStyle: Boolean;
    FHasCursor: Boolean;
    FEnabledMainActionMenu: Boolean;
    FFirstExpandingCalled: Boolean;
    FTree: TDevirtualizedTree;
    FNode: PVirtualNode;
    FColumnText: TArray<String>;
    FHint: String;
    FColor: TColor;
    FFontColor: TColor;
    FHasFontColorForColumn: TArray<Boolean>;
    FFontColorForColumn: TArray<TColor>;
    FFontStyle: TFontStyles;
    FHasFontStyleForColumn: TArray<Boolean>;
    FFontStyleForColumn: TArray<TFontStyles>;
    FCursor: TCursor;

    function Attached: Boolean; virtual;
    procedure Attach(Value: PVirtualNode); virtual;
    procedure Detach; virtual;
    procedure Initialize; virtual;
    function InitializeChildren: Boolean; virtual;
    procedure Invalidate; virtual;
    procedure NotifyChecked; virtual;
    procedure NotifySelected; virtual;
    procedure NotifyExpanding(var HasChildren: Boolean); virtual;
    procedure NotifyCollapsing(var HasChildren: Boolean); virtual;
    procedure NotifyFirstExpanding; virtual;
    function SearchExpression(const UpcasedExpression: String; Column: TColumnIndex): Boolean; virtual;
    function SearchNumber(const Value: UInt64; Signed: Boolean; Column: TColumnIndex): Boolean; virtual;

    function GetTree: TBaseVirtualTree; virtual;
    function GetNode: PVirtualNode; virtual;
    function GetColumnText(Column: TColumnIndex): String; virtual;
    function GetHint: String; virtual;
    function GetHasColor: Boolean; virtual;
    function GetColor: TColor; virtual;
    function GetHasFontColor: Boolean; virtual;
    function GetFontColor: TColor; virtual;
    function GetHasFontColorForColumn(Column: TColumnIndex): Boolean; virtual;
    function GetFontColorForColumn(Column: TColumnIndex): TColor; virtual;
    function GetHasFontStyle: Boolean; virtual;
    function GetFontStyle: TFontStyles; virtual;
    function GetHasFontStyleForColumn(Column: TColumnIndex): Boolean; virtual;
    function GetFontStyleForColumn(Column: TColumnIndex): TFontStyles; virtual;
    function GetHasCursor: Boolean; virtual;
    function GetCursor: TCursor; virtual;
    function GetEnabledMainActionMenu: Boolean; virtual;

    procedure SetColumnText(Column: TColumnIndex; const Value: String); virtual;
    procedure SetHint(const Value: String); virtual;
    procedure SetColor(Value: TColor); virtual;
    procedure SetFontColor(Value: TColor); virtual;
    procedure SetFontColorForColumn(Column: TColumnIndex; Value: TColor); virtual;
    procedure SetFontStyle(Value: TFontStyles); virtual;
    procedure SetFontStyleForColumn(Column: TColumnIndex; Value: TFontStyles); virtual;
    procedure SetEnabledMainActionMenu(Value: Boolean); virtual;
    procedure SetCursor(Value: TCursor); virtual;

    procedure ResetColor; virtual;
    procedure ResetFontColor; virtual;
    procedure ResetFontColorForColumn(Column: TColumnIndex); virtual;
    procedure ResetFontStyle; virtual;
    procedure ResetFontStyleForColumn(Column: TColumnIndex); virtual;
    procedure ResetCursor; virtual;
  public
    constructor Create(InitialColumnCount: Integer = 1);
  end;

  TDVTChangeEvent = procedure(
    Sender: TDevirtualizedTree;
    Node: PVirtualNode
  ) of object;

  IEditableNodeProvider = interface (INodeProvider)
    ['{2C3C26E6-6820-416D-BD44-AFE0D3AD7DC8}']

    procedure SetColumnText(Column: TColumnIndex; const Value: String);
    procedure SetHint(const Value: String);
    procedure SetColor(Value: TColor);
    procedure SetFontColor(Value: TColor);
    procedure SetFontColorForColumn(Column: TColumnIndex; Value: TColor);
    procedure SetFontStyle(Value: TFontStyles);
    procedure SetFontStyleForColumn(Column: TColumnIndex; Value: TFontStyles);
    procedure SetEnabledMainActionMenu(Value: Boolean);
    procedure SetCursor(Value: TCursor);

    procedure ResetColor;
    procedure ResetFontColor;
    procedure ResetFontColorForColumn(Column: TColumnIndex);
    procedure ResetFontStyle;
    procedure ResetFontStyleForColumn(Column: TColumnIndex);
    procedure ResetCursor;

    function GetOnInitialize: TDVTChangeEvent;
    function GetOnInitializeChildren: TDVTChangeEvent;
    function GetOnAttach: TDVTChangeEvent;
    function GetOnDetach: TDVTChangeEvent;
    function GetOnChecked: TDVTChangeEvent;
    function GetOnSelected: TDVTChangeEvent;
    function GetOnExpanding: TDVTChangeEvent;
    function GetOnFirstExpanding: TDVTChangeEvent;
    function GetOnCollapsing: TDVTChangeEvent;
    procedure SetOnInitialize(Value: TDVTChangeEvent);
    procedure SetOnInitializeChildren(Value: TDVTChangeEvent);
    procedure SetOnAttach(Value: TDVTChangeEvent);
    procedure SetOnDetach(Value: TDVTChangeEvent);
    procedure SetOnChecked(Value: TDVTChangeEvent);
    procedure SetOnSelected(Value: TDVTChangeEvent);
    procedure SetOnExpanding(Value: TDVTChangeEvent);
    procedure SetOnFirstExpanding(Value: TDVTChangeEvent);
    procedure SetOnCollapsing(Value: TDVTChangeEvent);

    property Tree: TBaseVirtualTree read GetTree;
    property Node: PVirtualNode read GetNode;
    property ColumnText[Column: TColumnIndex]: String read GetColumnText write SetColumnText;
    property Hint: String read GetHint write SetHint;
    property HasColor: Boolean read GetHasColor;
    property Color: TColor read GetColor write SetColor;
    property HasFontColor: Boolean read GetHasFontColor;
    property FontColor: TColor read GetFontColor write SetFontColor;
    property HasFontColorForColumn[Column: TColumnIndex]: Boolean read GetHasFontColorForColumn;
    property FontColorForColumn[Column: TColumnIndex]: TColor read GetFontColorForColumn write SetFontColorForColumn;
    property HasFontStyle: Boolean read GetHasFontStyle;
    property FontStyle: TFontStyles read GetFontStyle write SetFontStyle;
    property HasFontStyleForColumn[Column: TColumnIndex]: Boolean read GetHasFontStyleForColumn;
    property FontStyleForColumn[Column: TColumnIndex]: TFontStyles read GetFontStyleForColumn write SetFontStyleForColumn;
    property HasCursor: Boolean read GetHasCursor;
    property Cursor: TCursor read GetCursor write SetCursor;
    property EnabledMainActionMenu: Boolean read GetEnabledMainActionMenu write SetEnabledMainActionMenu;
    property OnInitialize: TDVTChangeEvent read GetOnInitialize write SetOnInitialize;
    property OnInitializeChildren: TDVTChangeEvent read GetOnInitializeChildren write SetOnInitializeChildren;
    property OnAttach: TDVTChangeEvent read GetOnAttach write SetOnAttach;
    property OnDetach: TDVTChangeEvent read GetOnDetach write SetOnDetach;
    property OnChecked: TDVTChangeEvent read GetOnChecked write SetOnChecked;
    property OnSelected: TDVTChangeEvent read GetOnSelected write SetOnSelected;
    property OnExpanding: TDVTChangeEvent read GetOnExpanding write SetOnExpanding;
    property OnFirstExpanding: TDVTChangeEvent read GetOnFirstExpanding write SetOnFirstExpanding;
    property OnCollapsing: TDVTChangeEvent read GetOnCollapsing write SetOnCollapsing;
  end;

  TEditableNodeProvider = class (TNodeProvider, IEditableNodeProvider)
  protected
    FOnInitialize: TDVTChangeEvent;
    FOnInitializeChildren: TDVTChangeEvent;
    FOnAttach: TDVTChangeEvent;
    FOnDetach: TDVTChangeEvent;
    FOnChecked: TDVTChangeEvent;
    FOnSelected: TDVTChangeEvent;
    FOnExpanding, FOnFitstExpanding, FOnCollapsing: TDVTChangeEvent;
    FPreviouslySelected, FPreviouslySelectedValid: Boolean;

    function GetOnInitialize: TDVTChangeEvent;
    function GetOnInitializeChildren: TDVTChangeEvent;
    function GetOnAttach: TDVTChangeEvent; virtual;
    function GetOnDetach: TDVTChangeEvent; virtual;
    function GetOnChecked: TDVTChangeEvent; virtual;
    function GetOnSelected: TDVTChangeEvent; virtual;
    function GetOnExpanding: TDVTChangeEvent; virtual;
    function GetOnFirstExpanding: TDVTChangeEvent;
    function GetOnCollapsing: TDVTChangeEvent; virtual;
    procedure SetOnInitialize(Value: TDVTChangeEvent);
    procedure SetOnInitializeChildren(Value: TDVTChangeEvent);
    procedure SetOnAttach(Value: TDVTChangeEvent); virtual;
    procedure SetOnDetach(Value: TDVTChangeEvent); virtual;
    procedure SetOnChecked(Value: TDVTChangeEvent); virtual;
    procedure SetOnSelected(Value: TDVTChangeEvent); virtual;
    procedure SetOnExpanding(Value: TDVTChangeEvent); virtual;
    procedure SetOnFirstExpanding(Value: TDVTChangeEvent);
    procedure SetOnCollapsing(Value: TDVTChangeEvent); virtual;

    procedure Attach(Value: PVirtualNode); override;
    procedure Detach; override;
    procedure NotifyChecked; override;
    procedure NotifySelected; override;
    procedure NotifyExpanding(var HasChildren: Boolean); override;
    procedure NotifyCollapsing(var HasChildren: Boolean); override;
  end;

// Collect node providers from node enumerator
function CollectNodeProviders(
  const NodeEnumeration: TVTVirtualNodeEnumeration;
  const ProviderId: TGuid
): TArray<INodeProvider>;

implementation

uses
  Winapi.Windows, System.SysUtils, NtUtils.SysUtils;

{ TVirtualNodeHelper }

function TVirtualNodeHelper.GetProvider;
begin
  if not TryGetProvider(Result) then
    Result := nil;
end;

function TVirtualNodeHelper.HasProvider: Boolean;
begin
  Result := Assigned(@Self) and Assigned(Pointer(GetData^));
end;

function TVirtualNodeHelper.HasProvider(const IID: TGuid): Boolean;
var
  Provider: IInterface;
begin
  Result := TryGetProvider(IID, Provider);
end;

procedure TVirtualNodeHelper.SetProvider;
begin
  // We don't support attaching providers (or any data, for that matter) while
  // designing the component in the IDE
  if csDesigning in TreeFromNode(@Self).ComponentState then
    Exit;

  if HasProvider then
    Provider._Release;

  SetData(IInterface(Value));
  Value.Attach(@Self);
end;

function TVirtualNodeHelper.TryGetProvider(
  out Provider: INodeProvider
): Boolean;
begin
  Result := TryGetProvider(INodeProvider, Provider);
end;

function TVirtualNodeHelper.TryGetProvider(
  const IID: TGuid;
  out Provider
): Boolean;
begin
  Result := HasProvider and Succeeded(IInterface(GetData^).QueryInterface(IID,
    Provider));
end;

{ TDevirtualizedTree }

function TDevirtualizedTree.AddChildEx;
begin
  Assert(Assigned(Provider), 'Provider must not be null');
  Provider.Attach(inherited AddChild(Parent, IInterface(Provider)));
  Result := Provider;
end;

procedure TDevirtualizedTree.ApplyFilter;
var
  Node, Parent: PVirtualNode;
  Provider: INodeProvider;
  SearchColumns: TColumnsArray;
  Column: TVirtualTreeColumn;
  Matches, IsNumberSearch, IsSignedNumber: Boolean;
  Expression: String;
  NumberQuery: UInt64;
begin
  // Select which columns we want to search
  if Header.Columns.IsValidColumn(UseColumn) then
    SearchColumns := [Header.Columns[UseColumn]]
  else
    SearchColumns := Header.Columns.GetVisibleColumns;

  BeginUpdateAuto;

  // Reset visibility
  for Node in Nodes do
    if Node.TryGetProvider(Provider) then
      IsVisible[Node] := Provider.SearchExpression('', -1);

  if Query = '' then
    Exit;

  // Check if the query parses into a number
  IsNumberSearch := RtlxStrToUInt64(Query, NumberQuery, nsDecimal,
    [nsHexadecimal], True, [npSpace, npAccent, npApostrophe, npUnderscore]);
  IsSignedNumber := IsNumberSearch and (Length(Query) > 1) and
    (Query[Low(String)] = '-');

  // Prepare an upcased expression for text search
  Expression := '*' + RtlxUpperString(Query) + '*';

  // Collect nodes that are visible without the search and test each one
  // against the query
  for Node in VisibleNodes.ToArray do
    if Node.TryGetProvider(Provider) then
    begin
      Matches := False;

      // At least one coulmn should match
      for Column in SearchColumns do
      begin
        Matches := (IsNumberSearch and
          Provider.SearchNumber(NumberQuery, IsSignedNumber, Column.Index)) or
          Provider.SearchExpression(Expression, Column.Index);

        if Matches then
          Break;
      end;

      if Matches then
      begin
        // Make the node and all of its parents visible
        Parent := Node;
        repeat
          IsVisible[Parent] := True;
          Parent := NodeParent[Parent];
        until not Assigned(Parent);
      end
      else
        IsVisible[Node] := False;
    end;
end;

procedure TDevirtualizedTree.DoBeforeItemErase;
var
  Provider: INodeProvider;
begin
  // Pre-load background color
  if Node.TryGetProvider(Provider) and Provider.HasColor then
    Color := Provider.Color;

  inherited;
end;

procedure TDevirtualizedTree.DoChange;
var
  Provider: INodeProvider;
begin
  inherited;

  if Assigned(Node) then
  begin
    // Use the supplied node when available

    if Node.TryGetProvider(Provider) then
      Provider.NotifySelected;
  end
  else
  begin
    // Cannot tell which node changed; need to notify all of them

    for Node in Nodes do
      if Node.TryGetProvider(Provider) then
        Provider.NotifySelected;
  end;
end;

procedure TDevirtualizedTree.DoChecked;
var
  Provider: INodeProvider;
begin
  inherited;

  if Node.TryGetProvider(Provider) then
    Provider.NotifyChecked;
end;

function TDevirtualizedTree.DoCollapsing;
var
  Provider: INodeProvider;
begin
  Result := inherited;

  if Node.TryGetProvider(Provider) then
    Provider.NotifyCollapsing(Result);
end;

function TDevirtualizedTree.DoExpanding;
var
  Provider: INodeProvider;
begin
  Result := inherited;

  if Node.TryGetProvider(Provider) then
    Provider.NotifyExpanding(Result);
end;

procedure TDevirtualizedTree.DoFreeNode;
var
  Provider: INodeProvider;
begin
  if Node.TryGetProvider(Provider) then
    Provider.Detach;

  inherited;
end;

procedure TDevirtualizedTree.DoGetCursor;
var
  Provider: INodeProvider;
begin
  if GetNodeAt(ScreenToClient(Mouse.CursorPos)).TryGetProvider(Provider) and
    Provider.HasCursor then
    Cursor := Provider.Cursor;

  inherited;
end;

function TDevirtualizedTree.DoGetNodeHint;
var
  Provider: INodeProvider;
begin
  Result := inherited;

  // Override inherited hint with the one provided by the node
  if not Assigned(OnGetHint) and Node.TryGetProvider(Provider) then
    Result := Provider.Hint;
end;

procedure TDevirtualizedTree.DoGetText;
var
  Provider: INodeProvider;
begin
  // (Copied initialization from the parent)
  if not (vsInitialized in pEventArgs.Node.States) then
    InitNode(pEventArgs.Node);

  // Pre-load the text
  if pEventArgs.Node.TryGetProvider(Provider) then
    pEventArgs.CellText := Provider.ColumnText[pEventArgs.Column];

  inherited;
end;

function TDevirtualizedTree.DoInitChildren;
var
  Provider: INodeProvider;
begin
  Result := inherited or (Node.TryGetProvider(Provider) and
    Provider.InitializeChildren);
end;

procedure TDevirtualizedTree.DoInitNode;
var
  Provider: INodeProvider;
begin
  inherited;

  if Node.TryGetProvider(Provider) then
    Provider.Initialize;
end;

procedure TDevirtualizedTree.DoPaintText;
var
  Provider: INodeProvider;
begin
  // Pre-load font styles
  if (TextType = ttNormal) and Node.TryGetProvider(Provider) then
  begin
    if Provider.HasFontColorForColumn[Column] then
      Canvas.Font.Color := Provider.FontColorForColumn[Column]
    else if Provider.HasFontColor then
      Canvas.Font.Color := Provider.FontColor;

    if Provider.HasFontStyleForColumn[Column] then
      Canvas.Font.Style := Provider.FontStyleForColumn[Column]
    else if Provider.HasFontStyle then
      Canvas.Font.Style := Provider.FontStyle;
  end;

  inherited;
end;

procedure TDevirtualizedTree.DoRemoveFromSelection;
var
  Provider: INodeProvider;
begin
  inherited;

  // Note: do not invoke events on a half-destroyed form
  if not (csDestroying in ComponentState) and Node.TryGetProvider(Provider) then
    Provider.NotifySelected;
end;

function TDevirtualizedTree.InsertNodeEx;
var
  NewNode: PVirtualNode;
begin
  Assert(Assigned(Provider), 'Provider must not be null');

  // Note: InsertNode doesn't have an overload that takes an interface as a
  // parameter like AddNode does. Reproduce AddNode's behavior by adding the
  // provider as a pointer and then adjusting its lifetime.
  NewNode := inherited InsertNode(Node, Mode, Pointer(Provider));
  Include(NewNode.States, vsReleaseCallOnUserDataRequired);
  Provider._AddRef;

  // Notify the provider of completion
  Provider.Attach(NewNode);
  Result := Provider;
end;

function TDevirtualizedTree.OverrideMainActionMenuEnabled;
var
  Provider: INodeProvider;
begin
  if Node.TryGetProvider(Provider) and not Provider.EnabledMainActionMenu then
    Result := False
  else
    Result := inherited;
end;

procedure TDevirtualizedTree.ValidateNodeDataSize;
begin
  inherited;
  Size := SizeOf(INodeProvider);
end;

{ Functions }

function CollectNodeProviders;
var
  Node: PVirtualNode;
  Provider: INodeProvider;
  Count: Integer;
begin
  Count := 0;

  for Node in NodeEnumeration do
    if Node.HasProvider(ProviderId) then
      Inc(Count);

  SetLength(Result, Count);
  Count := 0;

  for Node in NodeEnumeration do
    if Node.TryGetProvider(ProviderId, Provider) then
    begin
      Result[Count] := Provider;
      Inc(Count);
    end;
end;

{ TNodeProvider }

procedure TNodeProvider.Attach;
var
  FBaseTree: TBaseVirtualTree;
begin
  FNode := Value;

  if Assigned(Value) then
  begin
    FBaseTree := TreeFromNode(Value);

    if FBaseTree is TDevirtualizedTree then
      FTree :=  TDevirtualizedTree(FBaseTree);
  end
  else
    FTree := nil;
end;

function TNodeProvider.Attached;
begin
  Result := Assigned(FTree) and Assigned(FNode);
end;

constructor TNodeProvider.Create;
begin
  inherited Create;
  SetLength(FColumnText, InitialColumnCount);
  FEnabledMainActionMenu := True;
end;

procedure TNodeProvider.Detach;
begin
  FNode := nil;
  FTree := nil;
end;

function TNodeProvider.GetColor;
begin
  Result := FColor;
end;

function TNodeProvider.GetColumnText;
begin
  if (Column >= Low(FColumnText)) and (Column <= High(FColumnText)) then
    Result := FColumnText[Column]
  else
    Result := '';
end;

function TNodeProvider.GetCursor;
begin
  Result := FCursor;
end;

function TNodeProvider.GetEnabledMainActionMenu;
begin
  Result := FEnabledMainActionMenu;
end;

function TNodeProvider.GetFontColor;
begin
  Result := FFontColor;
end;

function TNodeProvider.GetFontColorForColumn;
begin
  if (Column >= Low(FFontColorForColumn)) and
    (Column <= High(FFontColorForColumn)) then
    Result := FFontColorForColumn[Column]
  else
    Result := clBlack;
end;

function TNodeProvider.GetFontStyle;
begin
  Result := FFontStyle;
end;

function TNodeProvider.GetFontStyleForColumn;
begin
  if (Column >= Low(FFontStyleForColumn)) and
    (Column <= High(FFontStyleForColumn)) then
    Result := FFontStyleForColumn[Column]
  else
    Result := [];
end;

function TNodeProvider.GetHasColor;
begin
  Result := FHasColor;
end;

function TNodeProvider.GetHasCursor;
begin
  Result := FHasCursor;
end;

function TNodeProvider.GetHasFontColor;
begin
  Result := FHasFontColor;
end;

function TNodeProvider.GetHasFontColorForColumn;
begin
  Result := (Column >= Low(FHasFontColorForColumn)) and
    (Column <= High(FHasFontColorForColumn)) and FHasFontColorForColumn[Column];
end;

function TNodeProvider.GetHasFontStyle;
begin
  Result := FHasFontStyle;
end;

function TNodeProvider.GetHasFontStyleForColumn;
begin
  Result := (Column >= Low(FHasFontStyleForColumn)) and
    (Column <= High(FHasFontStyleForColumn)) and FHasFontStyleForColumn[Column];
end;

function TNodeProvider.GetHint;
begin
  Result := FHint;
end;

function TNodeProvider.GetNode;
begin
  Result := FNode;
end;

function TNodeProvider.GetTree;
begin
  Result := FTree;
end;

procedure TNodeProvider.Initialize;
begin
  FInitialized := True;
end;

function TNodeProvider.InitializeChildren;
begin
  Result := False;
end;

procedure TNodeProvider.Invalidate;
begin
  if Attached then
    FTree.InvalidateNode(FNode);
end;

procedure TNodeProvider.NotifyChecked;
begin
end;

procedure TNodeProvider.NotifyCollapsing;
begin
end;

procedure TNodeProvider.NotifyExpanding;
begin
  if not FFirstExpandingCalled then
  begin
    FFirstExpandingCalled := True;
    NotifyFirstExpanding;
    HasChildren := FNode.ChildCount > 0;
  end;
end;

procedure TNodeProvider.NotifyFirstExpanding;
begin
end;

procedure TNodeProvider.NotifySelected;
begin
end;

procedure TNodeProvider.ResetColor;
begin
  if not FHasColor then
    Exit;

  FHasColor := False;
  Invalidate;
end;

procedure TNodeProvider.ResetCursor;
begin
  if not FHasCursor then
    Exit;

  FHasCursor := False;
  Invalidate;
end;

procedure TNodeProvider.ResetFontColor;
begin
  if not FHasFontColor then
    Exit;

  FHasFontColor := False;
  Invalidate;
end;

procedure TNodeProvider.ResetFontColorForColumn;
begin
  if (Column < Low(FHasFontColorForColumn)) or
    not GetHasFontColorForColumn(Column) then
    Exit;

  if Column > High(FHasFontColorForColumn) then
    SetLength(FHasFontColorForColumn, Column + 1);

  FHasFontColorForColumn[Column] := False;
  Invalidate;
end;

procedure TNodeProvider.ResetFontStyle;
begin
  if not FHasFontStyle then
    Exit;

  FHasFontStyle := False;
  Invalidate;
end;

procedure TNodeProvider.ResetFontStyleForColumn;
begin
  if (Column < Low(FHasFontStyleForColumn)) or
    not GetHasFontColorForColumn(Column) then
    Exit;

  if Column > High(FHasFontStyleForColumn) then
    SetLength(FHasFontStyleForColumn, Column + 1);

  FHasFontStyleForColumn[Column] := False;
  Invalidate;
end;

function TNodeProvider.SearchExpression;
var
  i: TVirtualTreeColumn;
begin
  if UpcasedExpression = '' then
    Exit(True);

  // Single-column queries
  if Column >= 0 then
  begin
    Result := RtlxIsNameInExpression(UpcasedExpression, GetColumnText(Column),
      False, False);
    Exit;
  end;

  // Multi-column queries require at least one visible column to match
  if Attached then
    for i in FTree.Header.Columns.GetVisibleColumns do
      if RtlxIsNameInExpression(UpcasedExpression, GetColumnText(i.Index),
        False, False) then
        Exit(True);

  Result := False;
end;

function TNodeProvider.SearchNumber;
begin
  // There is no generic number search but descendants can implement it
  Result := False;
end;

procedure TNodeProvider.SetColor;
begin
  if FHasColor and (FColor = Value) then
    Exit;

  FHasColor := True;
  FColor := Value;
  Invalidate;
end;

procedure TNodeProvider.SetColumnText;
begin
  if (Column < Low(FColumnText)) or (GetColumnText(Column) = Value) then
    Exit;

  if Column > High(FColumnText) then
    SetLength(FColumnText, Column + 1);

  FColumnText[Column] := Value;
  Invalidate;
end;

procedure TNodeProvider.SetCursor;
begin
  if FHasCursor and (FCursor = Value) then
    Exit;

  FHasCursor := True;
  FCursor := Value;
  Invalidate;
end;

procedure TNodeProvider.SetEnabledMainActionMenu;
begin
  FEnabledMainActionMenu := Value;
end;

procedure TNodeProvider.SetFontColor;
begin
  if FHasFontColor and (FFontColor = Value) then
    Exit;

  FHasFontColor := True;
  FFontColor := Value;
  Invalidate;
end;

procedure TNodeProvider.SetFontColorForColumn;
begin
  if Column < Low(FFontColorForColumn) then
    Exit;

  if GetHasFontColorForColumn(Column) and
    (GetFontColorForColumn(Column) = Value) then
    Exit;

  if Column > High(FHasFontColorForColumn) then
    SetLength(FHasFontColorForColumn, Column + 1);

  if Column > High(FFontColorForColumn) then
    SetLength(FFontColorForColumn, Column + 1);

  FHasFontColorForColumn[Column] := True;
  FFontColorForColumn[Column] := Value;
  Invalidate;
end;

procedure TNodeProvider.SetFontStyle;
begin
  if FHasFontStyle and (FFontStyle = Value) then
    Exit;

  FHasFontStyle := True;
  FFontStyle := Value;
  Invalidate;
end;

procedure TNodeProvider.SetFontStyleForColumn;
begin
    if Column < Low(FFontStyleForColumn) then
    Exit;

  if GetHasFontStyleForColumn(Column) and
    (GetFontStyleForColumn(Column) = Value) then
    Exit;

  if Column > High(FHasFontStyleForColumn) then
    SetLength(FHasFontStyleForColumn, Column + 1);

  if Column > High(FFontStyleForColumn) then
    SetLength(FFontStyleForColumn, Column + 1);

  FHasFontStyleForColumn[Column] := True;
  FFontStyleForColumn[Column] := Value;
  Invalidate;
end;

procedure TNodeProvider.SetHint;
begin
  if FHint = Value then
    Exit;

  FHint := Value;
  Invalidate;
end;

{ TEditableNodeProvider }

procedure TEditableNodeProvider.Attach;
begin
  inherited;

  if Assigned(FOnAttach) and Attached then
    FOnAttach(FTree, FNode);
end;

procedure TEditableNodeProvider.Detach;
begin
  if Assigned(FOnDetach) and Attached then
    FOnDetach(FTree, FNode);

  inherited;
end;

function TEditableNodeProvider.GetOnAttach;
begin
  Result := FOnAttach;
end;

function TEditableNodeProvider.GetOnChecked;
begin
  Result := FOnChecked;
end;

function TEditableNodeProvider.GetOnCollapsing;
begin
  Result := FOnCollapsing;
end;

function TEditableNodeProvider.GetOnDetach;
begin
  Result := FOnDetach;
end;

function TEditableNodeProvider.GetOnExpanding;
begin
  Result := FOnExpanding;
end;

function TEditableNodeProvider.GetOnFirstExpanding;
begin
  Result := FOnFitstExpanding;
end;

function TEditableNodeProvider.GetOnInitialize;
begin
  Result := FOnInitialize;
end;

function TEditableNodeProvider.GetOnInitializeChildren;
begin
  Result := FOnInitializeChildren;
end;

function TEditableNodeProvider.GetOnSelected;
begin
  Result := FOnSelected;
end;

procedure TEditableNodeProvider.NotifyChecked;
begin
  inherited;

  if Assigned(FOnChecked) and Attached then
    FOnChecked(FTree, FNode);
end;

procedure TEditableNodeProvider.NotifyCollapsing;
begin
  inherited;

  if Assigned(FOnCollapsing) and Attached then
    FOnCollapsing(FTree, FNode);
end;

procedure TEditableNodeProvider.NotifyExpanding;
begin
  inherited;

  if Assigned(FOnExpanding) and Attached then
    FOnExpanding(FTree, FNode);
end;

procedure TEditableNodeProvider.NotifySelected;
begin
  inherited;

  if not Attached then
    Exit;

  // Check if selection actually changed
  if FPreviouslySelectedValid and
    not (FPreviouslySelected xor (vsSelected in FNode.States)) then
    Exit;

  FPreviouslySelectedValid := Assigned(FOnSelected);
  FPreviouslySelected := vsSelected in FNode.States;

  if Assigned(FOnSelected) then
    FOnSelected(FTree, FNode);
end;

procedure TEditableNodeProvider.SetOnAttach;
begin
  FOnAttach := Value;
end;

procedure TEditableNodeProvider.SetOnChecked;
begin
  FOnChecked := Value;
end;

procedure TEditableNodeProvider.SetOnCollapsing;
begin
  FOnCollapsing := Value;
end;

procedure TEditableNodeProvider.SetOnDetach;
begin
  FOnDetach := Value;
end;

procedure TEditableNodeProvider.SetOnExpanding;
begin
  FOnExpanding := Value;
end;

procedure TEditableNodeProvider.SetOnFirstExpanding;
begin
  FOnFitstExpanding := Value;
end;

procedure TEditableNodeProvider.SetOnInitialize;
begin
  FOnInitialize := Value;
end;

procedure TEditableNodeProvider.SetOnInitializeChildren;
begin
  FOnInitializeChildren := Value;
end;

procedure TEditableNodeProvider.SetOnSelected;
begin
  FOnSelected := Value;
end;

end.
