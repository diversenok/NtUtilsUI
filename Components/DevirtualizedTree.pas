unit DevirtualizedTree;

{
  This module offers a devirtualized tree view based on the virtual tree view
  where each node has a dedicated provider that customizes its appearance.
}

interface

uses
  VirtualTrees, VirtualTreesEx, Vcl.Graphics, Vcl.Controls,
  System.Classes, System.Types;

type
  PVirtualNode = VirtualTrees.PVirtualNode;

  INodeProvider = interface
    ['{05550C04-3529-49CC-9D3B-A3A7AEF2BFBC}']
    procedure Attach(Node: PVirtualNode);
    procedure Detach;
    procedure Initialize;
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
    procedure DoGetCursor(var Cursor: TCursor); override;
    procedure DoFreeNode(Node: PVirtualNode); override;
    procedure DoInitNode(Parent, Node: PVirtualNode; var InitStates: TVirtualNodeInitStates); override;
  public
    function OverrideMainActionMenuEnabled(Node: PVirtualNode): Boolean; override;
    function AddChildEx(Parent: PVirtualNode; const Provider: INodeProvider): INodeProvider;
    function InsertNodeEx(Node: PVirtualNode; Mode: TVTNodeAttachMode; const Provider: INodeProvider): INodeProvider;
  end;

// Collect node providers from node enumerator
function CollectNodeProviders(
  const NodeEnumeration: TVTVirtualNodeEnumeration;
  const ProviderId: TGuid
): TArray<INodeProvider>;

procedure Register;

implementation

uses
  Winapi.Windows, System.SysUtils;

procedure Register;
begin
  RegisterComponents('Virtual Controls', [TDevirtualizedTree]);
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

{ TDevirtualizedTree }

function TDevirtualizedTree.AddChildEx;
begin
  Assert(Assigned(Provider), 'Provider must not be null');
  Provider.Attach(inherited AddChild(Parent, IInterface(Provider)));
  Result := Provider;
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

end.
