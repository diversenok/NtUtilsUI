unit NtUtilsUI.Tree;

{
  This module provides a full runtime definition for a custom tree view control.

  NOTE: Keep the published interface in sync with the design-time definition!
}

interface

uses
  System.Types, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.Menus,
  VirtualTrees, VirtualTrees.Header, VirtualTrees.Types, NtUtils,
  DelphiUtils.Arrays;

const
  DEFAULT_EMPTY_MESSAGE = 'No items to display';

type
  TUiLibTree = class;

  INodeProvider = interface
    ['{470E3BBC-4DED-4CCC-B05A-4754DF92506F}']
    procedure Attach(Node: PVirtualNode);
    procedure Detach;
    procedure Initialize;
    function InitializeChildren: Boolean;
    procedure Invalidate;

    function GetTree: TUiLibTree;
    function GetNode: PVirtualNode;
    function GetColumnText(Column: TColumnIndex): String;
    function GetHint: String;
    function GetColor(out Value: TColor): Boolean;
    function GetFontColor(out Value: TColor): Boolean;
    function GetFontColorForColumn(Column: TColumnIndex; out Value: TColor): Boolean;
    function GetFontStyle(out Value: TFontStyles): Boolean;
    function GetFontStyleForColumn(Column: TColumnIndex; out Value: TFontStyles): Boolean;
    function GetCursor(out Value: TCursor): Boolean;
    function GetEnabledMainActionMenu: Boolean;

    property Tree: TUiLibTree read GetTree;
    property Node: PVirtualNode read GetNode;
    property ColumnText[Column: TColumnIndex]: String read GetColumnText;
    property Hint: String read GetHint;
    property EnabledMainActionMenu: Boolean read GetEnabledMainActionMenu;

    procedure NotifyChecked;
    procedure NotifySelected;
    procedure NotifyExpanding(var HasChildren: Boolean);
    procedure NotifyCollapsing(var HasChildren: Boolean);
    function SearchExpression(const UpcasedExpression: String; Column: TColumnIndex): Boolean;
    function SearchNumber(const Value: UInt64; Column: TColumnIndex): Boolean;
    function SameEntity(Node: INodeProvider): Boolean;
  end;

  TNodeProviderEvent = procedure (Node: INodeProvider) of object;

  TVirtualNodeHelper = record helper for TVirtualNode
  strict private
    function GetProvider: INodeProvider;
    function GetProviderOrNil: INodeProvider;
    procedure SetProvider(Value: INodeProvider);
  public
    function HasProvider(const IID: TGuid): Boolean;
    function TryGetProvider(out Provider: INodeProvider): Boolean; overload;
    function TryGetProvider(const IID: TGuid; out Provider): Boolean; overload;
    property Provider: INodeProvider read GetProvider write SetProvider;
    property ProviderOrNil: INodeProvider read GetProviderOrNil;
  end;

  TVTVirtualNodeEnumerationHelper = record helper for TVTVirtualNodeEnumeration
    function Count: Integer;
    function Nodes: TArray<PVirtualNode>;
    function Providers: TArray<INodeProvider>; overload;
    function Providers<I: INodeProvider>(const IID: TGuid): TArray<I>; overload;
  end;

  TUiLibTreeMenuShortCut = record
    Menu: TMenuItem;
    ShiftState: TShiftState;
    Key: Word;
    function Matches(ShiftState: TShiftState; Key: Word): Boolean;
    constructor Create(Item: TMenuItem);
    class function Collect(Item: TMenuItem): TArray<TUiLibTreeMenuShortCut>; static;
  end;

  TUiLibTreeDefaultMenu = class
  strict private
    FTree: TUiLibTree;
    FMenu, FFallbackMenu: TPopupMenu;
    FMenuMainAction: TMenuItem;
    FMenuSeparator: TMenuItem;
    FMenuCopy: TMenuItem;
    FMenuCopyColumn: TMenuItem;
    FShortcuts: TArray<TUiLibTreeMenuShortCut>;
    FPopupColumnIndex: Integer;
    FOnMainAction: TNodeProviderEvent;
    procedure MenuMainActionClick(Sender: TObject);
    procedure MenuCopyClick(Sender: TObject);
    procedure MenuCopyColumnClick(Sender: TObject);
    function GetMainActionText: String;
    procedure SetMainActionText(const Value: String);
  public
    procedure AttachItemsTo(Menu: TPopupMenu);
    procedure InvokeShortcuts(Key: Word; Shift: TShiftState);
    procedure InvokeMainAction;
    procedure RefreshShortcuts;
    procedure NotifyPopup([opt] Node: INodeProvider; Menu: TPopupMenu; Column: TColumnIndex);
    property FallbackMenu: TPopupMenu read FFallbackMenu;
    property OnMainAction: TNodeProviderEvent read FOnMainAction write FOnMainAction;
    property MainActionText: String read GetMainActionText write SetMainActionText;
    constructor Create(Owner: TUiLibTree);
  end;

  TUiLibTreePopupMode = (pmOnItemsOnly, pmAnywhere);

  TUiLibTreeOptions = class (TStringTreeOptions)
  strict private
    FAutoShowRoot: Boolean;
  public
    constructor Create(AOwner: TCustomControl); override;
    procedure AssignTo(Dest: TPersistent); override;
  published
    property AutoShowRoot: Boolean read FAutoShowRoot write FAutoShowRoot default True;
    property AutoOptions default [toAutoDropExpand, toAutoScrollOnExpand, toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale];
    property ExportMode default emSelected;
    property MiscOptions default [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning];
    property PaintOptions default [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toThemeAware, toUseBlendedImages, toUseExplorerTheme];
    property SelectionOptions default [toFullRowSelect, toMultiSelect, toRightClickSelect];
  end;

  TUiLibTreeColumns = class (TVirtualTreeColumns)
  public
    function BeginUpdateAuto: IAutoReleasable;
  end;

  TUiLibTreeHeader = class (TVTHeader)
  private
    function GetColumns: TUiLibTreeColumns;
    procedure SetColumns(const Value: TUiLibTreeColumns);
  protected
    function GetColumnsClass: TVirtualTreeColumnsClass; override;
  public
    constructor Create(AOwner: TCustomControl); override;
  published
    property Columns: TUiLibTreeColumns read GetColumns write SetColumns stored False;
    property DefaultHeight default 24;
    property Height default 24;
    property Options default [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack, hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize, hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption];
  end;

  TUiLibTree = class (TVirtualStringTree)
  private
    FDefaultMenus: TUiLibTreeDefaultMenu;
    FPopupMenu: TPopupMenu;
    FPopupMode: TUiLibTreePopupMode;
    FEmptyListMessage: String;
    FEmptyListMessageLines: TArray<String>;
    procedure SetEmptyListMessage(Value: String);
    function GetHeader: TUiLibTreeHeader;
    procedure SetHeader(Value: TUiLibTreeHeader);
    function GetHighlightedNode: PVirtualNode;
    procedure SetHighlightedNode(Value: PVirtualNode);
    function GetMainActionMenuText: String;
    procedure SetMainActionMenuText(Value: String);
    function GetOnMainAction: TNodeProviderEvent;
    procedure SetOnMainAction(Value: TNodeProviderEvent);
    procedure SetPopupMenu(Value: TPopupMenu);
    function GetTreeOptions: TUiLibTreeOptions;
    procedure SetTreeOptions(Value: TUiLibTreeOptions);
  protected
    procedure DblClick; override;
    procedure DoAfterPaint(Canvas: TCanvas); override;
    procedure DoBeforeItemErase(Canvas: TCanvas; Node: PVirtualNode; ItemRect: TRect; var Color: TColor; var EraseAction: TItemEraseAction); override;
    procedure DoChange(Node: PVirtualNode); override;
    procedure DoChecked(Node: PVirtualNode); override;
    function DoCollapsing(Node: PVirtualNode): Boolean; override;
    function DoCompare(Node1, Node2: PVirtualNode; Column: TColumnIndex): Integer; override;
    function DoExpanding(Node: PVirtualNode): Boolean; override;
    procedure DoFreeNode(Node: PVirtualNode); override;
    procedure DoGetCursor(var Cursor: TCursor); override;
    function DoGetNodeHint(Node: PVirtualNode; Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle): string; override;
    function DoGetPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Position: TPoint): TPopupMenu; override;
    procedure DoGetText(var EventArgs: TVSTGetCellTextEventArgs); override;
    function DoInitChildren(Node: PVirtualNode; var ChildCount: Cardinal): Boolean; override;
    procedure DoInitNode(Parent, Node: PVirtualNode; var InitStates: TVirtualNodeInitStates); override;
    procedure DoPaintText(Node: PVirtualNode; const Canvas: TCanvas; Column: TColumnIndex; TextType: TVSTTextType); override;
    procedure DoRemoveFromSelection(Node: PVirtualNode); override;
    function GetHeaderClass: TVTHeaderClass; override;
    function GetOptionsClass: TTreeOptionsClass; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure ValidateNodeDataSize(var Size: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddChild(NewProvider: INodeProvider; [opt] Parent: INodeProvider = nil; AutoExpandParent: Boolean = True): INodeProvider; reintroduce;
    procedure ApplyFilter(const Query: String; UseColumn: TColumnIndex = -1);
    function BackupSelectionAuto: IDeferredOperation;
    function BeginUpdateAuto: IAutoReleasable;
    function CanMoveSelectedNodesUp: Boolean;
    function CanMoveSelectedNodesDown: Boolean;
    procedure Clear; override;
    procedure DeleteSelectedNodes(SelectSomethingAfter: Boolean = True); reintroduce;
    procedure EnsureNodeSelected; reintroduce;
    function InsertNode(NewProvider: INodeProvider; Mode: TVTNodeAttachMode; Existing: INodeProvider): INodeProvider; reintroduce;
    function MoveSelectedNodesUp: Boolean;
    function MoveSelectedNodesDown: Boolean;
    procedure RefreshPopupMenuShortcuts;
    property HighlightedNode: PVirtualNode read GetHighlightedNode write SetHighlightedNode;
  published
    property ClipboardFormats stored False;
    property DrawSelectionMode default smBlendedRectangle;
    property EmptyListMessage: String read FEmptyListMessage write SetEmptyListMessage;
    property Header: TUiLibTreeHeader read GetHeader write SetHeader;
    property HintMode default hmHint;
    property IncrementalSearch default isAll;
    property MainActionMenuText: String read GetMainActionMenuText write SetMainActionMenuText;
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;
    property PopupMode: TUiLibTreePopupMode read FPopupMode write FPopupMode default pmOnItemsOnly;
    property SelectionBlendFactor default 64;
    property TreeOptions: TUiLibTreeOptions read GetTreeOptions write SetTreeOptions;
    property OnMainAction: TNodeProviderEvent read GetOnMainAction write SetOnMainAction;
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
    FTree: TUiLibTree;
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
    function SearchNumber(const Value: UInt64; Column: TColumnIndex): Boolean; virtual;
    function SameEntity(Node: INodeProvider): Boolean; virtual;

    function GetTree: TUiLibTree; virtual;
    function GetNode: PVirtualNode; virtual;
    function GetColumnText(Column: TColumnIndex): String; virtual;
    function GetHint: String; virtual;
    function GetColor(out Value: TColor): Boolean; virtual;
    function GetFontColor(out Value: TColor): Boolean; virtual;
    function GetFontColorForColumn(Column: TColumnIndex; out Value: TColor): Boolean; virtual;
    function GetFontStyle(out Value: TFontStyles): Boolean; virtual;
    function GetFontStyleForColumn(Column: TColumnIndex; out Value: TFontStyles): Boolean; virtual;
    function GetCursor(out Value: TCursor): Boolean; virtual;
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

  IEditableNodeProvider = interface (INodeProvider)
    ['{D83BEB6B-B8BE-42D8-B0A1-8BDA54E50742}']

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

    function GetOnInitialize: TNodeProviderEvent;
    function GetOnInitializeChildren: TNodeProviderEvent;
    function GetOnAttach: TNodeProviderEvent;
    function GetOnDetach: TNodeProviderEvent;
    function GetOnChecked: TNodeProviderEvent;
    function GetOnSelected: TNodeProviderEvent;
    function GetOnExpanding: TNodeProviderEvent;
    function GetOnFirstExpanding: TNodeProviderEvent;
    function GetOnCollapsing: TNodeProviderEvent;
    procedure SetOnInitialize(Value: TNodeProviderEvent);
    procedure SetOnInitializeChildren(Value: TNodeProviderEvent);
    procedure SetOnAttach(Value: TNodeProviderEvent);
    procedure SetOnDetach(Value: TNodeProviderEvent);
    procedure SetOnChecked(Value: TNodeProviderEvent);
    procedure SetOnSelected(Value: TNodeProviderEvent);
    procedure SetOnExpanding(Value: TNodeProviderEvent);
    procedure SetOnFirstExpanding(Value: TNodeProviderEvent);
    procedure SetOnCollapsing(Value: TNodeProviderEvent);

    property Tree: TUiLibTree read GetTree;
    property Node: PVirtualNode read GetNode;
    property ColumnText[Column: TColumnIndex]: String read GetColumnText write SetColumnText;
    property Hint: String read GetHint write SetHint;
    property EnabledMainActionMenu: Boolean read GetEnabledMainActionMenu write SetEnabledMainActionMenu;
    property OnInitialize: TNodeProviderEvent read GetOnInitialize write SetOnInitialize;
    property OnInitializeChildren: TNodeProviderEvent read GetOnInitializeChildren write SetOnInitializeChildren;
    property OnAttach: TNodeProviderEvent read GetOnAttach write SetOnAttach;
    property OnDetach: TNodeProviderEvent read GetOnDetach write SetOnDetach;
    property OnChecked: TNodeProviderEvent read GetOnChecked write SetOnChecked;
    property OnSelected: TNodeProviderEvent read GetOnSelected write SetOnSelected;
    property OnExpanding: TNodeProviderEvent read GetOnExpanding write SetOnExpanding;
    property OnFirstExpanding: TNodeProviderEvent read GetOnFirstExpanding write SetOnFirstExpanding;
    property OnCollapsing: TNodeProviderEvent read GetOnCollapsing write SetOnCollapsing;
  end;

  TEditableNodeProvider = class (TNodeProvider, IEditableNodeProvider)
  protected
    FOnInitialize: TNodeProviderEvent;
    FOnInitializeChildren: TNodeProviderEvent;
    FOnAttach: TNodeProviderEvent;
    FOnDetach: TNodeProviderEvent;
    FOnChecked: TNodeProviderEvent;
    FOnSelected: TNodeProviderEvent;
    FOnExpanding, FOnFitstExpanding, FOnCollapsing: TNodeProviderEvent;
    FPreviouslySelected, FPreviouslySelectedValid: Boolean;

    function GetOnInitialize: TNodeProviderEvent;
    function GetOnInitializeChildren: TNodeProviderEvent;
    function GetOnAttach: TNodeProviderEvent; virtual;
    function GetOnDetach: TNodeProviderEvent; virtual;
    function GetOnChecked: TNodeProviderEvent; virtual;
    function GetOnSelected: TNodeProviderEvent; virtual;
    function GetOnExpanding: TNodeProviderEvent; virtual;
    function GetOnFirstExpanding: TNodeProviderEvent;
    function GetOnCollapsing: TNodeProviderEvent; virtual;
    procedure SetOnInitialize(Value: TNodeProviderEvent);
    procedure SetOnInitializeChildren(Value: TNodeProviderEvent);
    procedure SetOnAttach(Value: TNodeProviderEvent); virtual;
    procedure SetOnDetach(Value: TNodeProviderEvent); virtual;
    procedure SetOnChecked(Value: TNodeProviderEvent); virtual;
    procedure SetOnSelected(Value: TNodeProviderEvent); virtual;
    procedure SetOnExpanding(Value: TNodeProviderEvent); virtual;
    procedure SetOnFirstExpanding(Value: TNodeProviderEvent);
    procedure SetOnCollapsing(Value: TNodeProviderEvent); virtual;

    procedure Attach(Value: PVirtualNode); override;
    procedure Detach; override;
    procedure NotifyChecked; override;
    procedure NotifySelected; override;
    procedure NotifyExpanding(var HasChildren: Boolean); override;
    procedure NotifyCollapsing(var HasChildren: Boolean); override;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShLwApi, System.SysUtils, Vcl.Clipbrd, Vcl.Themes,
  NtUtils.SysUtils, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Helper functions }

