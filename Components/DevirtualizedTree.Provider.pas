unit DevirtualizedTree.Provider;

{
  This module defined the base class for creting node state providers for the
  devirtualized tree view.
}

interface

uses
  VirtualTrees, DevirtualizedTree, Vcl.Graphics;

type
  TCustomNodeProvider = class (TInterfacedObject, INodeProvider)
  protected
    Tree: TBaseVirtualTree;
    Node: PVirtualNode;
    Cells: TArray<String>;
    Hint: String;
    HasColor: Boolean;
    Color: TColor;
    HasFontColor: Boolean;
    FontColor: TColor;
    HasFontStyle: Boolean;
    FontStyle: TFontStyles;
    EnabledInspectMenu: Boolean;
    OnChecked: TVTChangeEvent;
    WasSelected, KnownWasSelected: Boolean;
    OnSelected: TVTChangeEvent;
    procedure Invalidate; virtual;
    procedure Attach(Value: PVirtualNode); virtual;
    function GetTree: TBaseVirtualTree; virtual;
    function GetNode: PVirtualNode; virtual;
    function GetColumn(Index: Integer): String; virtual;
    procedure SetColumn(Index: Integer; const Value: String); virtual;
    function GetHint: String; virtual;
    procedure SetHint(const Value: String); virtual;
    function GetColor: TColor; virtual;
    procedure SetColor(Value: TColor); virtual;
    function GetHasColor: Boolean; virtual;
    procedure ResetColor; virtual;
    function GetFontColor: TColor; virtual;
    procedure SetFontColor(Value: TColor); virtual;
    function GetHasFontColor: Boolean; virtual;
    procedure ResetFontColor; virtual;
    function GetFontStyle: TFontStyles; virtual;
    procedure SetFontStyle(Value: TFontStyles); virtual;
    function GetHasFontStyle: Boolean; virtual;
    procedure ResetFontStyle; virtual;
    function GetEnabledInspectMenu: Boolean; virtual;
    procedure SetEnabledInspectMenu(Value: Boolean); virtual;
    function GetOnChecked: TVTChangeEvent; virtual;
    procedure SetOnChecked(Value: TVTChangeEvent); virtual;
    procedure NotifyChecked; virtual;
    function GetOnSelected: TVTChangeEvent; virtual;
    procedure SetOnSelected(Value: TVTChangeEvent); virtual;
    procedure NotifySelected; virtual;
  public
    constructor Create(InitialColumnCount: Integer = 1);
  end;

implementation

{ TCustomNodeProvider }

procedure TCustomNodeProvider.Attach;
begin
  Node := Value;

  if Assigned(Value) then
    Tree := TreeFromNode(Value)
  else
    Tree := nil;
end;

constructor TCustomNodeProvider.Create;
begin
  SetLength(Cells, InitialColumnCount);
  EnabledInspectMenu := True;
end;

function TCustomNodeProvider.GetColor;
begin
  Result := Color;
end;

function TCustomNodeProvider.GetColumn;
begin
  if (Index >= Low(Cells)) and (Index <= High(Cells)) then
    Result := Cells[Index]
  else
    Result := '';
end;

function TCustomNodeProvider.GetEnabledInspectMenu;
begin
  Result := EnabledInspectMenu;
end;

function TCustomNodeProvider.GetFontColor;
begin
  Result := FontColor;
end;

function TCustomNodeProvider.GetFontStyle;
begin
  Result := FontStyle;
end;

function TCustomNodeProvider.GetHasColor;
begin
  Result := HasColor;
end;

function TCustomNodeProvider.GetHasFontColor;
begin
  Result := HasFontColor;
end;

function TCustomNodeProvider.GetHasFontStyle;
begin
  Result := HasFontStyle;
end;

function TCustomNodeProvider.GetHint;
begin
  Result := Hint;
end;

function TCustomNodeProvider.GetNode;
begin
  Result := Node;
end;

function TCustomNodeProvider.GetOnChecked;
begin
  Result := OnChecked;
end;

function TCustomNodeProvider.GetOnSelected;
begin
  Result := OnSelected;
end;

function TCustomNodeProvider.GetTree;
begin
  Result := Tree;
end;

procedure TCustomNodeProvider.Invalidate;
begin
  if Assigned(Tree) then
    Tree.InvalidateNode(Node);
end;

procedure TCustomNodeProvider.NotifyChecked;
begin
  if Assigned(OnChecked) then
    OnChecked(Tree, Node);
end;

procedure TCustomNodeProvider.NotifySelected;
begin
  // Check if selection actually changed
  if KnownWasSelected and not (WasSelected xor (vsSelected in Node.States)) then
    Exit;

  KnownWasSelected := Assigned(OnSelected);
  WasSelected := vsSelected in Node.States;

  if Assigned(OnSelected) then
    OnSelected(Tree, Node);
end;

procedure TCustomNodeProvider.ResetColor;
begin
  if not HasColor then
    Exit;

  HasColor := False;
  Invalidate;
end;

procedure TCustomNodeProvider.ResetFontColor;
begin
  if not HasFontColor then
    Exit;

  HasFontColor := False;
  Invalidate;
end;

procedure TCustomNodeProvider.ResetFontStyle;
begin
  if not HasFontStyle then
    Exit;

  HasFontStyle := False;
  Invalidate;
end;

procedure TCustomNodeProvider.SetColor;
begin
  if HasColor and (Color = Value) then
    Exit;

  HasColor := True;
  Color := Value;
  Invalidate;
end;

procedure TCustomNodeProvider.SetColumn;
begin
  if (GetColumn(Index) = Value) or (Index < Low(Cells)) then
    Exit;

  if Index > High(Cells) then
    SetLength(Cells, Index + 1);

  Cells[Index] := Value;
  Invalidate;
end;

procedure TCustomNodeProvider.SetEnabledInspectMenu;
begin
  EnabledInspectMenu := Value;  
end;

procedure TCustomNodeProvider.SetFontColor;
begin
  if HasFontColor and (FontColor = Value) then
    Exit;

  HasFontColor := True;
  FontColor := Value;
  Invalidate;
end;

procedure TCustomNodeProvider.SetFontStyle;
begin
  if HasFontStyle and (FontStyle = Value) then
    Exit;

  HasFontStyle := True;
  FontStyle := Value;
  Invalidate;
end;

procedure TCustomNodeProvider.SetHint;
begin
  if Hint <> Value then
    Exit;

  Hint := Value;
  Invalidate;
end;

procedure TCustomNodeProvider.SetOnChecked;
begin
  OnChecked := Value;
end;

procedure TCustomNodeProvider.SetOnSelected;
begin
  OnSelected := Value;
end;

end.
