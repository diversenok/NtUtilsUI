unit NtUtilsUI.DevirtualizedTree;

{
  This module provides a full runtime definition for a devirtualized tree view
  based on the virtual tree view where each node has a dedicated provider that
  customizes its appearance.

  NOTE: Keep the published interface in sync with the design-time definition!
}

interface

uses
  System.Types, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.Menus,
  VirtualTrees, VirtualTrees.Header, VirtualTrees.Types, NtUtils,
  DelphiUtils.Arrays;

type
  TDevirtualizedTree = class;

  INodeProvider = interface
    ['{B123A5F1-26FD-4AB3-8D0F-FC3AD07ABAD0}']
    procedure Attach(Node: PVirtualNode);
    procedure Detach;
    procedure Initialize;
    function InitializeChildren: Boolean;
    procedure Invalidate;

    function GetTree: TDevirtualizedTree;
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

    property Tree: TDevirtualizedTree read GetTree;
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

  TNodeProviderEvent = procedure (Node: INodeProvider) of object;

  TVirtualNodeHelper = record helper for TVirtualNode
  strict private
    procedure SetProvider(const Value: INodeProvider);
    function GetProvider: INodeProvider;
  public
    function HasProvider: Boolean; overload;
    function HasProvider(const IID: TGuid): Boolean; overload;
    function TryGetProvider(out Provider: INodeProvider): Boolean; overload;
    function TryGetProvider(const IID: TGuid; out Provider): Boolean; overload;
    property Provider: INodeProvider read GetProvider write SetProvider;
  end;

  TVTVirtualNodeEnumerationHelper = record helper for TVTVirtualNodeEnumeration
    function CountNodes: Integer;
    function Nodes: TArray<PVirtualNode>;
    function CountProviders: Integer;
    function Providers: TArray<INodeProvider>;
  end;

  TDevirtualizedTreeMenuShortCut = record
    Menu: TMenuItem;
    ShiftState: TShiftState;
    Key: Word;
    function Matches(ShiftState: TShiftState; Key: Word): Boolean;
    constructor Create(Item: TMenuItem);
    class function Collect(Item: TMenuItem): TArray<TDevirtualizedTreeMenuShortCut>; static;
  end;

  TDevirtualizedTreeDefaultMenu = class
  strict private
    FTree: TDevirtualizedTree;
    FMenu, FFallbackMenu: TPopupMenu;
    FMenuMainAction: TMenuItem;
    FMenuSeparator: TMenuItem;
    FMenuCopy: TMenuItem;
    FMenuCopyColumn: TMenuItem;
    FShortcuts: TArray<TDevirtualizedTreeMenuShortCut>;
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
    procedure NotifyPopup(Node: INodeProvider; Menu: TPopupMenu; Column: TColumnIndex);
    property FallbackMenu: TPopupMenu read FFallbackMenu;
    property OnMainAction: TNodeProviderEvent read FOnMainAction write FOnMainAction;
    property MainActionText: String read GetMainActionText write SetMainActionText;
    constructor Create(Owner: TDevirtualizedTree);
  end;

  TDevirtualizedTreePopupMode = (pmOnItemsOnly, pmAnywhere);

  TDevirtualizedTreeOptions = class (TStringTreeOptions)
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

  TDevirtualizedTreeColumns = class (TVirtualTreeColumns)
  public
    function BeginUpdateAuto: IAutoReleasable;
  end;

  TDevirtualizedTreeHeader = class (TVTHeader)
  private
    function GetColumns: TDevirtualizedTreeColumns;
    procedure SetColumns(const Value: TDevirtualizedTreeColumns);
  protected
    function GetColumnsClass: TVirtualTreeColumnsClass; override;
  public
    constructor Create(AOwner: TCustomControl); override;
  published
    property Columns: TDevirtualizedTreeColumns read GetColumns write SetColumns stored False;
    property DefaultHeight default 24;
    property Height default 24;
    property Options default [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack, hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize, hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption];
  end;

  TDevirtualizedTree = class (TVirtualStringTree)
  private
    FDefaultMenus: TDevirtualizedTreeDefaultMenu;
    FPopupMenu: TPopupMenu;
    FPopupMode: TDevirtualizedTreePopupMode;
    FEmptyListMessage: String;
    FEmptyListMessageLines: TArray<String>;
    procedure SetEmptyListMessage(Value: String);
    function GetMainActionMenuText: String;
    procedure SetMainActionMenuText(Value: String);
    procedure SetPopupMenu(Value: TPopupMenu);
    function GetTreeOptions: TDevirtualizedTreeOptions;
    procedure SetTreeOptions(Value: TDevirtualizedTreeOptions);
    function GetHeader: TDevirtualizedTreeHeader;
    procedure SetHeader(const Value: TDevirtualizedTreeHeader);
    function GetOnMainAction: TNodeProviderEvent;
    procedure SetOnMainAction(Value: TNodeProviderEvent);
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
    property ClipboardFormats;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddChild(NewProvider: INodeProvider; [opt] Parent: INodeProvider = nil; AutoExpandParent: Boolean = True): INodeProvider; reintroduce;
    procedure ApplyFilter(const Query: String; UseColumn: TColumnIndex = -1);
    function BackupSelectionAuto(Comparer: TMapRoutine<INodeProvider, TCondition<INodeProvider>>): IDeferredOperation;
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
  published
    property DrawSelectionMode default smBlendedRectangle;
    property EmptyListMessage: String read FEmptyListMessage write SetEmptyListMessage;
    property Header: TDevirtualizedTreeHeader read GetHeader write SetHeader;
    property HintMode default hmHint;
    property IncrementalSearch default isAll;
    property MainActionMenuText: String read GetMainActionMenuText write SetMainActionMenuText;
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;
    property PopupMode: TDevirtualizedTreePopupMode read FPopupMode write FPopupMode default pmOnItemsOnly;
    property SelectionBlendFactor default 64;
    property TreeOptions: TDevirtualizedTreeOptions read GetTreeOptions write SetTreeOptions;
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

    function GetTree: TDevirtualizedTree; virtual;
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

    property Tree: TDevirtualizedTree read GetTree;
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
  NtUtils.SysUtils;

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