function NodeOrNil(const Provider: INodeProvider): PVirtualNode;
begin
  if Assigned(Provider) then
    Result := Provider.Node
  else
    Result := nil;
end;

{ TVirtualNodeHelper }

function TVirtualNodeHelper.GetProvider;
begin
  Assert(Assigned(@Self), 'Querying node provider of nil');
  Result := GetProviderOrNil;

  if not Assigned(Result) then
    EAssertionFailed.Create('Invalid node provider');
end;

function TVirtualNodeHelper.GetProviderOrNil;
begin
  if Assigned(@Self) then
  begin
    Assert(Assigned(Pointer(GetData^)), 'Querying provider of a legacy node');
    Result := INodeProvider(GetData^);
  end
  else
    Result := nil;
end;

function TVirtualNodeHelper.HasProvider;
var
  Dummy: IInterface;
begin
  Result := TryGetProvider(IID, Dummy);
end;

procedure TVirtualNodeHelper.SetProvider;
begin
  Assert(Assigned(@Self), 'Setting node provider of nil');
  Assert(Assigned(Value), 'Setting node provider to nil');

  // Swap providers
  GetProvider._Release;
  SetData(IInterface(Value));

  // Notify the change
  Value.Attach(@Self);
  Value.Invalidate;
end;

function TVirtualNodeHelper.TryGetProvider(
  out Provider: INodeProvider
): Boolean;
begin
  Provider := GetProviderOrNil;
  Result := Assigned(Provider);
