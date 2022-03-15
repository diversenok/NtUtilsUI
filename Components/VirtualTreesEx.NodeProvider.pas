unit VirtualTreesEx.NodeProvider;

interface

uses
  VirtualTrees, VirtualTreesEx, Vcl.Graphics, DelphiUtils.AutoEvents;

type
  TCustomNodeProvider = class (TInterfacedObject, INodeProvider)
  protected
    FTree: TBaseVirtualTree;
    FNode: PVirtualNode;
    FColumns: TArray<String>;
    FHint: String;
    FHasColor: Boolean;
    FColor: TColor;
    procedure Invalidate; virtual;
    procedure Attach(Node: PVirtualNode); virtual;
    function GetColumn(Index: Integer): String; virtual;
    procedure SetColumn(Index: Integer; const Value: String); virtual;
    function GetHint: String; virtual;
    procedure SetHint(const Value: String); virtual;
    function GetColor(out ItemColor: TColor): Boolean; virtual;
    procedure SetColor(Value: TColor); virtual;
    procedure ResetColor; virtual;
  public
    constructor Create(ColumnCount: Integer); overload;
    constructor Create(ColumnText: TArray<String>; ItemHint: String = ''); overload;
    constructor Create(ColumnText: TArray<String>; ItemHint: String; BackgroundColor: TColor); overload;
  end;

implementation

{ TCustomNodeProvider }

procedure TCustomNodeProvider.Attach;
begin
  FNode := Node;

  if Assigned(Node) then
    FTree := TreeFromNode(Node)
  else
    FTree := nil;
end;

constructor TCustomNodeProvider.Create(ColumnCount: Integer);
begin
  SetLength(FColumns, ColumnCount);
end;

constructor TCustomNodeProvider.Create(ColumnText: TArray<String>;
  ItemHint: String);
begin
  FColumns := ColumnText;
  FHint := ItemHint;
end;

constructor TCustomNodeProvider.Create(ColumnText: TArray<String>;
  ItemHint: String; BackgroundColor: TColor);
begin
  FColumns := ColumnText;
  FHint := ItemHint;
  FHasColor := True;
  FColor := BackgroundColor;
end;

function TCustomNodeProvider.GetColor;
begin
  Result := FHasColor;
  ItemColor := FColor;
end;

function TCustomNodeProvider.GetColumn;
begin
  if (Index >= Low(FColumns)) and (Index <= High(FColumns)) then
    Result := FColumns[Index]
  else
    Result := '';
end;

function TCustomNodeProvider.GetHint;
begin
  Result := FHint;
end;

procedure TCustomNodeProvider.Invalidate;
begin
  if Assigned(FTree) then
    FTree.InvalidateNode(FNode);
end;

procedure TCustomNodeProvider.ResetColor;
begin
  if not FHasColor then
    Exit;

  FHasColor := False;
  Invalidate;
end;

procedure TCustomNodeProvider.SetColor;
begin
  if FHasColor and (FColor = Value) then
    Exit;

  FHasColor := True;
  FColor := Value;
  Invalidate;
end;

procedure TCustomNodeProvider.SetColumn;
begin
  if (GetColumn(Index) = Value) or (Index < Low(FColumns)) then
    Exit;

  if Index > High(FColumns) then
    SetLength(FColumns, Index + 1);

  FColumns[Index] := Value;
  Invalidate;
end;

procedure TCustomNodeProvider.SetHint;
begin
  if FHint <> Value then
    Exit;

  FHint := Value;
  Invalidate;
end;

end.