{ TVTVirtualNodeEnumerationHelper }

function TVTVirtualNodeEnumerationHelper.CountNodes;
var
  Node: PVirtualNode;
begin
  Result := 0;

  for Node in Self do
    Inc(Result);
end;

function TVTVirtualNodeEnumerationHelper.CountProviders;
var
  Node: PVirtualNode;
begin
  Result := 0;

  for Node in Self do
    if Node.HasProvider then
      Inc(Result);
end;

function TVTVirtualNodeEnumerationHelper.Nodes;
var
  Node: PVirtualNode;
  i: Integer;
begin
  SetLength(Result, CountNodes);

  i := 0;
  for Node in Self do
  begin
    Result[i] := Node;
    Inc(i);
  end;
end;

function TVTVirtualNodeEnumerationHelper.Providers;
var
  Node: PVirtualNode;
  Provider: INodeProvider;
  i: Integer;
begin
  SetLength(Result, CountProviders);

  i := 0;
  for Node in Self do
    if Node.TryGetProvider(Provider) then
    begin
      Result[i] := Provider;
      Inc(i);
    end;
end;

{ TDevirtualizedTreeMenuShortCut }

class function TDevirtualizedTreeMenuShortCut.Collect;
begin
  Result := nil;

  // Save the shortcut from the current item
  if Item.ShortCut <> 0 then
    Result := [TDevirtualizedTreeMenuShortCut.Create(Item)];

  // Process netsed items recursively
  for Item in Item do
    Result := Result + TDevirtualizedTreeMenuShortCut.Collect(Item);
end;

constructor TDevirtualizedTreeMenuShortCut.Create;
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

function TDevirtualizedTreeMenuShortCut.Matches;
begin
  Result := (Self.ShiftState = ShiftState) and (Self.Key = Key);
end;

{ TDevirtualizedTreeDefaultMenu }

procedure TDevirtualizedTreeDefaultMenu.AttachItemsTo;
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

constructor TDevirtualizedTreeDefaultMenu.Create;
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

function TDevirtualizedTreeDefaultMenu.GetMainActionText;
begin
  Result := FMenuMainAction.Caption;
