unit VirtualTreesEx;

interface

uses
  System.SysUtils, System.Classes, System.Types, Vcl.Menus,
  Vcl.Graphics, VirtualTrees, VirtualTrees.Types, VirtualTreesEx.DefaultMenu;

type
  INodeProvider = interface
    ['{E9C3AFD4-FDCA-45E5-9DD3-7CD027E0AC1D}']
    procedure Invalidate;
    procedure Attach(Node: PVirtualNode);
    function GetColumn(Index: Integer): String;
    procedure SetColumn(Index: Integer; const Value: String);
    function GetHint: String;
    procedure SetHint(const Value: String);
    function GetColor(out ItemColor: TColor): Boolean;
    procedure SetColor(Value: TColor);
    procedure ResetColor;

    property Column[Index: Integer]: String read GetColumn write SetColumn;
    property Hint: String read GetHint write SetHint;
  end;

  TVirtualNodeHelper = record helper for TVirtualNode
    function HasProvider: Boolean;
    function GetProvider: INodeProvider;
    procedure SetProvider(const Provider: INodeProvider);
  end;

  TNodeEvent = VirtualTreesEx.DefaultMenu.TNodeEvent;

  TVirtualStringTreeEx = class(TVirtualStringTree)
  private
    FDefaultMenus: TDefaultTreeMenu;
    FNodePopupMenu: TPopupMenu;
    procedure SetNodePopupMenu(const Value: TPopupMenu);
  private
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
    function GetOnInspectNode: TNodeEvent;
    procedure SetOnInspectNode(const Value: TNodeEvent);
  protected
    function CollectNodes(Nodes: TVTVirtualNodeEnumeration): TArray<PVirtualNode>;
    function DoGetPopupMenu(Node: PVirtualNode; Column: TColumnIndex; Position: TPoint): TPopupMenu; override;
    procedure DoInitNode(Parent, Node: PVirtualNode; var InitStates: TVirtualNodeInitStates); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure UseINodeDataMode;
  published
    property OnInspectNode: TNodeEvent read GetOnInspectNode write SetOnInspectNode;
    property NodePopupMenu: TPopupMenu read FNodePopupMenu write SetNodePopupMenu;
  end;

procedure Register;

implementation

uses
  Winapi.Windows;

procedure Register;
begin
  RegisterComponents('Virtual Controls', [TVirtualStringTreeEx]);
end;

{ TVirtualNodeHelper }

function TVirtualNodeHelper.GetProvider;
begin
  Result := INodeProvider(GetData^);
end;

function TVirtualNodeHelper.HasProvider;
begin
  Result := Assigned(@Self) and Assigned(Pointer(GetData^));
end;

procedure TVirtualNodeHelper.SetProvider;
begin
  if HasProvider then
    GetProvider._Release;

  SetData(IInterface(Provider));
  Provider.Attach(@Self);
end;

{ TVirtualStringTreeEx }

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

  // Always include a menu for copying and inspecting items
  FDefaultMenus := TDefaultTreeMenu.Create(Self);
end;

procedure TVirtualStringTreeEx.DblClick;
begin
  inherited;
  FDefaultMenus.InvokeInspect;
end;

destructor TVirtualStringTreeEx.Destroy;
begin
  FDefaultMenus.Free;
  inherited;
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

procedure TVirtualStringTreeEx.DoINodeBeforeItemErase;
var
  NewColor: TColor;
begin
  if Node.GetProvider.GetColor(NewColor) then
    ItemColor := NewColor;
end;

procedure TVirtualStringTreeEx.DoINodeCompare;
begin
  Result := String.Compare(Text[Node1, Column], Text[Node2, Column]);
end;

procedure TVirtualStringTreeEx.GetINodeCellText;
begin
  E.CellText := E.Node.GetProvider.Column[E.Column];
end;

procedure TVirtualStringTreeEx.GetINodeHint;
begin
  HintText := Node.GetProvider.Hint;
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

procedure TVirtualStringTreeEx.UseINodeDataMode;
begin
  RootNodeCount := 0;
  NodeDataSize := SizeOf(INodeProvider);

  OnGetCellText := GetINodeCellText;
  OnGetHint := GetINodeHint;
  OnBeforeItemErase := DoINodeBeforeItemErase;
  OnCompareNodes := DoINodeCompare;
end;

end.