end;

function TVirtualNodeHelper.TryGetProvider(
  const IID: TGuid;
  out Provider
): Boolean;
begin
  Result := Assigned(@Self) and
    Succeeded(GetProvider.QueryInterface(IID, Provider));
end;

{ TVTVirtualNodeEnumerationHelper }

function TVTVirtualNodeEnumerationHelper.Count;
var
  Node: PVirtualNode;
begin
  Result := 0;

  for Node in Self do
    Inc(Result);
end;

function TVTVirtualNodeEnumerationHelper.Nodes;
var
  Node: PVirtualNode;
  i: Integer;
begin
  SetLength(Result, Count);

  i := 0;
  for Node in Self do
  begin
    Result[i] := Node;
    Inc(i);
  end;
end;

function TVTVirtualNodeEnumerationHelper.Providers: TArray<INodeProvider>;
var
  Node: PVirtualNode;
  i: Integer;
begin
  SetLength(Result, Count);

  i := 0;
  for Node in Self do
  begin
    Result[i] := Node.Provider;
    Inc(i);
  end;
end;

function TVTVirtualNodeEnumerationHelper.Providers<I>(
  const IID: TGuid
): TArray<I>;
var
  Node: PVirtualNode;
  Provider: I;
  j: Integer;
begin
  j := 0;
  for Node in Self do
    if Node.TryGetProvider(IID, Provider) then
      Inc(j);

  SetLength(Result, j);

  j := 0;
  for Node in Self do
    if Node.TryGetProvider(IID, Provider) then
    begin
      Result[j] := Provider;
      Inc(j);
    end;
