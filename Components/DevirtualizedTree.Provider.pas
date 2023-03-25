unit DevirtualizedTree.Provider;

{
  This module defined the base class for creting node state providers for the
  devirtualized tree view.
}

interface

uses
  VirtualTrees, DevirtualizedTree, Vcl.Graphics;

type
  TNodeProvider = class (TInterfacedObject, INodeProvider)
  protected
    FTree: TBaseVirtualTree;
    FNode: PVirtualNode;
    FColumnText: TArray<String>;
    FHint: String;
    FHasColor: Boolean;
    FColor: TColor;
    FHasFontColor: Boolean;
    FFontColor: TColor;
    FHasFontStyle: Boolean;
    FFontStyle: TFontStyles;
    FEnabledInspectMenu: Boolean;
    FOnChecked: TVTChangeEvent;
    FPreviouslySelected, FPreviouslySelectedValid: Boolean;
    FOnSelected: TVTChangeEvent;

    function Attached: Boolean; virtual;
    procedure Attach(Value: PVirtualNode); virtual;
    procedure NotifyChecked; virtual;
    procedure NotifySelected; virtual;

    function GetTree: TBaseVirtualTree; virtual;
    function GetNode: PVirtualNode; virtual;
    function GetColumnText(Index: Integer): String; virtual;
    function GetHint: String; virtual;
    function GetColor: TColor; virtual;
    function GetHasColor: Boolean; virtual;
    function GetFontColor: TColor; virtual;
    function GetHasFontColor: Boolean; virtual;
    function GetFontStyle: TFontStyles; virtual;
    function GetHasFontStyle: Boolean; virtual;
    function GetEnabledInspectMenu: Boolean; virtual;
    function GetOnChecked: TVTChangeEvent; virtual;
    function GetOnSelected: TVTChangeEvent; virtual;
  public
    constructor Create(InitialColumnCount: Integer = 1);
    procedure Invalidate; virtual;
  end;

  IEditableNodeProvider = interface (INodeProvider)
    ['{C4211977-15A3-46FC-8935-30004824258F}']
    procedure Invalidate;

    procedure SetColumnText(Index: Integer; const Value: String);
    procedure SetHint(const Value: String);
    procedure SetColor(Value: TColor);
    procedure SetFontColor(Value: TColor);
    procedure SetFontStyle(Value: TFontStyles);
    procedure SetEnabledInspectMenu(Value: Boolean);
    procedure SetOnChecked(Value: TVTChangeEvent);
    procedure SetOnSelected(Value: TVTChangeEvent);

    procedure ResetColor;
    procedure ResetFontColor;
    procedure ResetFontStyle;

    property Tree: TBaseVirtualTree read GetTree;
    property Node: PVirtualNode read GetNode;
    property ColumnText[Index: Integer]: String read GetColumnText write SetColumnText;
    property Hint: String read GetHint write SetHint;
    property Color: TColor read GetColor write SetColor;
    property HasColor: Boolean read GetHasColor;
    property FontColor: TColor read GetFontColor write SetFontColor;
    property HasFontColor: Boolean read GetHasFontColor;
    property FontStyle: TFontStyles read GetFontStyle write SetFontStyle;
    property HasFontStyle: Boolean read GetHasFontStyle;
    property EnabledInspectMenu: Boolean read GetEnabledInspectMenu write SetEnabledInspectMenu;
    property OnChecked: TVTChangeEvent read GetOnChecked write SetOnChecked;
    property OnSelected: TVTChangeEvent read GetOnSelected write SetOnSelected;
  end;

  TEditableNodeProvider = class (TNodeProvider, IEditableNodeProvider)
  protected
    procedure SetColumnText(Index: Integer; const Value: String); virtual;
    procedure SetHint(const Value: String); virtual;
    procedure SetColor(Value: TColor); virtual;
    procedure SetFontColor(Value: TColor); virtual;
    procedure SetFontStyle(Value: TFontStyles); virtual;
    procedure SetEnabledInspectMenu(Value: Boolean); virtual;
    procedure SetOnChecked(Value: TVTChangeEvent); virtual;
    procedure SetOnSelected(Value: TVTChangeEvent); virtual;
    procedure ResetColor; virtual;
    procedure ResetFontColor; virtual;
    procedure ResetFontStyle; virtual;
  end;

implementation

{ TNodeProvider }

