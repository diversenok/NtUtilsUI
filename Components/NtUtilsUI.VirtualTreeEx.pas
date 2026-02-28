unit NtUtilsUI.VirtualTreeEx;

{
  This module contains a full runtime definition of the TVirtualStringTreeEx
  component - a slightly improved virtual tree view.

  NOTE: Keep the published interface in sync with the design-time definition!
}

interface

uses
  System.Classes, System.Types, Vcl.Menus, Vcl.Graphics, VirtualTrees,
  VirtualTrees.Types, VirtualTrees.Header, NtUtilsUI.VirtualTreeEx.DefaultMenu;

type
  TNodeEvent = NtUtilsUI.VirtualTreeEx.DefaultMenu.TNodeEvent;

  TVTVirtualNodeEnumerationHelper = record helper for TVTVirtualNodeEnumeration
    function ToArray: TArray<PVirtualNode>;
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
  System.SysUtils, Winapi.ShLwApi, Vcl.Themes;

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

{ TVirtualStringTreeEx }

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
