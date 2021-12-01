unit VirtualTreesEx;

interface

uses
  System.SysUtils, System.Classes, System.Types, Vcl.Controls, Vcl.Menus,
  Vcl.Graphics, VirtualTrees, VirtualTrees.Types;

type
  INodeData = interface
    ['{94376202-9372-4539-8112-BEE16D041A9C}']
    procedure Attach(TreeView: TVirtualStringTree; Node: PVirtualNode);
    function GetColumnText(Index: Integer): String;
    function GetHint: String;
    function GetColor(out ItemColor: TColor): Boolean;
    property Text[Index: Integer]: String read GetColumnText;
    property Hint: String read GetHint;
  end;

  TCustomNodeData = class (TInterfacedObject, INodeData)
  protected
    TreeView: TVirtualStringTree;
    Node: PVirtualNode;
    Cell: TArray<String>;
    Hint: String;
    HasColor: Boolean;
    Color: TColor;
    procedure Attach(TreeView: TVirtualStringTree; Node: PVirtualNode); virtual;
    function GetColumnText(Index: Integer): String; virtual;
    function GetHint: String; virtual;
    function GetColor(out ItemColor: TColor): Boolean; virtual;
  public
    constructor Create(ColumnCount: Integer); overload;
    constructor Create(ColumnText: TArray<String>; ItemHint: String = ''); overload;
    constructor Create(ColumnText: TArray<String>; ItemHint: String; BacgroundColor: TColor); overload;
  end;

  TVirtualNodeHelper = record helper for TVirtualNode
    function HasData: Boolean;
    function GetINodeData: INodeData;
    procedure SetINodeData(const Provider: INodeData);
  end;

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
  private
    FUseingINodeData: Boolean;
    procedure GetINodeCellText(Sender: TCustomVirtualStringTree;
      var E: TVSTGetCellTextEventArgs);
    procedure GetINodeHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
      var HintText: string);
    procedure DoINodeBeforeItemErase(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect;
      var ItemColor: TColor; var EraseAction: TItemEraseAction);
    procedure DoINodeCompare(Sender: TBaseVirtualTree; Node1,
      Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
  protected
    function CollectNodes(Nodes: TVTVirtualNodeEnumeration): TArray<PVirtualNode>;
    function DoGetPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Position: TPoint): TPopupMenu; override;
    procedure DoInitNode(Parent, Node: PVirtualNode; var InitStates: TVirtualNodeInitStates); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure UseINodeDataMode;
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

{ TCustomNodeData }

procedure TCustomNodeData.Attach;
begin
  Self.TreeView := TreeView;
  Self.Node := Node;
end;

constructor TCustomNodeData.Create(ColumnCount: Integer);
begin
  SetLength(Cell, ColumnCount);
end;

constructor TCustomNodeData.Create(ColumnText: TArray<String>; ItemHint: String);
begin
  Cell := ColumnText;
  Hint := ItemHint;
end;

constructor TCustomNodeData.Create(
  ColumnText: TArray<String>;
  ItemHint: String;
  BacgroundColor: TColor
);
begin
  Create(ColumnText, ItemHint);
  HasColor := True;
  Color := BacgroundColor;
end;

function TCustomNodeData.GetColor;
begin
  Result := HasColor;
  ItemColor := Color;
end;

function TCustomNodeData.GetColumnText;
begin
  if (Index >= Low(Cell)) and (Index <= High(Cell)) then
    Result := Cell[Index]
  else
    Result := '';
end;

function TCustomNodeData.GetHint;
begin
  Result := Hint;
end;

{ TVirtualNodeHelper }

function TVirtualNodeHelper.GetINodeData;
begin
  Result := INodeData(GetData^);
end;

function TVirtualNodeHelper.HasData;
begin
  Result := Assigned(@Self) and Assigned(Pointer(GetData^));
end;

procedure TVirtualNodeHelper.SetINodeData;
begin
  if HasData then
    GetINodeData._Release;

  SetData(IInterface(Provider));
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
  inherited;
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

procedure TVirtualStringTreeEx.DoInitNode;
begin
  // Pre-populate checkboxes by default when the feature is enabled
  if toCheckSupport in TreeOptions.MiscOptions then
    CheckType[Node] := ctCheckBox;

  if FUseingINodeData then
    Node.GetINodeData.Attach(Self, Node);

  inherited;
end;

procedure TVirtualStringTreeEx.DoINodeBeforeItemErase;
var
  NewColor: TColor;
begin
  if Node.GetINodeData.GetColor(NewColor) then
    ItemColor := NewColor;
end;

procedure TVirtualStringTreeEx.DoINodeCompare;
begin
  Result := String.Compare(Text[Node1, Column], Text[Node2, Column]);
end;

procedure TVirtualStringTreeEx.GetINodeCellText;
begin
  E.CellText := E.Node.GetINodeData.Text[E.Column];
end;

procedure TVirtualStringTreeEx.GetINodeHint;
begin
  HintText := Node.GetINodeData.Hint;
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

  if csDesigning in ComponentState then
    Exit;

  if Assigned(FNodePopupMenu) then
    AttachDefaultMenuItems(FNodePopupMenu)
  else
    AttachDefaultMenuItems(FDefaultMenu);
end;

procedure TVirtualStringTreeEx.UseINodeDataMode;
begin
  RootNodeCount := 0;
  NodeDataSize := SizeOf(INodeData);

  OnGetCellText := GetINodeCellText;
  OnGetHint := GetINodeHint;
  OnBeforeItemErase := DoINodeBeforeItemErase;
  OnCompareNodes := DoINodeCompare;
end;

end.