end;

procedure TDevirtualizedTreeDefaultMenu.InvokeMainAction;
begin
  MenuMainActionClick(FTree);
end;

procedure TDevirtualizedTreeDefaultMenu.InvokeShortcuts;
var
  Shortcut: TDevirtualizedTreeMenuShortCut;
begin
  inherited;

  // Ignore item-specific shortcuts when they are no items selected
  if (FTree.SelectedCount <= 0) and (FTree.PopupMode = pmOnItemsOnly) then
    Exit;

  // Invoke events on all menu items with matching shortcuts
  for Shortcut in FShortcuts do
    if Shortcut.Matches(Shift, Key) and Assigned(Shortcut.Menu.OnClick) then
      Shortcut.Menu.OnClick(FTree);
end;


procedure TDevirtualizedTreeDefaultMenu.MenuCopyClick;
begin
  FTree.CopyToClipboard;
end;

procedure TDevirtualizedTreeDefaultMenu.MenuCopyColumnClick;
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

procedure TDevirtualizedTreeDefaultMenu.MenuMainActionClick;
var
  Provider: INodeProvider;
begin
  if Assigned(FOnMainAction) and FTree.FocusedNode.TryGetProvider(Provider) then
    FOnMainAction(Provider);
end;

procedure TDevirtualizedTreeDefaultMenu.NotifyPopup;
begin
  // Allow the main action only a single node that enables it
  FMenuMainAction.Visible := Assigned(FOnMainAction) and
    (FTree.SelectedCount = 1) and Node.EnabledMainActionMenu;

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

procedure TDevirtualizedTreeDefaultMenu.RefreshShortcuts;
begin
  if Assigned(FMenu) then
    FShortcuts := TDevirtualizedTreeMenuShortCut.Collect(FMenu.Items)
  else
    FShortcuts := nil;
end;

procedure TDevirtualizedTreeDefaultMenu.SetMainActionText;
begin
  FMenuMainAction.Caption := Value;
end;

{ TDevirtualizedTreeOptions }

procedure TDevirtualizedTreeOptions.AssignTo;
begin
  if Dest is TDevirtualizedTreeOptions then
    TDevirtualizedTreeOptions(Dest).FAutoShowRoot := FAutoShowRoot;

  inherited;
end;

constructor TDevirtualizedTreeOptions.Create;
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

{ TDevirtualizedTreeColumns }

function TDevirtualizedTreeColumns.BeginUpdateAuto;
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

{ TDevirtualizedTreeHeader }

constructor TDevirtualizedTreeHeader.Create;
begin
  inherited;

  // Adjust defaults
  DefaultHeight := 24;
  Height := 24;
  Options := [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack,
    hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize,
    hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption];
end;

function TDevirtualizedTreeHeader.GetColumns;
begin
  Result := TDevirtualizedTreeColumns(inherited Columns);
end;

function TDevirtualizedTreeHeader.GetColumnsClass;
begin
  Result := TDevirtualizedTreeColumns;
end;

procedure TDevirtualizedTreeHeader.SetColumns;
begin
  inherited Columns := Value;
end;

{ TDevirtualizedTree }

function TDevirtualizedTree.AddChild;
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

procedure TDevirtualizedTree.ApplyFilter;
var
  Node, Parent: INodeProvider;
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
  for Node in Nodes.Providers do
    IsVisible[Node.Node] := Node.SearchExpression('', -1);

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
  for Node in VisibleNodes.Providers do
  begin
    Matches := False;

    // At least one coulmn should match
    for Column in SearchColumns do
    begin
      Matches := (IsNumberSearch and
        Node.SearchNumber(NumberQuery, IsSignedNumber, Column.Index)) or
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
        Parent := NodeParent[Node.Node].Provider;
      until not Assigned(Parent);
    end
    else
      IsVisible[Node.Node] := False;
  end;
end;

function TDevirtualizedTree.BackupSelectionAuto;
var
  WeakRef: IWeak;
  SelectionConditions: TArray<TCondition<INodeProvider>>;
  FocusCondition: TCondition<INodeProvider>;
  Provider: INodeProvider;
