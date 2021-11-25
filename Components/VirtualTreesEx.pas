unit VirtualTreesEx;

interface

uses
  System.SysUtils, System.Classes, System.Types, Vcl.Controls, Vcl.Menus,
  VirtualTrees;

type
  TNodeEvent = procedure (Node: PVirtualNode) of object;

  TMenuShortCut = record
    Menu: TMenuItem;
    ShiftState: TShiftState;
    Key: Word;
    function Matches(ShiftState: TShiftState; Key: Word): Boolean;
    constructor Create(Item: TMenuItem);
    class function Collect(Item: TMenuItem): TArray<TMenuShortCut>; static;
  end;

  TVirtualStringTreeEx = class(TVirtualStringTree)
  private
    FOnInspectNode: TNodeEvent;
    FDefaultMenu: TPopupMenu;
    FNodePopupMenu: TPopupMenu;
    FShortcuts: TArray<TMenuShortCut>;
    FMenuInspect: TMenuItem;
    FMenuSeparator: TMenuItem;
    FMenuCopy: TMenuItem;
    FMenuCopyColumn: TMenuItem;
    FPopupColumnIndex: Integer;
    procedure MenuInspectClick(Sender: TObject);
    procedure MenuCopyClick(Sender: TObject);
    procedure MenuCopyColumnClick(Sender: TObject);
    procedure MakeDefaultMenu;
    procedure AttachDefaultMenuItems(Menu: TPopupMenu);
    procedure SetNodePopupMenu(const Value: TPopupMenu);
  protected
    function CollectNodes(Nodes: TVTVirtualNodeEnumeration): TArray<PVirtualNode>;
    function DoGetPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Position: TPoint): TPopupMenu; override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property OnInspectNode: TNodeEvent read FOnInspectNode write FOnInspectNode;
    property NodePopupMenu: TPopupMenu read FNodePopupMenu write SetNodePopupMenu;
  end;

procedure Register;

implementation

uses
  Winapi.Windows, Vcl.Clipbrd;

procedure Register;
begin
  RegisterComponents('Virtual Controls', [TVirtualStringTreeEx]);
end;

{ TMenuShortCut }

class function TMenuShortCut.Collect;
begin
  Result := nil;

  if Item.ShortCut <> 0 then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := TMenuShortCut.Create(Item);
  end;

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

{ TVirtualStringTreeEx }

procedure TVirtualStringTreeEx.AttachDefaultMenuItems;
begin
  FMenuInspect.SetParentComponent(Menu);
  FMenuSeparator.SetParentComponent(Menu);
  FMenuCopy.SetParentComponent(Menu);
  FMenuCopyColumn.SetParentComponent(Menu);

  FShortcuts := TMenuShortCut.Collect(Menu.Items);
end;

function TVirtualStringTreeEx.CollectNodes;
var
  Node: PVirtualNode;
  Count: Integer;
begin
  Count := 0;
  for Node in Nodes do
    Inc(Count);

  SetLength(Result, Count);

  Count := 0;
  for Node in Nodes do
  begin
    Result[Count] := Node;
    Inc(Count);
  end;
end;

constructor TVirtualStringTreeEx.Create;
begin
  inherited Create(AOwner);
  MakeDefaultMenu;
end;

procedure TVirtualStringTreeEx.DblClick;
begin
  inherited;

  if not Assigned(OnDblClick) then
    MenuInspectClick(Self);
end;

function TVirtualStringTreeEx.DoGetPopupMenu;
begin
  Result := inherited DoGetPopupMenu(Node, Column, Position);

  if Header.InHeader(Position) or (SelectedCount = 0) then
    Exit;

  // Allow inspecting a single selected item
  FMenuInspect.Visible := Assigned(FOnInspectNode) and (SelectedCount = 1);
  FMenuSeparator.Visible := Assigned(Result) or FMenuInspect.Visible;

  // Choose a context menu
  if not Assigned(Result) then
    if Assigned(FNodePopupMenu) then
      Result := FNodePopupMenu
    else
      Result := FDefaultMenu;

  // Enable column-specific copying
  FPopupColumnIndex := Column;
  FMenuCopyColumn.Visible := Column >= 0;

  if FMenuCopyColumn.Visible then
    FMenuCopyColumn.Caption := 'Copy "' + Header.Columns[Column].CaptionText + '"';
end;

procedure TVirtualStringTreeEx.KeyDown(var Key: Word; Shift: TShiftState);
var
  Shortcut: TMenuShortCut;
begin
  inherited;

  // Invoke events on all menu items with matching shortcuts
  if SelectedCount > 0 then
    for Shortcut in FShortcuts do
      if Shortcut.Matches(Shift, Key) and Assigned(Shortcut.Menu.OnClick) then
        Shortcut.Menu.OnClick(Self);
end;

procedure TVirtualStringTreeEx.MakeDefaultMenu;
begin
  FDefaultMenu := TPopupMenu.Create(Self);

  FMenuInspect := TMenuItem.Create(Self);
  FMenuInspect.Caption := 'Inspect';
  FMenuInspect.Default := True;
  FMenuInspect.ShortCut := VK_RETURN;
  FMenuInspect.Visible := False;
  FMenuInspect.OnClick := MenuInspectClick;

  FMenuSeparator := TMenuItem.Create(Self);
  FMenuSeparator.Caption := '-';
  FMenuSeparator.Visible := False;

  FMenuCopy := TMenuItem.Create(Self);
  FMenuCopy.Caption := 'Copy';
  FMenuCopy.ShortCut := scCtrl or Ord('C');
  FMenuCopy.OnClick := MenuCopyClick;

  FMenuCopyColumn := TMenuItem.Create(Self);
  FMenuCopyColumn.Caption := 'Copy "%s"';
  FMenuCopyColumn.OnClick := MenuCopyColumnClick;

  AttachDefaultMenuItems(FDefaultMenu);
end;

procedure TVirtualStringTreeEx.MenuCopyClick;
begin
  CopyToClipboard;
end;

procedure TVirtualStringTreeEx.MenuCopyColumnClick;
var
  Nodes: TArray<PVirtualNode>;
  Texts: TArray<String>;
  i: Integer;
begin
  Nodes := CollectNodes(SelectedNodes);
  SetLength(Texts, Length(Nodes));

  for i := 0 to High(Texts) do
    Texts[i] := Text[Nodes[i], FPopupColumnIndex];

  Clipboard.SetTextBuf(PWideChar(string.Join(#$D#$A, Texts)));
end;

procedure TVirtualStringTreeEx.MenuInspectClick;
var
  Node: PVirtualNode;
begin
  if Assigned(FOnInspectNode) then
    for Node in Nodes do
      if Selected[Node] then
      begin
        FOnInspectNode(Node);
        Exit;
      end;
end;

procedure TVirtualStringTreeEx.SetNodePopupMenu;
begin
  FNodePopupMenu := Value;

  if Assigned(FNodePopupMenu) then
    AttachDefaultMenuItems(FNodePopupMenu)
  else
    AttachDefaultMenuItems(FDefaultMenu);
end;

end.