end;

{ TUiLibTreeMenuShortCut }

class function TUiLibTreeMenuShortCut.Collect;
begin
  Result := nil;

  // Save the shortcut from the current item
  if Item.ShortCut <> 0 then
    Result := [TUiLibTreeMenuShortCut.Create(Item)];

  // Process netsed items recursively
  for Item in Item do
    Result := Result + TUiLibTreeMenuShortCut.Collect(Item);
end;

constructor TUiLibTreeMenuShortCut.Create;
begin
  Menu := Item;
  Key := Item.ShortCut and $FFF;
  ShiftState := [];

  if BitTest(Item.ShortCut and scCommand) then
    Include(ShiftState, ssCommand);

  if BitTest(Item.ShortCut and scCtrl) then
    Include(ShiftState, ssCtrl);

  if BitTest(Item.ShortCut and scShift) then
    Include(ShiftState, ssShift);

  if BitTest(Item.ShortCut and scAlt) then
    Include(ShiftState, ssAlt);
end;

function TUiLibTreeMenuShortCut.Matches;
begin
  Result := (Self.ShiftState = ShiftState) and (Self.Key = Key);
end;

{ TUiLibTreeDefaultMenu }

procedure TUiLibTreeDefaultMenu.AttachItemsTo;
begin
  // Note: nil means no menu, so we use our fallback
  if not Assigned(Menu) then
    Menu := FFallbackMenu;

  FMenu := Menu;

  // Attach the item for the main action to the top
  if Assigned(FMenuMainAction.Parent) then
    FMenuMainAction.Parent.Remove(FMenuMainAction);

  Menu.Items.Insert(0, FMenuMainAction);

  // Attach items for copying text to the bottom of the popup menu
  FMenuSeparator.SetParentComponent(Menu);
  FMenuCopy.SetParentComponent(Menu);
  FMenuCopyColumn.SetParentComponent(Menu);

  RefreshShortcuts;
end;

constructor TUiLibTreeDefaultMenu.Create;
begin
  FTree := Owner;
  FFallbackMenu := TPopupMenu.Create(FTree);

  FMenuMainAction := TMenuItem.Create(FTree);
  FMenuMainAction.Caption := 'Inspect...';
  FMenuMainAction.Default := True;
  FMenuMainAction.ShortCut := VK_RETURN;
  FMenuMainAction.Visible := False;
  FMenuMainAction.OnClick := MenuMainActionClick;

  FMenuSeparator := TMenuItem.Create(FTree);
  FMenuSeparator.Caption := '-';
  FMenuSeparator.Visible := False;

  FMenuCopy := TMenuItem.Create(FTree);
  FMenuCopy.Caption := 'Copy';
  FMenuCopy.ShortCut := scCtrl or Ord('C');
  FMenuCopy.OnClick := MenuCopyClick;

  FMenuCopyColumn := TMenuItem.Create(FTree);
  FMenuCopyColumn.Caption := 'Copy Column';
  FMenuCopyColumn.OnClick := MenuCopyColumnClick;

  AttachItemsTo(FFallbackMenu);
end;

function TUiLibTreeDefaultMenu.GetMainActionText;
begin
  Result := FMenuMainAction.Caption;
end;

procedure TUiLibTreeDefaultMenu.InvokeMainAction;
begin
  MenuMainActionClick(FTree);
end;

procedure TUiLibTreeDefaultMenu.InvokeShortcuts;
var
  Shortcut: TUiLibTreeMenuShortCut;
begin
  inherited;

  // Ignore item-specific shortcuts when there are no items selected
  if (FTree.PopupMode = pmOnItemsOnly) and (FTree.SelectedCount <= 0) then
    Exit;

  // Invoke events on all menu items with matching shortcuts
  for Shortcut in FShortcuts do
    if Shortcut.Matches(Shift, Key) and Assigned(Shortcut.Menu.OnClick) then
      Shortcut.Menu.OnClick(FTree);
end;

procedure TUiLibTreeDefaultMenu.MenuCopyClick;
begin
  FTree.CopyToClipboard;
end;

procedure TUiLibTreeDefaultMenu.MenuCopyColumnClick;
var
  Nodes: TArray<PVirtualNode>;
  Texts: TArray<String>;
  i: Integer;