begin
  // For each selected node, capture necessary data for later comparison
  SelectionConditions := TArray.Map<INodeProvider, TCondition<INodeProvider>>(
    SelectedNodes.Providers, Comparer);

  // Same for the focused node
  if FocusedNode.TryGetProvider(Provider) then
    FocusCondition := Comparer(Provider)
  else
    FocusCondition := nil;

  // Use a weak reference to verify that the defer didn't outlive the tree
  WeakRef := Auto.RefWeak(Self);

  // Restore selection afterward
  Result := Auto.Defer(
    procedure
    var
      SelectionCondition: TCondition<INodeProvider>;
      Node: INodeProvider;
    begin
      // Check if the tree is still alive
      if not WeakRef.HasRef then
        Exit;

      BeginUpdateAuto;

      // Check new nodes for matching any conditions for selection
      for Node in Nodes.Providers do
      begin
        for SelectionCondition in SelectionConditions do
          if Assigned(SelectionCondition) and
            SelectionCondition(Node) then
          begin
            Selected[Node.Node] := True;
            Break;
          end;

        // Same for the focus
        if Assigned(FocusCondition) and FocusCondition(Node) then
          FocusedNode := Node.Node;
      end;

      // Re-apply sorting
      Sort(nil, Header.SortColumn, Header.SortDirection);
    end
  );
end;

function TDevirtualizedTree.BeginUpdateAuto;
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

function TDevirtualizedTree.CanMoveSelectedNodesDown;
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

function TDevirtualizedTree.CanMoveSelectedNodesUp;
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

procedure TDevirtualizedTree.Clear;
begin
  inherited;

  if TreeOptions.AutoShowRoot then
    TreeOptions.PaintOptions := TreeOptions.PaintOptions - [toShowRoot];
end;

constructor TDevirtualizedTree.Create;
begin
  inherited;

  // Always include a menu for copying and inspecting items
  FDefaultMenus := TDevirtualizedTreeDefaultMenu.Create(Self);

  // Adjust defaults
  DrawSelectionMode := smBlendedRectangle;
  HintMode := hmHint;
  IncrementalSearch := isAll;
  SelectionBlendFactor := 64;
  ClipboardFormats.Add('CSV');
  ClipboardFormats.Add('Plain text');
  ClipboardFormats.Add('Unicode text');
end;

procedure TDevirtualizedTree.DblClick;
begin
  inherited;

  // Enter, Double Click, and Inspect should all invoke the main action
  FDefaultMenus.InvokeMainAction;
end;

procedure TDevirtualizedTree.DeleteSelectedNodes;
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
    FocusedNode := SelectionCandidate;
end;

destructor TDevirtualizedTree.Destroy;
begin
  FDefaultMenus.Free;
  inherited;
end;

procedure TDevirtualizedTree.DoAfterPaint;
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

procedure TDevirtualizedTree.DoBeforeItemErase;
var
  Provider: INodeProvider;
begin
  // Preload the background color
  if Node.TryGetProvider(Provider) and Provider.HasColor then
    Color := Provider.Color;

  inherited;
end;

procedure TDevirtualizedTree.DoChange;
var
  Provider: INodeProvider;
begin
  inherited;

  // If we don't know the node, notify all
  if not Assigned(Node) then
    for Provider in Nodes.Providers do
      Provider.NotifySelected
  // Otherwise, notify selected
  else if Node.TryGetProvider(Provider) then
    Provider.NotifySelected;
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

function TDevirtualizedTree.DoCompare;
begin
  if Assigned(OnCompareNodes) then
    OnCompareNodes(Self, Node1, Node2, Column, Result)
  else
    // Fall back to logical text comparison
    Result := StrCmpLogicalW(PWideChar(inherited Text[Node1, Column]),
      PWideChar(inherited Text[Node2, Column]));
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
  Node: PVirtualNode;
  Provider: INodeProvider;
begin
  inherited;

  Node := GetNodeAt(ScreenToClient(Mouse.CursorPos));

  if Node.TryGetProvider(Provider) and Provider.HasCursor then
    Cursor := Provider.Cursor;
end;

function TDevirtualizedTree.DoGetNodeHint;
var
  Provider: INodeProvider;