procedure TNodeProvider.Attach;
begin
  FNode := Value;

  if Assigned(Value) then
    FTree := TreeFromNode(Value)
  else
    FTree := nil;
end;

function TNodeProvider.Attached;
begin
  Result := Assigned(FTree) and Assigned(FNode);
end;

constructor TNodeProvider.Create;
begin
  inherited Create;
  SetLength(FColumnText, InitialColumnCount);
  FEnabledInspectMenu := True;
end;

function TNodeProvider.GetColor;
begin
  Result := FColor;
end;

function TNodeProvider.GetColumnText;
begin
  if (Index >= Low(FColumnText)) and (Index <= High(FColumnText)) then
    Result := FColumnText[Index]
  else
    Result := '';
end;

function TNodeProvider.GetEnabledInspectMenu;
begin
  Result := FEnabledInspectMenu;
end;

function TNodeProvider.GetFontColor;
begin
  Result := FFontColor;
end;

function TNodeProvider.GetFontStyle;
begin
  Result := FFontStyle;
end;

function TNodeProvider.GetHasColor;
begin
  Result := FHasColor;
end;

function TNodeProvider.GetHasFontColor;
begin
  Result := FHasFontColor;
end;

function TNodeProvider.GetHasFontStyle;
begin
  Result := FHasFontStyle;
end;

function TNodeProvider.GetHint;
begin
  Result := FHint;
end;

function TNodeProvider.GetNode;
begin
  Result := FNode;
end;

function TNodeProvider.GetOnChecked;
begin
  Result := FOnChecked;
end;

function TNodeProvider.GetOnSelected;
begin
  Result := FOnSelected;
end;

function TNodeProvider.GetTree;
begin
  Result := FTree;
end;

procedure TNodeProvider.Invalidate;
begin
  if Attached then
    FTree.InvalidateNode(FNode);
end;

procedure TNodeProvider.NotifyChecked;
begin
  if Assigned(FOnChecked) and Attached then
    FOnChecked(FTree, FNode);
end;

procedure TNodeProvider.NotifySelected;
begin
  if not Attached then
    Exit;

  // Check if selection actually changed
  if FPreviouslySelectedValid and
    not (FPreviouslySelected xor (vsSelected in FNode.States)) then
    Exit;

  FPreviouslySelectedValid := Assigned(FOnSelected);
  FPreviouslySelected := vsSelected in FNode.States;

  if Assigned(FOnSelected) then
    FOnSelected(FTree, FNode);
end;

{ TEditableNodeProvider }

procedure TEditableNodeProvider.ResetColor;
begin
  if not FHasColor then
    Exit;

  FHasColor := False;
  Invalidate;
end;

procedure TEditableNodeProvider.ResetFontColor;
begin
  if not FHasFontColor then
    Exit;

  FHasFontColor := False;
  Invalidate;
end;

procedure TEditableNodeProvider.ResetFontStyle;
begin
  if not FHasFontStyle then
    Exit;

  FHasFontStyle := False;
  Invalidate;
end;

procedure TEditableNodeProvider.SetColor;
begin
  if FHasColor and (FColor = Value) then
    Exit;

  FHasColor := True;
  FColor := Value;
  Invalidate;
end;

procedure TEditableNodeProvider.SetColumnText;
begin
  if (GetColumnText(Index) = Value) or (Index < Low(FColumnText)) then
    Exit;

  if Index > High(FColumnText) then
    SetLength(FColumnText, Index + 1);

  FColumnText[Index] := Value;
  Invalidate;
end;

procedure TEditableNodeProvider.SetEnabledInspectMenu;
begin
  FEnabledInspectMenu := Value;
end;

procedure TEditableNodeProvider.SetFontColor;
begin
  if FHasFontColor and (FFontColor = Value) then
    Exit;

  FHasFontColor := True;
  FFontColor := Value;
  Invalidate;
end;

procedure TEditableNodeProvider.SetFontStyle;
begin
  if FHasFontStyle and (FFontStyle = Value) then
    Exit;

  FHasFontStyle := True;
  FFontStyle := Value;
  Invalidate;
end;

procedure TEditableNodeProvider.SetHint;
begin
  if FHint <> Value then
    Exit;

  FHint := Value;
  Invalidate;
end;

procedure TEditableNodeProvider.SetOnChecked;
begin
  FOnChecked := Value;
end;

procedure TEditableNodeProvider.SetOnSelected;
begin
  FOnSelected := Value;
end;

end.
