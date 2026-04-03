unit NtUtilsUI.VirtualTreeEx;

{
  This module contains a full runtime definition of the TVirtualStringTreeEx
  component - a slightly improved virtual tree view.

  NOTE: Keep the published interface in sync with the design-time definition!
}

interface

uses
  System.Classes, System.Types, Vcl.Menus, Vcl.Graphics, VirtualTrees,
  VirtualTrees.Types, VirtualTrees.Header, NtUtils, DelphiUtils.Arrays;

type
  TNodeEvent = procedure (Node: PVirtualNode) of object;

  TVTVirtualNodeEnumerationHelper = record helper for TVTVirtualNodeEnumeration
    function ToArray: TArray<PVirtualNode>;
  end;

  TVirtualTreeColumnsHelper = class helper for TVirtualTreeColumns
    function BeginUpdateAuto: IAutoReleasable;
  end;

  // A structure for capturing keyboard shortcuts of a popup menu
  TMenuShortCut = record
    Menu: TMenuItem;
    ShiftState: TShiftState;
    Key: Word;
    function Matches(ShiftState: TShiftState; Key: Word): Boolean;
    constructor Create(Item: TMenuItem);
    class function Collect(Item: TMenuItem): TArray<TMenuShortCut>; static;
  end;

  // A provider of the default menu items for extended virtual trees
  TDefaultTreeMenu = class
  private
    FTree: TCustomVirtualStringTree;
    FMenu, FFallbackMenu: TPopupMenu;
    FMenuMainAction: TMenuItem;
    FMenuSeparator: TMenuItem;
    FMenuCopy: TMenuItem;
    FMenuCopyColumn: TMenuItem;
    FShortcuts: TArray<TMenuShortCut>;
    FPopupColumnIndex: Integer;
    FOnMainAction: TNodeEvent;
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
    procedure NotifyPopup(Node: PVirtualNode; Menu: TPopupMenu; Column: TColumnIndex);
    property FallbackMenu: TPopupMenu read FFallbackMenu;
    property OnMainAction: TNodeEvent read FOnMainAction write FOnMainAction;
    property MainActionText: String read GetMainActionText write SetMainActionText;
    constructor Create(Owner: TCustomVirtualStringTree);
  end;

  TPopupMode = (pmOnItemsOnly, pmAnywhere);

  TVirtualStringTreeEx = class(TVirtualStringTree)
  private
    FDefaultMenus: TDefaultTreeMenu;
    FPopupMenuEx: TPopupMenu;
    FPopupMode: TPopupMode;
    FNoItemsText: String;
    FNoItemsTextLines: TArray<String>;
    procedure SetPopupMenuEx(const Value: TPopupMenu);
    function GetOnMainAction: TNodeEvent;
    procedure SetOnMainAction(const Value: TNodeEvent);
    procedure SetNoItemsText(const Value: String);
    function GetMainActionMenuText: String;
    procedure SetMainActionMenuText(const Value: String);
  protected
    function DoCompare(Node1, Node2: PVirtualNode; Column: TColumnIndex): Integer; override;
    function DoGetPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Position: TPoint): TPopupMenu; override;
    procedure DoRemoveFromSelection(Node: PVirtualNode); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoAfterPaint(Canvas: TCanvas); override;
  public
    function OverrideMainActionMenuEnabled(Node: PVirtualNode): Boolean; virtual;
    constructor Create(AOwner: TComponent); override;
    procedure DeleteSelectedNodesEx(SelectSomethingAfter: Boolean = True);
    procedure SelectSomething;
    procedure RefreshPopupMenuShortcuts;
    property MainActionMenuText: String read GetMainActionMenuText write SetMainActionMenuText;
    destructor Destroy; override;
    function CanMoveSelectedNodesUp: Boolean;
    function CanMoveSelectedNodesDown: Boolean;
    function MoveSelectedNodesUp: Boolean;
    function MoveSelectedNodesDown: Boolean;
    function BeginUpdateAuto: IAutoReleasable;
    function BackupSelectionAuto(Comparer: TMapRoutine<PVirtualNode, TCondition<PVirtualNode>>): IDeferredOperation;
  published
    property DrawSelectionMode default smBlendedRectangle;
    property HintMode default hmHint;
    property IncrementalSearch default isAll;
    property SelectionBlendFactor default 64;
    property OnMainAction: TNodeEvent read GetOnMainAction write SetOnMainAction;
    property PopupMenuEx: TPopupMenu read FPopupMenuEx write SetPopupMenuEx;
    property PopupMode: TPopupMode read FPopupMode write FPopupMode default pmOnItemsOnly;
    property NoItemsText: String read FNoItemsText write SetNoItemsText;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShLwApi, System.SysUtils, Vcl.Themes, Vcl.Clipbrd;