begin
  LineBreakStyle := hlbDefault;

  // Override inherited hint with the one provided by the node
  if Node.TryGetProvider(Provider) then
    Result := Provider.Hint
  else
    Result := inherited;
end;

function TDevirtualizedTree.DoGetPopupMenu;
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
  FDefaultMenus.NotifyPopup(Node.Provider, Result, Column);
end;

procedure TDevirtualizedTree.DoGetText;
var
  Provider: INodeProvider;
begin
  // Init if necessary
  if not (vsInitialized in EventArgs.Node.States) then
    InitNode(EventArgs.Node);

  // Ask the provider
  if EventArgs.Node.TryGetProvider(Provider) then
    EventArgs.CellText := Provider.ColumnText[EventArgs.Column]
  else
    inherited;
end;

function TDevirtualizedTree.DoInitChildren;
var
  Provider: INodeProvider;
begin
  if Node.TryGetProvider(Provider) then
    Result := Provider.InitializeChildren
  else
    Result := inherited;
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
  // Preload the font color and style
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
begin
  // Fix errors caused by invoking the OnRemoveFromSelection event on a
  // half-destroyed form
  if not (csDestroying in ComponentState) then
    inherited;
end;

procedure TDevirtualizedTree.EnsureNodeSelected;
begin
  if toAlwaysSelectNode in TreeOptions.SelectionOptions then
    inherited EnsureNodeSelected

  // Note: this is not an override method; change purely for local callers
  else if SelectedCount < 1 then
    FocusedNode := GetFirstVisible;
end;

function TDevirtualizedTree.GetHeader;
begin
  Result := TDevirtualizedTreeHeader(inherited Header);
end;

function TDevirtualizedTree.GetHeaderClass;
begin
  Result := TDevirtualizedTreeHeader;
end;

function TDevirtualizedTree.GetMainActionMenuText;
begin
  Result := FDefaultMenus.MainActionText;
end;

function TDevirtualizedTree.GetOnMainAction;
begin
  Result := FDefaultMenus.OnMainAction;
end;

function TDevirtualizedTree.GetOptionsClass;
begin
  Result := TDevirtualizedTreeOptions;
end;

function TDevirtualizedTree.GetTreeOptions;
begin
  Result := TDevirtualizedTreeOptions(inherited TreeOptions);
end;

function TDevirtualizedTree.InsertNode;
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

procedure TDevirtualizedTree.KeyDown;
begin
  inherited;

  // Process shortcuts on all menu items
  FDefaultMenus.InvokeShortcuts(Key, Shift);
end;

function TDevirtualizedTree.MoveSelectedNodesDown;
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

function TDevirtualizedTree.MoveSelectedNodesUp;
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

procedure TDevirtualizedTree.RefreshPopupMenuShortcuts;
begin
  FDefaultMenus.RefreshShortcuts;
end;

procedure TDevirtualizedTree.SetEmptyListMessage;
begin
  if FEmptyListMessage <> Value then
  begin
    FEmptyListMessage := Value;
    FEmptyListMessageLines := Value.Split([#$D#$A]);
    Invalidate;
  end;
end;

procedure TDevirtualizedTree.SetHeader;
begin
  inherited Header := Value;
end;

procedure TDevirtualizedTree.SetMainActionMenuText;
begin
  FDefaultMenus.MainActionText := Value;
end;

procedure TDevirtualizedTree.SetOnMainAction;
begin
  FDefaultMenus.OnMainAction := Value;
end;

procedure TDevirtualizedTree.SetPopupMenu;
begin
  if FPopupMenu <> Value then
  begin
    FPopupMenu := Value;

    // Note: attaching to nil moves items back to the fallback menu
    if not (csDesigning in ComponentState) then
      FDefaultMenus.AttachItemsTo(FPopupMenu);
  end;
end;

procedure TDevirtualizedTree.SetTreeOptions;
begin
  inherited TreeOptions := Value;
end;

procedure TDevirtualizedTree.ValidateNodeDataSize;
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

    if FBaseTree is TDevirtualizedTree then
      FTree := TDevirtualizedTree(FBaseTree);
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
