unit DevirtualizedTree;

{
  This module offers a devirtualized tree view based on the virtual tree view
  where each node has a dedicated provider that customizes its appearance.
}

interface

uses
  VirtualTrees, VirtualTreesEx, Vcl.Graphics, System.Classes, System.Types;

type
  INodeProvider = interface
    ['{714EBDFA-74FD-4549-927D-E605E277E5A5}']
    procedure Invalidate;
    procedure Attach(Node: PVirtualNode);

    // Property providers
    function GetTree: TBaseVirtualTree;
    function GetNode: PVirtualNode;
    function GetColumn(Index: Integer): String;
    procedure SetColumn(Index: Integer; const Value: String);
    function GetHint: String;
    procedure SetHint(const Value: String);
    function GetColor: TColor;
    procedure SetColor(Value: TColor);
    function GetHasColor: Boolean;
    function GetFontColor: TColor;
    procedure SetFontColor(Value: TColor);
    function GetHasFontColor: Boolean;
    function GetFontStyle: TFontStyles;
    procedure SetFontStyle(Value: TFontStyles);
    function GetHasFontStyle: Boolean;
    function GetEnabledInspectMenu: Boolean;
    procedure SetEnabledInspectMenu(Value: Boolean);
    function GetOnChecked: TVTChangeEvent;
    procedure SetOnChecked(Value: TVTChangeEvent);
    function GetOnSelected: TVTChangeEvent;
    procedure SetOnSelected(Value: TVTChangeEvent);

    property Tree: TBaseVirtualTree read GetTree;
    property Node: PVirtualNode read GetNode;
    property Column[Index: Integer]: String read GetColumn write SetColumn;
    property Hint: String read GetHint write SetHint;
    property Color: TColor read GetColor write SetColor;
    property HasColor: Boolean read GetHasColor;
    procedure ResetColor;
    property FontColor: TColor read GetFontColor write SetFontColor;
    property HasFontColor: Boolean read GetHasFontColor;
    procedure ResetFontColor;
    property FontStyle: TFontStyles read GetFontStyle write SetFontStyle;
    property HasFontStyle: Boolean read GetHasFontStyle;
    procedure ResetFontStyle;
    property EnabledInspectMenu: Boolean read GetEnabledInspectMenu write SetEnabledInspectMenu;
    property OnChecked: TVTChangeEvent read GetOnChecked write SetOnChecked;
    procedure NotifyChecked;
    property OnSelected: TVTChangeEvent read GetOnSelected write SetOnSelected;
    procedure NotifySelected;
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
  public
    function OverrideInspectMenuEnabled(Node: PVirtualNode): Boolean; override;
    function AddChild(Parent: PVirtualNode; const Provider: INodeProvider): PVirtualNode; overload;
    function InsertNode(Node: PVirtualNode; Mode: TVTNodeAttachMode; const Provider: INodeProvider): PVirtualNode; overload;
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

function TDevirtualizedTree.AddChild(
  Parent: PVirtualNode;
  const Provider: INodeProvider
): PVirtualNode;
begin
  Assert(Assigned(Provider), 'Provider must not be null');
  Result := inherited AddChild(Parent, IInterface(Provider));
  Provider.Attach(Result);
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
    pEventArgs.CellText := pEventArgs.Node.Provider.Column[pEventArgs.Column];

  inherited;
end;

procedure TDevirtualizedTree.DoPaintText(Node: PVirtualNode;
  const Canvas: TCanvas; Column: TColumnIndex; TextType: TVSTTextType);
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

function TDevirtualizedTree.InsertNode(
  Node: PVirtualNode;
  Mode: TVTNodeAttachMode;
  const Provider: INodeProvider
): PVirtualNode;
begin
  Assert(Assigned(Provider), 'Provider must not be null');
  Result := inherited InsertNode(Node, Mode, Pointer(IInterface(Provider)));
  Provider.Attach(Result);
end;

function TDevirtualizedTree.OverrideInspectMenuEnabled;
begin
  if Node.HasProvider and not Node.Provider.EnabledInspectMenu then
    Result := False
  else
    Result := inherited;
end;

procedure TDevirtualizedTree.ValidateNodeDataSize(var Size: Integer);
begin
  inherited;
  Size := SizeOf(INodeProvider);
end;

end.