{ TVTVirtualNodeEnumerationHelper }

function TVTVirtualNodeEnumerationHelper.ToArray;
var
  Node: PVirtualNode;
  Count: Integer;
begin
  Count := 0;
  for Node in Self do
    Inc(Count);

  SetLength(Result, Count);

  Count := 0;
  for Node in Self do
  begin
    Result[Count] := Node;
    Inc(Count);
  end;
end;

{ TVirtualTreeColumnsHelper }

function TVirtualTreeColumnsHelper.BeginUpdateAuto;
begin
  BeginUpdate;

  Result := Auto.Defer(
    procedure
    begin
      EndUpdate;
    end
  );
end;

{ TMenuShortCut }

class function TMenuShortCut.Collect;
begin
  Result := nil;

  // Save the shortcut from the current item
  if Item.ShortCut <> 0 then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := TMenuShortCut.Create(Item);
  end;

  // Process netsed items recursively
  for Item in Item do
    Result := Result + TMenuShortCut.Collect(Item);
end;

constructor TMenuShortCut.Create;
begin
  Menu := Item;
  Key := Item.ShortCut and $FFF;
  ShiftState := [];

  if LongBool(Item.ShortCut and scCommand) then
    Include(ShiftState, ssCommand);

  if LongBool(Item.ShortCut and scCtrl) then
    Include(ShiftState, ssCtrl);

  if LongBool(Item.ShortCut and scShift) then
    Include(ShiftState, ssShift);

  if LongBool(Item.ShortCut and scAlt) then
    Include(ShiftState, ssAlt);
end;

function TMenuShortCut.Matches;
begin
  Result := (Self.ShiftState = ShiftState) and (Self.Key = Key);
end;

{ TDefaultTreeMenu }

procedure TDefaultTreeMenu.AttachItemsTo;
begin
  // Note: nil means no menu, so we use our fallback one
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

constructor TDefaultTreeMenu.Create;
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
  FMenuCopyColumn.Caption := 'Copy "%s"';
  FMenuCopyColumn.OnClick := MenuCopyColumnClick;

  AttachItemsTo(FFallbackMenu);
end;

function TDefaultTreeMenu.GetMainActionText;
begin
  Result := FMenuMainAction.Caption;
end;

procedure TDefaultTreeMenu.InvokeMainAction;
begin
  MenuMainActionClick(FTree);
end;

procedure TDefaultTreeMenu.InvokeShortcuts;
var
  Shortcut: TMenuShortCut;
begin
  inherited;

  // Ignore item-specific shortcuts when they are no items selected
  if (FTree.SelectedCount = 0) and (FTree is TVirtualStringTreeEx) and
    (TVirtualStringTreeEx(FTree).PopupMode = pmOnItemsOnly) then
    Exit;

  // Invoke events on all menu items with matching shortcuts
  for Shortcut in FShortcuts do
    if Shortcut.Matches(Shift, Key) and Assigned(Shortcut.Menu.OnClick) then
      Shortcut.Menu.OnClick(FTree);
end;

procedure TDefaultTreeMenu.MenuCopyClick;
begin
  FTree.CopyToClipboard;
end;

procedure TDefaultTreeMenu.MenuCopyColumnClick;
var
  Node: PVirtualNode;
  Texts: TArray<String>;
  i: Integer;
