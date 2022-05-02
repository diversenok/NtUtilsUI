unit VirtualTreesEx.DefaultMenu;

{
  This module provides the default popup menu for the VirtualTreeView for
  copying and inspecting items.
}

interface

uses
  VirtualTrees, Vcl.Menus, System.Classes;

type
  TNodeEvent = procedure (Node: PVirtualNode) of object;

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
    FFallbackMenu: TPopupMenu;
    FMenuInspect: TMenuItem;
    FMenuSeparator: TMenuItem;
    FMenuCopy: TMenuItem;
    FMenuCopyColumn: TMenuItem;
    FShortcuts: TArray<TMenuShortCut>;
    FPopupColumnIndex: Integer;
    FOnInspectNode: TNodeEvent;
    procedure MenuInspectClick(Sender: TObject);
    procedure MenuCopyClick(Sender: TObject);
    procedure MenuCopyColumnClick(Sender: TObject);
  public
    procedure AttachItemsTo(Menu: TPopupMenu);
    procedure InvokeShortcuts(Key: Word; Shift: TShiftState);
    procedure InvokeInspect;
    procedure NotifyPopup(Node: PVirtualNode; Menu: TPopupMenu; Column: TColumnIndex);
    property FallbackMenu: TPopupMenu read FFallbackMenu;
    property OnInspect: TNodeEvent read FOnInspectNode write FOnInspectNode;
    constructor Create(Owner: TCustomVirtualStringTree);
  end;

implementation

uses
  Winapi.Windows, Vcl.Clipbrd, System.SysUtils, VirtualTreesEx;

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

  // Attach the item for inspecting to the top
  if Assigned(FMenuInspect.Parent) then
    FMenuInspect.Parent.Remove(FMenuInspect);

  Menu.Items.Insert(0, FMenuInspect);

  // Attach items for copying text to the bottom of the popup menu
  FMenuSeparator.SetParentComponent(Menu);
  FMenuCopy.SetParentComponent(Menu);
  FMenuCopyColumn.SetParentComponent(Menu);

  // Merge and capture existing and new keyboard shortcuts
  FShortcuts := TMenuShortCut.Collect(Menu.Items);
end;

constructor TDefaultTreeMenu.Create;
begin
  FTree := Owner;
  FFallbackMenu := TPopupMenu.Create(FTree);

  FMenuInspect := TMenuItem.Create(FTree);
  FMenuInspect.Caption := 'Inspect';
  FMenuInspect.Default := True;
  FMenuInspect.ShortCut := VK_RETURN;
  FMenuInspect.Visible := False;
  FMenuInspect.OnClick := MenuInspectClick;

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

procedure TDefaultTreeMenu.InvokeInspect;
begin
  MenuInspectClick(FTree);
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

procedure TDefaultTreeMenu.MenuInspectClick;
begin
  if Assigned(FOnInspectNode) and Assigned(FTree.FocusedNode) and
    (FTree.SelectedCount = 1) then
    FOnInspectNode(FTree.FocusedNode);
end;

procedure TDefaultTreeMenu.NotifyPopup;
begin
  // Allow inspecting only single node
  FMenuInspect.Visible := Assigned(FOnInspectNode) and (FTree.SelectedCount = 1);

  // Allow the node selected to explicitly disable the inspect menu
  if Assigned(Node) and (FTree is TVirtualStringTreeEx) and
    not TVirtualStringTreeEx(FTree).OverrideInspectMenuEnabled(Node) then
    FMenuInspect.Visible := False;

  // Enable regular copiying when there are things to copy
  FMenuCopy.Visible := FTree.SelectedCount > 0;

  // Enable column-specific copying
  FPopupColumnIndex := Column;
  FMenuCopyColumn.Visible := (FTree.SelectedCount > 0) and (Column >= 0);

  if FMenuCopyColumn.Visible then
    FMenuCopyColumn.Caption := Format('Copy "%s"',
      [FTree.Header.Columns[Column].CaptionText]);

  // Enable the separator if there are items to separate
  FMenuSeparator.Visible := (Assigned(Menu) or FMenuInspect.Visible) and
    FMenuCopy.Visible;
end;

end.
