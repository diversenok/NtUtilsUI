unit VirtualTreesEx;

{
  This module provides a sligtly improved virtual tree view.
}

interface

uses
  System.Classes, System.Types, Vcl.Menus, Vcl.Graphics, VirtualTrees,
  VirtualTrees.Types, VirtualTrees.Header, VirtualTreesEx.DefaultMenu;

type
  TNodeEvent = VirtualTreesEx.DefaultMenu.TNodeEvent;

  TVTVirtualNodeEnumerationHelper = record helper for TVTVirtualNodeEnumeration
    function ToArray: TArray<PVirtualNode>;
  end;

  TVirtualStringTreeEx = class(TVirtualStringTree)
  private
    FDefaultMenus: TDefaultTreeMenu;
    FNodePopupMenu: TPopupMenu;
    procedure SetNodePopupMenu(const Value: TPopupMenu);
    function GetOnInspectNode: TNodeEvent;
    procedure SetOnInspectNode(const Value: TNodeEvent);
  protected
    function DoCompare(Node1, Node2: PVirtualNode; Column: TColumnIndex): Integer; override;
    function DoGetPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Position: TPoint): TPopupMenu; override;
    procedure DoInitNode(Parent, Node: PVirtualNode; var InitStates: TVirtualNodeInitStates); override;
    procedure DoRemoveFromSelection(Node: PVirtualNode); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    function OverrideInspectMenuEnabled(Node: PVirtualNode): Boolean; virtual;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property DrawSelectionMode default smBlendedRectangle;
    property HintMode default hmHint;
    property IncrementalSearch default isAll;
    property SelectionBlendFactor default 64;
    property OnInspectNode: TNodeEvent read GetOnInspectNode write SetOnInspectNode;
    property NodePopupMenu: TPopupMenu read FNodePopupMenu write SetNodePopupMenu;
  end;

procedure Register;

implementation

uses
  System.SysUtils;

procedure Register;
begin
  RegisterComponents('Virtual Controls', [TVirtualStringTreeEx]);
end;

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

  // Enter, Double Click, and Inspect should yield the same result
  FDefaultMenus.InvokeInspect;
end;

destructor TVirtualStringTreeEx.Destroy;
begin
  FDefaultMenus.Free;
  inherited;
end;

function TVirtualStringTreeEx.DoCompare;
begin
  Result := inherited;

  // Fallback to text comparison by default
  if not Assigned(OnCompareNodes) then
    Result := String.Compare(Text[Node1, Column], Text[Node2, Column]);
end;

function TVirtualStringTreeEx.DoGetPopupMenu;
begin
  Result := inherited DoGetPopupMenu(Node, Column, Position);

  if Header.InHeader(Position) or (SelectedCount = 0) then
    Exit;

  // Choose a context menu
  if not Assigned(Result) then
    if Assigned(FNodePopupMenu) then
      Result := FNodePopupMenu
    else
      Result := FDefaultMenus.FallbackMenu;

  // Update visibility of the built-in items
  FDefaultMenus.NotifyPopup(Node, Result, Column);
end;

procedure TVirtualStringTreeEx.DoInitNode;
begin
  // Pre-populate checkboxes by default when the feature is enabled
  if toCheckSupport in TreeOptions.MiscOptions then
    CheckType[Node] := ctCheckBox;

  inherited;
end;

procedure TVirtualStringTreeEx.DoRemoveFromSelection;
begin
  // Fix errors caused by invoking the OnRemoveFromSelection event on a
  // half-destroyed form
  if not (csDestroying in ComponentState) then
    inherited;
end;

function TVirtualStringTreeEx.GetOnInspectNode;
begin
  Result := FDefaultMenus.OnInspect;
end;

procedure TVirtualStringTreeEx.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;

  // Process shortcuts on all menu items
  FDefaultMenus.InvokeShortcuts(Key, Shift);
end;

function TVirtualStringTreeEx.OverrideInspectMenuEnabled;
begin
  Result := True;
end;

procedure TVirtualStringTreeEx.SetNodePopupMenu;
begin
  FNodePopupMenu := Value;

  if csDesigning in ComponentState then
    Exit;

  // Note: attaching to nil moves items back to the fallback menu
  FDefaultMenus.AttachItemsTo(FNodePopupMenu);
end;

procedure TVirtualStringTreeEx.SetOnInspectNode;
begin
  FDefaultMenus.OnInspect := Value;
end;

end.