begin
  if not FTree.Header.Columns.IsValidColumn(FPopupColumnIndex) then
    Exit;

  Nodes := FTree.SelectedNodes.Nodes;
  SetLength(Texts, Length(Nodes));

  for i := 0 to High(Nodes) do
    Texts[i] := FTree.Text[Nodes[i], FPopupColumnIndex];

  Clipboard.SetTextBuf(PWideChar(String.Join(#$D#$A, Texts)));
end;

procedure TUiLibTreeDefaultMenu.MenuMainActionClick;
begin
  if Assigned(FOnMainAction) and Assigned(FTree.HighlightedNode) then
    FOnMainAction(FTree.HighlightedNode.Provider);
end;

procedure TUiLibTreeDefaultMenu.NotifyPopup;
begin
  // Enable the main action only on a single node (that allows it)
  FMenuMainAction.Visible := Assigned(FOnMainAction) and Assigned(Node) and
    (FTree.SelectedCount = 1) and FTree.Selected[Node.Node] and
    Node.EnabledMainActionMenu;

  // Enable regular copying when there are nodes to copy
  FMenuCopy.Visible := FTree.SelectedCount > 0;

  // Enable column-specific copying if there is a column
  FPopupColumnIndex := Column;
  FMenuCopyColumn.Visible := (FTree.SelectedCount > 0) and (Column >= 0);

  if FMenuCopyColumn.Visible then
    FMenuCopyColumn.Caption := 'Copy "' + FTree.Header.Columns[Column].Text + '"';

  // Enable the separator if there are items to separate
  FMenuSeparator.Visible := (Assigned(Menu) or FMenuMainAction.Visible) and
    FMenuCopy.Visible;
end;

procedure TUiLibTreeDefaultMenu.RefreshShortcuts;
begin
  if Assigned(FMenu) then
    FShortcuts := TUiLibTreeMenuShortCut.Collect(FMenu.Items)
  else
    FShortcuts := nil;
end;

procedure TUiLibTreeDefaultMenu.SetMainActionText;
begin
  FMenuMainAction.Caption := Value;
end;

{ TUiLibTreeOptions }

procedure TUiLibTreeOptions.AssignTo;
begin
  if Dest is TUiLibTreeOptions then
    TUiLibTreeOptions(Dest).FAutoShowRoot := FAutoShowRoot;

  inherited;
end;

constructor TUiLibTreeOptions.Create;
begin
  inherited Create(AOwner);

  // Adjust existing defaults
  AutoOptions := [toAutoDropExpand, toAutoScrollOnExpand,
    toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale];
  ExportMode := emSelected;
  MiscOptions := [toAcceptOLEDrop, toFullRepaintOnResize,
    toInitOnSave, toToggleOnDblClick, toWheelPanning];
  PaintOptions := [toHideFocusRect, toHotTrack, toShowButtons,
    toShowDropmark, toThemeAware, toUseBlendedImages, toUseExplorerTheme];
  SelectionOptions := [toFullRowSelect, toMultiSelect,
    toRightClickSelect];

  // Choose new option defaults
  FAutoShowRoot := True;
end;

{ TUiLibTreeColumns }

function TUiLibTreeColumns.BeginUpdateAuto;
var
  WeakRef: IWeak;
begin
  // Use a weak reference to verify that the defer didn't outlive the tree
  WeakRef := Auto.RefWeak(TreeView);
  BeginUpdate;

  Result := Auto.Defer(
    procedure
    begin
      if WeakRef.HasRef then
        EndUpdate;
    end
  );
end;

{ TUiLibTreeHeader }

constructor TUiLibTreeHeader.Create;
begin
  inherited;

  // Adjust defaults
  DefaultHeight := 24;
  Height := 24;
  Options := [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack,
    hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize,
    hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption];
end;

function TUiLibTreeHeader.GetColumns;
begin
  Result := TUiLibTreeColumns(inherited Columns);
end;

function TUiLibTreeHeader.GetColumnsClass;
begin
  Result := TUiLibTreeColumns;
end;

procedure TUiLibTreeHeader.SetColumns;
begin
  inherited Columns := Value;
end;

{ TUiLibTree }

function TUiLibTree.AddChild;
var
  NewNode: PVirtualNode;
begin
  NewNode := inherited AddChild(NodeOrNil(Parent), IInterface(NewProvider));
  NewProvider.Attach(NewNode);
  Result := NewProvider;

  if AutoExpandParent and Assigned(Parent) then
    Expanded[Parent.Node] := True;

  if TreeOptions.AutoShowRoot and Assigned(Parent) then
    TreeOptions.PaintOptions := TreeOptions.PaintOptions + [toShowRoot];
end;

procedure TUiLibTree.ApplyFilter;
var
  Node, Parent: INodeProvider;
  SearchColumns: TColumnsArray;
  Column: TVirtualTreeColumn;
  Matches, IsNumberSearch: Boolean;
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
  for Node in Nodes.Providers do
    IsVisible[Node.Node] := Node.SearchExpression('', -1);

  if Query = '' then
    Exit;

  // Check if the query parses into a number
  IsNumberSearch := RtlxStrToUInt64(Query, NumberQuery, nsDecimal,
    [nsHexadecimal], True, [npSpace, npAccent, npApostrophe, npUnderscore]);

  // Prepare an upcased expression for text search
  Expression := '*' + RtlxUpperString(Query) + '*';

  // Collect nodes that are visible without the search and test each one
  // against the query
  for Node in VisibleNodes.Providers do
  begin
    Matches := False;

    // The node can match a non-column-specific number search
    if IsNumberSearch and (UseColumn < 0) then
      Matches := Node.SearchNumber(NumberQuery, -1);

    // Or at least one coulmn should match text or number
    if not Matches then
      for Column in SearchColumns do
      begin
        Matches := (IsNumberSearch and
          Node.SearchNumber(NumberQuery, Column.Index)) or
          Node.SearchExpression(Expression, Column.Index);

        if Matches then
          Break;
      end;

    if Matches then
    begin
      // Make the node and all of its parents visible
      Parent := Node;
      repeat
        IsVisible[Node.Node] := True;
        Parent := NodeParent[Node.Node].ProviderOrNil;
      until not Assigned(Parent);
    end
    else
      IsVisible[Node.Node] := False;
  end;

  // Fix invisible nodes remaining selected
  for Node in SelectedNodes.Providers do
    if not IsVisible[Node.Node] then
      Selected[Node.Node] := False;
end;

function TUiLibTree.BackupSelectionAuto;
var
  WeakRef: IWeak;
  PreviouslySelected: TArray<INodeProvider>;
  PreviouslyFocused: INodeProvider;
begin
  // Capture selection and focus information
  PreviouslySelected := SelectedNodes.Providers;
  PreviouslyFocused := FocusedNode.ProviderOrNil;

  // Use a weak reference to verify that the defer didn't outlive the tree
  WeakRef := Auto.RefWeak(Self);

  // Make a defer to restore selection later
  Result := Auto.Defer(
    procedure
    var
      Node: INodeProvider;
      i: Integer;
    begin
      // Check if the tree is still alive
      if not WeakRef.HasRef then
        Exit;

      BeginUpdateAuto;

      // Check new nodes for matching any previously selected nodes
      for Node in Nodes.Providers do
      begin
        for i := 0 to High(PreviouslySelected) do
          if Node.SameEntity(PreviouslySelected[i]) then
          begin
            Selected[Node.Node] := True;
            Break;
          end;

        // Same for the focus
        if Assigned(PreviouslyFocused) and
          Node.SameEntity(PreviouslyFocused) then
        begin
          FocusedNode := Node.Node;
          ScrollIntoView(Node.Node, False);
        end;
      end;

      // Re-apply sorting
      Sort(nil, Header.SortColumn, Header.SortDirection);
    end
  );
end;

function TUiLibTree.BeginUpdateAuto;
var
  WeakRef: IWeak;
begin
  // Use a weak reference to verify that the defer didn't outlive the tree
  WeakRef := Auto.RefWeak(Self);
  BeginUpdate;

  Result := Auto.Defer(
    procedure
    begin
      if WeakRef.HasRef then
        EndUpdate;
    end
  );
end;

function TUiLibTree.CanMoveSelectedNodesDown;
var
  Nodes: TArray<PVirtualNode>;
  Next: PVirtualNode;
  i: Integer;
begin
  Result := False;
  Nodes := SelectedNodes.Nodes;

  for i := High(Nodes) downto 0 do
  begin
    Next := GetNext(Nodes[i]);

    // Check if we can move each node after its next without passing previously
    // moved
    if Assigned(Next) and ((i = High(Nodes)) or (Next <> Nodes[i + 1])) then
      Exit(True);
  end;
end;

function TUiLibTree.CanMoveSelectedNodesUp;
var
  Nodes: TArray<PVirtualNode>;
  Previous: PVirtualNode;
  i: Integer;
begin
  Result := False;
  Nodes := SelectedNodes.Nodes;

  for i := 0 to High(Nodes) do
  begin
    Previous := GetPrevious(Nodes[i]);

    // Check if we can move each node before its previous without passing
    // previously moved
    if Assigned(Previous) and ((i = 0) or (Previous <> Nodes[i - 1])) then
      Exit(True);
  end;
end;

procedure TUiLibTree.Clear;
begin
  inherited;

  if TreeOptions.AutoShowRoot then
    TreeOptions.PaintOptions := TreeOptions.PaintOptions - [toShowRoot];
end;

constructor TUiLibTree.Create;
begin
  inherited;

  // Always include a menu for copying and inspecting items
  FDefaultMenus := TUiLibTreeDefaultMenu.Create(Self);

  // Adjust defaults
  DrawSelectionMode := smBlendedRectangle;
  HintMode := hmHint;
  IncrementalSearch := isAll;
  SelectionBlendFactor := 64;
  ClipboardFormats.Add('CSV');
  ClipboardFormats.Add('Plain text');
  ClipboardFormats.Add('Unicode text');

  // Select defaults for new properties
  FEmptyListMessage := DEFAULT_EMPTY_MESSAGE;
  FEmptyListMessageLines := [FEmptyListMessage];
end;

procedure TUiLibTree.DblClick;
begin
  inherited;

  // Enter, Double Click, and Inspect should all invoke the main action
  FDefaultMenus.InvokeMainAction;
end;

procedure TUiLibTree.DeleteSelectedNodes;
var
  SelectionLookupStart: PVirtualNode;
  SelectionCandidate: PVirtualNode;
begin
  if SelectedCount <= 0 then
    Exit;

  BeginUpdateAuto;
  SelectionCandidate := nil;

  if SelectSomethingAfter then
  begin
    // We want the future selection to be in the same area of the tree
    if Assigned(FocusedNode) then
      SelectionLookupStart := FocusedNode
    else
      SelectionLookupStart := GetFirstSelected;

    // Choose an item below for future selection
    SelectionCandidate := SelectionLookupStart;
    while Assigned(SelectionCandidate) and Selected[SelectionCandidate] do
      SelectionCandidate := GetNextVisible(SelectionCandidate);

    // No items below are suitable; try items above
    if not Assigned(SelectionCandidate) then
    begin
      SelectionCandidate := SelectionLookupStart;
      while Assigned(SelectionCandidate) and Selected[SelectionCandidate] do
         SelectionCandidate := GetPreviousVisible(SelectionCandidate);
    end;
  end;

  // Perform deletion
  inherited DeleteSelectedNodes;
  ClearSelection;

  // Select and focus the candidate
  if Assigned(SelectionCandidate) then
  begin
    Selected[SelectionCandidate] := True;
    FocusedNode := SelectionCandidate;
  end;
end;

destructor TUiLibTree.Destroy;
begin
  FDefaultMenus.Free;
  inherited;
end;

procedure TUiLibTree.DoAfterPaint;
var
  Sizes: TArray<TSize>;
  TotalHeight, Offset: Integer;
  i: Integer;
begin
  // Draw the no-items text
  if (VisibleCount = 0) and (Length(FEmptyListMessageLines) > 0) then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := StyleServices.GetStyleFontColor(sfListItemTextDisabled);

    // Compute the sizes of each line
    SetLength(Sizes, Length(FEmptyListMessageLines));
    TotalHeight := 0;

    for i := 0 to High(FEmptyListMessageLines) do
    begin
      Sizes[i] := Canvas.TextExtent(FEmptyListMessageLines[i]);
      Inc(TotalHeight, Sizes[i].Height);
    end;

    Offset := 0;

    // Draw the static text in the middle of an empty tree
    for i := 0 to High(FEmptyListMessageLines) do
    begin
      Canvas.TextOut(
        (ClientWidth - Sizes[i].Width) div 2,
        (ClientHeight - Sizes[i].Height - TotalHeight) div 2 + Offset,
        FEmptyListMessageLines[i]);
      Inc(Offset, Sizes[i].Height);
    end;
  end;

  inherited DoAfterPaint(Canvas);
end;

procedure TUiLibTree.DoBeforeItemErase;
var
  Value: TColor;
begin
  if Node.Provider.GetColor(Value) then
    Color := Value
  else
    inherited;
end;

procedure TUiLibTree.DoChange;
var
  Provider: INodeProvider;
begin
  inherited;

  if Assigned(Node) then
    Node.Provider.NotifySelected
  else
    // Notify all when the node is not known
    for Provider in Nodes.Providers do
      Provider.NotifySelected;
end;

procedure TUiLibTree.DoChecked;
begin
  inherited;
  Node.Provider.NotifyChecked;
end;

function TUiLibTree.DoCollapsing;
begin
  Result := inherited;
  Node.Provider.NotifyCollapsing(Result);
end;

function TUiLibTree.DoCompare;
begin
  if Assigned(OnCompareNodes) then
    OnCompareNodes(Self, Node1, Node2, Column, Result)
  else
    // Fall back to logical text comparison
    Result := StrCmpLogicalW(PWideChar(Text[Node1, Column]),
      PWideChar(Text[Node2, Column]));
end;

function TUiLibTree.DoExpanding;
begin
  Result := inherited;
  Node.Provider.NotifyExpanding(Result);
end;

procedure TUiLibTree.DoFreeNode;
begin
  Node.Provider.Detach;
  inherited;
end;

procedure TUiLibTree.DoGetCursor;
var
  Node: PVirtualNode;
  Value: TCursor;
begin
  Node := GetNodeAt(ScreenToClient(Mouse.CursorPos));

  if Assigned(Node) and Node.Provider.GetCursor(Value) then
    Cursor := Value
  else
    inherited;
end;

function TUiLibTree.DoGetNodeHint;
begin
  LineBreakStyle := hlbDefault;
  Result := Node.Provider.Hint
end;

function TUiLibTree.DoGetPopupMenu;
begin
  Result := inherited DoGetPopupMenu(Node, Column, Position);

  if Header.InHeader(Position) then
    Exit;

  if (FPopupMode = pmOnItemsOnly) and (SelectedCount = 0) then
    Exit;

  // Choose a context menu
  if not Assigned(Result) then
    if Assigned(FPopupMenu) then
      Result := FPopupMenu
    else
      Result := FDefaultMenus.FallbackMenu;

  // Update visibility of the built-in items
  FDefaultMenus.NotifyPopup(Node.ProviderOrNil, Result, Column);
end;

procedure TUiLibTree.DoGetText;
begin
  // Init if necessary
  if not (vsInitialized in EventArgs.Node.States) then
    InitNode(EventArgs.Node);

  EventArgs.CellText := EventArgs.Node.Provider.ColumnText[EventArgs.Column];
end;

function TUiLibTree.DoInitChildren;
begin
  Result := Node.Provider.InitializeChildren
end;

procedure TUiLibTree.DoInitNode;
begin
  inherited;
  Node.Provider.Initialize;
end;

procedure TUiLibTree.DoPaintText;
var
  Provider: INodeProvider;
  ColorValue: TColor;
  FontStyleValue: TFontStyles;
begin
  // Preload the font color and style
  if TextType = ttNormal then
  begin
    Provider := Node.Provider;

    if Provider.GetFontColorForColumn(Column, ColorValue) or
      Provider.GetFontColor(ColorValue) then
      Canvas.Font.Color := ColorValue;

    if Provider.GetFontStyleForColumn(Column, FontStyleValue) or
      Provider.GetFontStyle(FontStyleValue)  then
      Canvas.Font.Style := FontStyleValue;
  end;

  inherited;
end;

procedure TUiLibTree.DoRemoveFromSelection;
begin
  // Fix errors caused by invoking the OnRemoveFromSelection event on a
  // half-destroyed form
  if not (csDestroying in ComponentState) then
    inherited;
end;

procedure TUiLibTree.EnsureNodeSelected;
begin
  if toAlwaysSelectNode in TreeOptions.SelectionOptions then
    inherited EnsureNodeSelected

  // Note: this is not an override method; change purely for local callers
  else if SelectedCount < 1 then
    HighlightedNode := GetFirstVisible;
end;

function TUiLibTree.GetHeader;
begin
  Result := TUiLibTreeHeader(inherited Header);
end;

function TUiLibTree.GetHeaderClass;
begin
  Result := TUiLibTreeHeader;
end;

function TUiLibTree.GetHighlightedNode;
begin
  if SelectedCount = 1 then
    Result := GetFirstSelected
  else
    Result := nil;
end;

function TUiLibTree.GetMainActionMenuText;
begin
  Result := FDefaultMenus.MainActionText;
end;

function TUiLibTree.GetOnMainAction;
begin
  Result := FDefaultMenus.OnMainAction;
end;

function TUiLibTree.GetOptionsClass;
begin
  Result := TUiLibTreeOptions;
end;

function TUiLibTree.GetTreeOptions;
begin
  Result := TUiLibTreeOptions(inherited TreeOptions);
end;

function TUiLibTree.InsertNode;
var
  NewNode: PVirtualNode;
begin
  // Note: InsertNode doesn't have an overload that takes an interface as a
  // parameter like AddNode does. Reproduce AddNode's behavior by adding the
  // provider as a pointer and then adjusting its lifetime.
  NewNode := inherited InsertNode(NodeOrNil(Existing), Mode, Pointer(NewProvider));
  NewProvider._AddRef;
  Include(NewNode.States, vsReleaseCallOnUserDataRequired);

  // Notify the provider of completion
  NewProvider.Attach(NewNode);
  Result := NewProvider;
end;

procedure TUiLibTree.KeyDown;
begin
  inherited;

  // Process shortcuts on all menu items
  FDefaultMenus.InvokeShortcuts(Key, Shift);
end;

function TUiLibTree.MoveSelectedNodesDown;
var
  Nodes: TArray<PVirtualNode>;
  Next: PVirtualNode;
  i: Integer;
begin
  BeginUpdateAuto;
  Result := False;
  Nodes := SelectedNodes.Nodes;

  for i := High(Nodes) downto 0 do
  begin
    Next := GetNext(Nodes[i]);

    // Move each node after its next without passing previously moved
    if Assigned(Next) and ((i = High(Nodes)) or (Next <> Nodes[i + 1])) then
    begin
      MoveTo(Nodes[i], Next, amInsertAfter, False);
      Result := True;
    end;
  end;
end;

function TUiLibTree.MoveSelectedNodesUp;
var
  Nodes: TArray<PVirtualNode>;
  Previous: PVirtualNode;
  i: Integer;
begin
  BeginUpdateAuto;
  Result := False;
  Nodes := SelectedNodes.Nodes;

  for i := 0 to High(Nodes) do
  begin
    Previous := GetPrevious(Nodes[i]);

    // Move each node before its previous without passing previously moved
    if Assigned(Previous) and ((i = 0) or (Previous <> Nodes[i - 1])) then
    begin
      MoveTo(Nodes[i], Previous, amInsertBefore, False);
      Result := True;
    end;
  end;
end;

procedure TUiLibTree.RefreshPopupMenuShortcuts;
begin
  FDefaultMenus.RefreshShortcuts;
end;

procedure TUiLibTree.SetEmptyListMessage;
begin
  if FEmptyListMessage <> Value then
  begin
    FEmptyListMessage := Value;
    FEmptyListMessageLines := Value.Split([#$D#$A]);
    Invalidate;
  end;
end;

procedure TUiLibTree.SetHeader;
begin
  inherited Header := Value;
end;

procedure TUiLibTree.SetHighlightedNode;
begin
  BeginUpdateAuto;
  ClearSelection;
  Selected[Value] := True;
  FocusedNode := Value;
end;

procedure TUiLibTree.SetMainActionMenuText;
begin
  FDefaultMenus.MainActionText := Value;
end;

procedure TUiLibTree.SetOnMainAction;
begin
  FDefaultMenus.OnMainAction := Value;
end;

procedure TUiLibTree.SetPopupMenu;
begin
  if FPopupMenu <> Value then
  begin
    FPopupMenu := Value;

    // Note: attaching to nil moves items back to the fallback menu
    if not (csDesigning in ComponentState) then
      FDefaultMenus.AttachItemsTo(FPopupMenu);
  end;
end;

procedure TUiLibTree.SetTreeOptions;
begin
  inherited TreeOptions := Value;
end;

procedure TUiLibTree.ValidateNodeDataSize;
begin
  inherited;
  Size := SizeOf(INodeProvider);
end;

{ TNodeProvider }

procedure TNodeProvider.Attach;
var
  FBaseTree: TBaseVirtualTree;
begin
  FNode := Value;
  FTree := nil;

  if Assigned(Value) then
  begin
    FBaseTree := TreeFromNode(Value);

    if FBaseTree is TUiLibTree then
      FTree := TUiLibTree(FBaseTree);
  end;
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
  Result := FHasColor;

  if Result then
    Value := FColor;
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
  Result := FHasCursor;

  if Result then
    Value := FCursor;
end;

function TNodeProvider.GetEnabledMainActionMenu;
begin
  Result := FEnabledMainActionMenu;
end;

function TNodeProvider.GetFontColor;
begin
  Result := FHasFontColor;

  if Result then
    Value := FFontColor;
end;

function TNodeProvider.GetFontColorForColumn;
begin
  Result := (Column >= Low(FFontColorForColumn)) and
    (Column <= High(FFontColorForColumn)) and
    FHasFontColorForColumn[Column];

  if Result then
    Value := FFontColorForColumn[Column];
end;

function TNodeProvider.GetFontStyle;
begin
  Result := FHasFontStyle;

  if Result then
    Value := FFontStyle;
end;

function TNodeProvider.GetFontStyleForColumn;
begin
  Result := (Column >= Low(FFontStyleForColumn)) and
    (Column <= High(FFontStyleForColumn)) and
    FHasFontStyleForColumn[Column];

  if Result then
    Value := FFontStyleForColumn[Column];
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
  if FHasColor then
  begin
    FHasColor := False;
    Invalidate;
  end;
end;

procedure TNodeProvider.ResetCursor;
begin
  if FHasCursor then
  begin
    FHasCursor := False;
    Invalidate;
  end;
end;

procedure TNodeProvider.ResetFontColor;
begin
  if FHasFontColor then
  begin
    FHasFontColor := False;
    Invalidate;
  end;
end;

procedure TNodeProvider.ResetFontColorForColumn;
begin
  if (Column >= Low(FHasFontColorForColumn)) and
    (Column <= High(FHasFontColorForColumn)) and
    FHasFontColorForColumn[Column] then
  begin
    FHasFontColorForColumn[Column] := False;
    Invalidate;
  end;
end;

procedure TNodeProvider.ResetFontStyle;
begin
  if FHasFontStyle then
  begin
    FHasFontStyle := False;
    Invalidate;
  end;
end;

procedure TNodeProvider.ResetFontStyleForColumn;
begin
  if (Column >= Low(FHasFontStyleForColumn)) and
    (Column <= High(FHasFontStyleForColumn)) and
    FHasFontStyleForColumn[Column] then
  begin
    FHasFontStyleForColumn[Column] := False;
    Invalidate;
  end;
end;

function TNodeProvider.SameEntity;
var
  AnotherNodeObject: TObject;
begin
  // This method indicates that this and the other node represent the same
  // underlying resource and that the tree should preserve node selection and
  // similar visual properties when replacing one node with another. To be
  // overriden by descendants.

  Result := (Node.QueryInterface(ObjCastGUID,
    AnotherNodeObject) = S_OK) and (AnotherNodeObject = Self);
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
var
  OldValue: TColor;
begin
  if Column < Low(FFontColorForColumn) then
    Exit;

  if GetFontColorForColumn(Column, OldValue) and (OldValue = Value) then
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
var
  OldValue: TFontStyles;
begin
  if Column < Low(FFontStyleForColumn) then
    Exit;

  if GetFontStyleForColumn(Column, OldValue) and (OldValue = Value) then
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
    FOnAttach(Self);
end;

procedure TEditableNodeProvider.Detach;
begin
  if Assigned(FOnDetach) and Attached then
    FOnDetach(Self);

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
    FOnChecked(Self);
end;

procedure TEditableNodeProvider.NotifyCollapsing;
begin
  inherited;

  if Assigned(FOnCollapsing) and Attached then
    FOnCollapsing(Self);
end;

procedure TEditableNodeProvider.NotifyExpanding;
begin
  inherited;

  if Assigned(FOnExpanding) and Attached then
    FOnExpanding(Self);
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
    FOnSelected(Self);
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