begin
  i := 0;
  for Node in FTree.SelectedNodes do
    Inc(i);

  SetLength(Texts, i);

  i := 0;
  for Node in FTree.SelectedNodes do
  begin
    Texts[i] := FTree.Text[Node, FPopupColumnIndex];
    Inc(i);
  end;

  Clipboard.SetTextBuf(PWideChar(string.Join(#$D#$A, Texts)));
end;

procedure TDefaultTreeMenu.MenuMainActionClick;
begin
  if Assigned(FOnMainAction) and Assigned(FTree.FocusedNode) and
    (FTree.SelectedCount = 1) then
    FOnMainAction(FTree.FocusedNode);
end;

procedure TDefaultTreeMenu.NotifyPopup;
begin
  // Allow the main action only a single node
  FMenuMainAction.Visible := Assigned(FOnMainAction) and (FTree.SelectedCount = 1);

  // Allow the node selected to explicitly disable the default menu
  if Assigned(Node) and (FTree is TVirtualStringTreeEx) and
    not TVirtualStringTreeEx(FTree).OverrideMainActionMenuEnabled(Node) then
    FMenuMainAction.Visible := False;

  // Enable regular copying when there are things to copy
  FMenuCopy.Visible := FTree.SelectedCount > 0;

  // Enable column-specific copying
  FPopupColumnIndex := Column;
  FMenuCopyColumn.Visible := (FTree.SelectedCount > 0) and (Column >= 0);

  if FMenuCopyColumn.Visible then
    FMenuCopyColumn.Caption := Format('Copy "%s"',
      [FTree.Header.Columns[Column].Text]);

  // Enable the separator if there are items to separate
  FMenuSeparator.Visible := (Assigned(Menu) or FMenuMainAction.Visible) and
    FMenuCopy.Visible;
end;

procedure TDefaultTreeMenu.RefreshShortcuts;
begin
  if Assigned(FMenu) then
    FShortcuts := TMenuShortCut.Collect(FMenu.Items)
  else
    FShortcuts := nil;
end;

procedure TDefaultTreeMenu.SetMainActionText;
begin
  FMenuMainAction.Caption := Value;
end;

{ TVirtualStringTreeEx }

function TVirtualStringTreeEx.BackupSelectionAuto;
var
  SelectionConditions: TArray<TCondition<PVirtualNode>>;
  FocusCondition: TCondition<PVirtualNode>;
begin
  // For each selected node, capture necessary data for later comparison
  SelectionConditions := TArray.Map<PVirtualNode, TCondition<PVirtualNode>>(
    SelectedNodes.ToArray, Comparer);

  // Same for the focused node
  if Assigned(FocusedNode) then
    FocusCondition := Comparer(FocusedNode)
  else
    FocusCondition := nil;

  // Restore selection afterward
  Result := Auto.Defer(
    procedure
    var
      SelectionCondition: TCondition<PVirtualNode>;
      Node: PVirtualNode;
      UpdateReleaser: IAutoReleasable;
    begin
      UpdateReleaser := BeginUpdateAuto;

      // Check if each new node matches any conditions for selection
      for Node in Nodes do
      begin
        for SelectionCondition in SelectionConditions do
          if Assigned(SelectionCondition) and SelectionCondition(Node) then
          begin
            Selected[Node] := True;
            Break;
          end;

        // Same for the focus
        if Assigned(FocusCondition) and FocusCondition(Node) then
          FocusedNode := Node;
      end;

      // Re-apply sorting
      Sort(RootNode, Header.SortColumn, Header.SortDirection);
    end
  );
end;

function TVirtualStringTreeEx.BeginUpdateAuto;
begin
  BeginUpdate;

  Result := Auto.Defer(
    procedure
    begin
      EndUpdate;
    end
  );
end;

function TVirtualStringTreeEx.CanMoveSelectedNodesDown;
var
  Nodes: TArray<PVirtualNode>;
  Next: PVirtualNode;
  i: Integer;
begin
  Result := False;
  Nodes := SelectedNodes.ToArray;

  for i := High(Nodes) downto 0 do
  begin
    Next := GetNext(Nodes[i]);

    // Check if we can move each node after its next without passing previously
    // moved
    if Assigned(Next) and ((i = High(Nodes)) or (Next <> Nodes[i + 1])) then
      Exit(True);
  end;
end;

function TVirtualStringTreeEx.CanMoveSelectedNodesUp;
var
  Nodes: TArray<PVirtualNode>;
  Previous: PVirtualNode;
  i: Integer;
begin
  Result := False;
  Nodes := SelectedNodes.ToArray;

  for i := 0 to High(Nodes) do
  begin
    Previous := GetPrevious(Nodes[i]);

    // Check if we can move each node before its previous without passing
    // previously moved
    if Assigned(Previous) and ((i = 0) or (Previous <> Nodes[i - 1])) then
      Exit(True);
  end;
end;

constructor TVirtualStringTreeEx.Create;
begin
  inherited;

  // Always include a menu for copying and inspecting items
  FDefaultMenus := TDefaultTreeMenu.Create(Self);

  // Adjust some defaults
  DrawSelectionMode := smBlendedRectangle;
  HintMode := hmHint;
  IncrementalSearch := isAll;
  SelectionBlendFactor := 64;
  TreeOptions.AutoOptions := [toAutoDropExpand, toAutoScrollOnExpand,
    toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale];
  TreeOptions.ExportMode := emSelected;
  TreeOptions.MiscOptions := [toAcceptOLEDrop, toFullRepaintOnResize,
    toInitOnSave, toToggleOnDblClick, toWheelPanning];
  TreeOptions.PaintOptions := [toHideFocusRect, toHotTrack, toShowButtons,
    toShowDropmark, toThemeAware, toUseBlendedImages, toUseExplorerTheme];
  TreeOptions.SelectionOptions := [toFullRowSelect, toMultiSelect,
    toRightClickSelect];
  Header.DefaultHeight := 24;
  Header.Height := 24;
  Header.Options := [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack,
    hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize,
    hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption];

  ClipboardFormats.Add('CSV');
  ClipboardFormats.Add('Plain text');
  ClipboardFormats.Add('Unicode text');
end;

procedure TVirtualStringTreeEx.DblClick;
begin
  inherited;

  // Enter, Double Click, and Inspect should invoke the main action
  FDefaultMenus.InvokeMainAction;
end;

procedure TVirtualStringTreeEx.DeleteSelectedNodesEx;
var
  SelectionLookupStart: PVirtualNode;
  SelectionCandidate: PVirtualNode;
begin
  if SelectedCount <= 0 then
    Exit;

  try
    BeginUpdate;
    SelectionCandidate := nil;

    if SelectSomethingAfter then
    begin
      // We want the future selection to be in the same area of the tree
      if Assigned(FocusedNode) then
        SelectionLookupStart := FocusedNode
      else
        SelectionLookupStart := GetFirstSelected(True);

      // Choose an item below for future selection
      SelectionCandidate := SelectionLookupStart;
      while Assigned(SelectionCandidate) and Selected[SelectionCandidate] do
        SelectionCandidate := GetNextVisible(SelectionCandidate, True);

      // No items below are suitable; try items above
      if not Assigned(SelectionCandidate) then
      begin
        SelectionCandidate := SelectionLookupStart;
        while Assigned(SelectionCandidate) and Selected[SelectionCandidate] do
           SelectionCandidate := GetPreviousVisible(SelectionCandidate, True);
      end;
    end;

    // Perform deletion
    DeleteSelectedNodes;
    ClearSelection;

    // Select and focus the candidate
    if Assigned(SelectionCandidate) then
    begin
      FocusedNode := SelectionCandidate;
      Selected[SelectionCandidate] := True;
    end;
  finally
    EndUpdate;
  end;
end;

destructor TVirtualStringTreeEx.Destroy;
begin
  FDefaultMenus.Free;
  inherited;
end;

procedure TVirtualStringTreeEx.DoAfterPaint;
var
  Sizes: TArray<TSize>;
  TotalHeight, Offset: Integer;
  i: Integer;
begin
  // Draw the no-items text
  if (VisibleCount = 0) and (Length(FNoItemsTextLines) > 0) then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := StyleServices.GetStyleFontColor(sfListItemTextDisabled);

    // Compute the sizes of each line
    SetLength(Sizes, Length(FNoItemsTextLines));
    TotalHeight := 0;

    for i := 0 to High(FNoItemsTextLines) do
    begin
      Sizes[i] := Canvas.TextExtent(FNoItemsTextLines[i]);
      Inc(TotalHeight, Sizes[i].Height);
    end;

    Offset := 0;

    // Draw the static text in the middle of an empty tree
    for i := 0 to High(FNoItemsTextLines) do
    begin
      Canvas.TextOut(
        (ClientWidth - Sizes[i].Width) div 2,
        (ClientHeight - Sizes[i].Height - TotalHeight) div 2 + Offset,
        FNoItemsTextLines[i]);
      Inc(Offset, Sizes[i].Height);
    end;
  end;

  inherited DoAfterPaint(Canvas);
end;

function TVirtualStringTreeEx.DoCompare;
begin
  Result := inherited;

  // Fallback to logical text comparison by default
  if not Assigned(OnCompareNodes) then
    Result := StrCmpLogicalW(PWideChar(Text[Node1, Column]),
      PWideChar(Text[Node2, Column]));
end;

function TVirtualStringTreeEx.DoGetPopupMenu;
begin
  Result := inherited DoGetPopupMenu(Node, Column, Position);

  if Header.InHeader(Position) then
    Exit;

  if (FPopupMode = pmOnItemsOnly) and (SelectedCount = 0) then
    Exit;

  // Choose a context menu
  if not Assigned(Result) then
    if Assigned(FPopupMenuEx) then
      Result := FPopupMenuEx
    else
      Result := FDefaultMenus.FallbackMenu;

  // Update visibility of the built-in items
  FDefaultMenus.NotifyPopup(Node, Result, Column);
end;

procedure TVirtualStringTreeEx.DoRemoveFromSelection;
begin
  // Fix errors caused by invoking the OnRemoveFromSelection event on a
  // half-destroyed form
  if not (csDestroying in ComponentState) then
    inherited;
end;

function TVirtualStringTreeEx.GetMainActionMenuText;
begin
  Result := FDefaultMenus.MainActionText;
end;

function TVirtualStringTreeEx.GetOnMainAction;
begin
  Result := FDefaultMenus.OnMainAction;
end;

procedure TVirtualStringTreeEx.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;

  // Process shortcuts on all menu items
  FDefaultMenus.InvokeShortcuts(Key, Shift);
end;

function TVirtualStringTreeEx.MoveSelectedNodesDown;
var
  Nodes: TArray<PVirtualNode>;
  Next: PVirtualNode;
  i: Integer;
begin
  try
    BeginUpdate;
    Result := False;
    Nodes := SelectedNodes.ToArray;

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
  finally
    EndUpdate;
  end;
end;

function TVirtualStringTreeEx.MoveSelectedNodesUp;
var
  Nodes: TArray<PVirtualNode>;
  Previous: PVirtualNode;
  i: Integer;
begin
  try
    BeginUpdate;
    Result := False;
    Nodes := SelectedNodes.ToArray;

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
  finally
    EndUpdate;
  end;
end;

function TVirtualStringTreeEx.OverrideMainActionMenuEnabled;
begin
  Result := True;
end;

procedure TVirtualStringTreeEx.RefreshPopupMenuShortcuts;
begin
  FDefaultMenus.RefreshShortcuts;
end;

procedure TVirtualStringTreeEx.SelectSomething;
var
  Node: PVirtualNode;
begin
  if SelectedCount > 0 then
    Exit;

  Node := GetFirstVisible;

  if Assigned(Node) then
  begin
    FocusedNode := Node;
    Selected[Node] := True;
  end;
end;

procedure TVirtualStringTreeEx.SetMainActionMenuText;
begin
  FDefaultMenus.MainActionText := Value;
end;

procedure TVirtualStringTreeEx.SetNoItemsText;
begin
  FNoItemsText := Value;
  FNoItemsTextLines := FNoItemsText.Split([#$D#$A]);
  Invalidate;
end;

procedure TVirtualStringTreeEx.SetOnMainAction;
begin
  FDefaultMenus.OnMainAction := Value;
end;

procedure TVirtualStringTreeEx.SetPopupMenuEx;
begin
  FPopupMenuEx := Value;

  if csDesigning in ComponentState then
    Exit;

  // Note: attaching to nil moves items back to the fallback menu
  FDefaultMenus.AttachItemsTo(FPopupMenuEx);
end;

end.
