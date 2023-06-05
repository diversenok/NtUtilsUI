unit DevirtualizedTree;

{
  This module offers a devirtualized tree view based on the virtual tree view
  where each node has a dedicated provider that customizes its appearance.
}

interface

uses
  VirtualTrees, VirtualTreesEx, Vcl.Graphics, System.Classes, System.Types;

type
  PVirtualNode = VirtualTrees.PVirtualNode;

  INodeProvider = interface
    ['{73CD9263-15D9-470E-937A-1EFDBBF60AF4}']
    procedure Attach(Node: PVirtualNode);
    procedure Detach;
    procedure Initialize;
    procedure Invalidate;
    procedure NotifyChecked;
    procedure NotifySelected;
    procedure NotifyExpanding(var HasChildren: Boolean);
    procedure NotifyCollapsing(var HasChildren: Boolean);
    function MatchesSearch(const Query: String; Column: TColumnIndex): Boolean;

    function GetTree: TBaseVirtualTree;
    function GetNode: PVirtualNode;
    function GetColumnText(Index: Integer): String;
    function GetHint: String;
    function GetColor: TColor;
    function GetHasColor: Boolean;
    function GetFontColor: TColor;
    function GetHasFontColor: Boolean;
    function GetFontStyle: TFontStyles;
    function GetHasFontStyle: Boolean;
    function GetEnabledInspectMenu: Boolean;

    property Tree: TBaseVirtualTree read GetTree;
    property Node: PVirtualNode read GetNode;
    property ColumnText[Index: Integer]: String read GetColumnText;
    property Hint: String read GetHint;
    property Color: TColor read GetColor;
    property HasColor: Boolean read GetHasColor;
    property FontColor: TColor read GetFontColor;
    property HasFontColor: Boolean read GetHasFontColor;
    property FontStyle: TFontStyles read GetFontStyle;
    property HasFontStyle: Boolean read GetHasFontStyle;
    property EnabledInspectMenu: Boolean read GetEnabledInspectMenu;
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
    procedure DoFreeNode(Node: PVirtualNode); override;
    procedure DoInitNode(Parent, Node: PVirtualNode; var InitStates: TVirtualNodeInitStates); override;
  public
    function OverrideInspectMenuEnabled(Node: PVirtualNode): Boolean; override;
    function AddChildEx(Parent: PVirtualNode; const Provider: INodeProvider): INodeProvider;
    function InsertNodeEx(Node: PVirtualNode; Mode: TVTNodeAttachMode; const Provider: INodeProvider): INodeProvider;
  end;

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
begin
  // Pre-load background color
  if Node.HasProvider and Node.Provider.HasColor then
    Color := Node.Provider.Color;

  inherited;
end;

procedure TDevirtualizedTree.DoChange;
begin
  inherited;

  if Assigned(Node) then
  begin
    // Use the supplied node when available

    if Node.HasProvider then
      Node.Provider.NotifySelected;
  end
  else
  begin
    // Cannot tell which node changed; need to notify all of them

    for Node in Nodes do
      if Node.HasProvider then
        Node.Provider.NotifySelected;
  end;
end;

procedure TDevirtualizedTree.DoChecked;
begin
  inherited;

  if Node.HasProvider then
    Node.Provider.NotifyChecked;
end;

function TDevirtualizedTree.DoCollapsing;
begin
  Result := inherited;

  if Node.HasProvider then
    Node.Provider.NotifyCollapsing(Result);
end;

function TDevirtualizedTree.DoExpanding;
begin
  Result := inherited;

  if Node.HasProvider then
    Node.Provider.NotifyExpanding(Result);
end;

procedure TDevirtualizedTree.DoFreeNode;
begin
  if Node.HasProvider then
    Node.Provider.Detach;

  inherited;
end;

function TDevirtualizedTree.DoGetNodeHint;
begin
  Result := inherited;

  // Override inherited hint with the one provided by the node
  if not Assigned(OnGetHint) and Node.HasProvider then
    Result := Node.Provider.Hint;
end;

procedure TDevirtualizedTree.DoGetText;
begin
  // (Copied initialization from the parent)
  if not (vsInitialized in pEventArgs.Node.States) then
    InitNode(pEventArgs.Node);

  // Pre-load the text
  if pEventArgs.Node.HasProvider then
    pEventArgs.CellText := pEventArgs.Node.Provider.ColumnText[
      pEventArgs.Column];

  inherited;
end;

procedure TDevirtualizedTree.DoInitNode;
begin
  inherited;

  if Node.HasProvider then
    Node.Provider.Initialize;
end;

procedure TDevirtualizedTree.DoPaintText;
begin
  // Pre-load font styles
  if (TextType = ttNormal) and Node.HasProvider then
  begin
    if Node.Provider.HasFontColor then
      Canvas.Font.Color := Node.Provider.FontColor;

    if Node.Provider.HasFontStyle then
      Canvas.Font.Style := Node.Provider.FontStyle;
  end;

  inherited;
end;

procedure TDevirtualizedTree.DoRemoveFromSelection;
begin
  inherited;

  // Note: do not invoke events on a half-destroyed form
  if not (csDestroying in ComponentState) and Node.HasProvider then
    Node.Provider.NotifySelected;
end;

function TDevirtualizedTree.InsertNodeEx;
begin
  Assert(Assigned(Provider), 'Provider must not be null');
  Provider.Attach(inherited InsertNode(Node, Mode, Pointer(IInterface(Provider))));
  Result := Provider;
end;

function TDevirtualizedTree.OverrideInspectMenuEnabled;
begin
  if Node.HasProvider and not Node.Provider.EnabledInspectMenu then
    Result := False
  else
    Result := inherited;
end;

procedure TDevirtualizedTree.ValidateNodeDataSize;
begin
  inherited;
  Size := SizeOf(INodeProvider);
end;

end.
