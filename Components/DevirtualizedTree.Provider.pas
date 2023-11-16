unit DevirtualizedTree.Provider;

{
  This module defined the base class for creating node state providers for the
  devirtualized tree view.
}

interface

uses
  VirtualTrees, DevirtualizedTree, Vcl.Graphics, Vcl.Controls;

type
  TDVTChangeEvent = procedure(
    Sender: TDevirtualizedTree;
    Node: PVirtualNode
  ) of object;

  TNodeProvider = class (TInterfacedObject, INodeProvider)
  protected
    FTree: TDevirtualizedTree;
    FNode: PVirtualNode;
    FInitialized: Boolean;
    FColumnText: TArray<String>;
    FHint: String;
    FHasColor: Boolean;
    FColor: TColor;
    FHasFontColor: Boolean;
    FFontColor: TColor;
    FHasFontColorForColumn: TArray<Boolean>;
    FFontColorForColumn: TArray<TColor>;
    FHasFontStyle: Boolean;
    FFontStyle: TFontStyles;
    FHasFontStyleForColumn: TArray<Boolean>;
    FFontStyleForColumn: TArray<TFontStyles>;
    FEnabledMainActionMenu: Boolean;
    FHasCursor: Boolean;
    FCursor: TCursor;

    function Attached: Boolean; virtual;
    procedure Attach(Value: PVirtualNode); virtual;
    procedure Detach; virtual;
    procedure Initialize; virtual;
    procedure Invalidate; virtual;
    procedure NotifyChecked; virtual;
    procedure NotifySelected; virtual;
    procedure NotifyExpanding(var HasChildren: Boolean); virtual;
    procedure NotifyCollapsing(var HasChildren: Boolean); virtual;
    function MatchesSearch(const Query: String; Column: TColumnIndex): Boolean; virtual;

    function GetTree: TBaseVirtualTree; virtual;
    function GetNode: PVirtualNode; virtual;
    function GetColumnText(Column: TColumnIndex): String; virtual;
    function GetHint: String; virtual;
    function GetHasColor: Boolean; virtual;
    function GetColor: TColor; virtual;
    function GetHasFontColor: Boolean; virtual;
    function GetFontColor: TColor; virtual;
    function GetHasFontColorForColumn(Column: TColumnIndex): Boolean; virtual;
    function GetFontColorForColumn(Column: TColumnIndex): TColor; virtual;
    function GetHasFontStyle: Boolean; virtual;
    function GetFontStyle: TFontStyles; virtual;
    function GetHasFontStyleForColumn(Column: TColumnIndex): Boolean; virtual;
    function GetFontStyleForColumn(Column: TColumnIndex): TFontStyles; virtual;
    function GetHasCursor: Boolean; virtual;
    function GetCursor: TCursor; virtual;
    function GetEnabledMainActionMenu: Boolean; virtual;
  public
    constructor Create(InitialColumnCount: Integer = 1);
  end;

  IEditableNodeProvider = interface (INodeProvider)
    ['{52A18D6F-5E69-4EEC-9C69-DC21202329CD}']

    procedure SetColumnText(Column: TColumnIndex; const Value: String);
    procedure SetHint(const Value: String);
    procedure SetColor(Value: TColor);
    procedure SetFontColor(Value: TColor);
    procedure SetFontColorForColumn(Column: TColumnIndex; Value: TColor);
    procedure SetFontStyle(Value: TFontStyles);
    procedure SetFontStyleForColumn(Column: TColumnIndex; Value: TFontStyles);
    procedure SetEnabledMainActionMenu(Value: Boolean);
    procedure SetCursor(Value: TCursor);

    procedure ResetColor;
    procedure ResetFontColor;
    procedure ResetFontColorForColumn(Column: TColumnIndex);
    procedure ResetFontStyle;
    procedure ResetFontStyleForColumn(Column: TColumnIndex);
    procedure ResetCursor;

    function GetOnAttach: TDVTChangeEvent;
    function GetOnDetach: TDVTChangeEvent;
    function GetOnChecked: TDVTChangeEvent;
    function GetOnSelected: TDVTChangeEvent;
    function GetOnExpanding: TDVTChangeEvent;
    function GetOnCollapsing: TDVTChangeEvent;
    procedure SetOnAttach(Value: TDVTChangeEvent);
    procedure SetOnDetach(Value: TDVTChangeEvent);
    procedure SetOnChecked(Value: TDVTChangeEvent);
    procedure SetOnSelected(Value: TDVTChangeEvent);
    procedure SetOnExpanding(Value: TDVTChangeEvent);
    procedure SetOnCollapsing(Value: TDVTChangeEvent);

    property Tree: TBaseVirtualTree read GetTree;
    property Node: PVirtualNode read GetNode;
    property ColumnText[Column: TColumnIndex]: String read GetColumnText write SetColumnText;
    property Hint: String read GetHint write SetHint;
    property HasColor: Boolean read GetHasColor;
    property Color: TColor read GetColor write SetColor;
    property HasFontColor: Boolean read GetHasFontColor;
    property FontColor: TColor read GetFontColor write SetFontColor;
    property HasFontColorForColumn[Column: TColumnIndex]: Boolean read GetHasFontColorForColumn;
    property FontColorForColumn[Column: TColumnIndex]: TColor read GetFontColorForColumn write SetFontColorForColumn;
    property HasFontStyle: Boolean read GetHasFontStyle;
    property FontStyle: TFontStyles read GetFontStyle write SetFontStyle;
    property HasFontStyleForColumn[Column: TColumnIndex]: Boolean read GetHasFontStyleForColumn;
    property FontStyleForColumn[Column: TColumnIndex]: TFontStyles read GetFontStyleForColumn write SetFontStyleForColumn;
    property HasCursor: Boolean read GetHasCursor;
    property Cursor: TCursor read GetCursor write SetCursor;
    property EnabledMainActionMenu: Boolean read GetEnabledMainActionMenu write SetEnabledMainActionMenu;
    property OnAttach: TDVTChangeEvent read GetOnAttach write SetOnAttach;
    property OnDetach: TDVTChangeEvent read GetOnDetach write SetOnDetach;
    property OnChecked: TDVTChangeEvent read GetOnChecked write SetOnChecked;
    property OnSelected: TDVTChangeEvent read GetOnSelected write SetOnSelected;
    property OnExpanding: TDVTChangeEvent read GetOnExpanding write SetOnExpanding;
    property OnCollapsing: TDVTChangeEvent read GetOnCollapsing write SetOnCollapsing;
  end;

  TEditableNodeProvider = class (TNodeProvider, IEditableNodeProvider)
  protected
    FOnAttach: TDVTChangeEvent;
    FOnDetach: TDVTChangeEvent;
    FOnChecked: TDVTChangeEvent;
    FOnSelected: TDVTChangeEvent;
    FOnExpanding, FOnCollapsing: TDVTChangeEvent;
    FPreviouslySelected, FPreviouslySelectedValid: Boolean;

    procedure SetColumnText(Column: TColumnIndex; const Value: String); virtual;
    procedure SetHint(const Value: String); virtual;
    procedure SetColor(Value: TColor); virtual;
    procedure SetFontColor(Value: TColor); virtual;
    procedure SetFontColorForColumn(Column: TColumnIndex; Value: TColor); virtual;
    procedure SetFontStyle(Value: TFontStyles); virtual;
    procedure SetFontStyleForColumn(Column: TColumnIndex; Value: TFontStyles); virtual;
    procedure SetEnabledMainActionMenu(Value: Boolean); virtual;
    procedure SetCursor(Value: TCursor); virtual;

    procedure ResetColor; virtual;
    procedure ResetFontColor; virtual;
    procedure ResetFontColorForColumn(Column: TColumnIndex); virtual;
    procedure ResetFontStyle; virtual;
    procedure ResetFontStyleForColumn(Column: TColumnIndex); virtual;
    procedure ResetCursor; virtual;

    function GetOnAttach: TDVTChangeEvent; virtual;
    function GetOnDetach: TDVTChangeEvent; virtual;
    function GetOnChecked: TDVTChangeEvent; virtual;
    function GetOnSelected: TDVTChangeEvent; virtual;
    function GetOnExpanding: TDVTChangeEvent; virtual;
    function GetOnCollapsing: TDVTChangeEvent; virtual;
    procedure SetOnAttach(Value: TDVTChangeEvent); virtual;
    procedure SetOnDetach(Value: TDVTChangeEvent); virtual;
    procedure SetOnChecked(Value: TDVTChangeEvent); virtual;
    procedure SetOnSelected(Value: TDVTChangeEvent); virtual;
    procedure SetOnExpanding(Value: TDVTChangeEvent); virtual;
    procedure SetOnCollapsing(Value: TDVTChangeEvent); virtual;

    procedure Attach(Value: PVirtualNode); override;
    procedure Detach; override;
    procedure NotifyChecked; override;
    procedure NotifySelected; override;
    procedure NotifyExpanding(var HasChildren: Boolean); override;
    procedure NotifyCollapsing(var HasChildren: Boolean); override;
  end;

implementation

uses
  System.SysUtils;

{ TNodeProvider }

procedure TNodeProvider.Attach;
var
  FBaseTree: TBaseVirtualTree;
begin
  FNode := Value;

  if Assigned(Value) then
  begin
    FBaseTree := TreeFromNode(Value);

    if FBaseTree is TDevirtualizedTree then
      FTree :=  TDevirtualizedTree(FBaseTree);
  end
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
  FEnabledMainActionMenu := True;
end;

procedure TNodeProvider.Detach;
begin
  FNode := nil;
  FTree := nil;
end;

function TNodeProvider.GetColor;
begin
  Result := FColor;
end;

function TNodeProvider.GetColumnText;
begin
  if (Column >= Low(FColumnText)) and (Column <= High(FColumnText)) then
    Result := FColumnText[Column]
  else
    Result := '';
end;

function TNodeProvider.GetCursor;
begin
  Result := FCursor;
end;

function TNodeProvider.GetEnabledMainActionMenu;
begin
  Result := FEnabledMainActionMenu;
end;

function TNodeProvider.GetFontColor;
begin
  Result := FFontColor;
end;

function TNodeProvider.GetFontColorForColumn;
begin
  if (Column >= Low(FFontColorForColumn)) and
    (Column <= High(FFontColorForColumn)) then
    Result := FFontColorForColumn[Column]
  else
    Result := clBlack;
end;

function TNodeProvider.GetFontStyle;
begin
  Result := FFontStyle;
end;

function TNodeProvider.GetFontStyleForColumn;
begin
  if (Column >= Low(FFontStyleForColumn)) and
    (Column <= High(FFontStyleForColumn)) then
    Result := FFontStyleForColumn[Column]
  else
    Result := [];
end;

function TNodeProvider.GetHasColor;
begin
  Result := FHasColor;
end;

function TNodeProvider.GetHasCursor;
begin
  Result := FHasCursor;
end;

function TNodeProvider.GetHasFontColor;
begin
  Result := FHasFontColor;
end;

function TNodeProvider.GetHasFontColorForColumn;
begin
  Result := (Column >= Low(FHasFontColorForColumn)) and
    (Column <= High(FHasFontColorForColumn)) and FHasFontColorForColumn[Column];
end;

function TNodeProvider.GetHasFontStyle;
begin
  Result := FHasFontStyle;
end;

function TNodeProvider.GetHasFontStyleForColumn;
begin
  Result := (Column >= Low(FHasFontStyleForColumn)) and
    (Column <= High(FHasFontStyleForColumn)) and FHasFontStyleForColumn[Column];
end;

function TNodeProvider.GetHint;
begin
  Result := FHint;
end;

function TNodeProvider.GetNode;
begin
  Result := FNode;
end;

function TNodeProvider.GetTree;
begin
  Result := FTree;
end;

procedure TNodeProvider.Initialize;
begin
  FInitialized := True;
end;

procedure TNodeProvider.Invalidate;
begin
  if Attached then
    FTree.InvalidateNode(FNode);
end;

function TNodeProvider.MatchesSearch;
var
  QueryLowercase: string;
  i: TVirtualTreeColumn;
begin
  QueryLowercase := Query.ToLower;

  // Single-column queries
  if Column >= 0 then
    Exit(GetColumnText(Column).ToLower.Contains(QueryLowercase));

  // Multi-column queries require at least one visible column to match
  if Attached then
    for i in FTree.Header.Columns.GetVisibleColumns do
      if GetColumnText(i.Index).ToLower.Contains(QueryLowercase) then
        Exit(True);

  Result := False;
end;

procedure TNodeProvider.NotifyChecked;
begin
end;

procedure TNodeProvider.NotifyCollapsing;
begin
end;

procedure TNodeProvider.NotifyExpanding;
begin
end;

procedure TNodeProvider.NotifySelected;
begin
end;

{ TEditableNodeProvider }

procedure TEditableNodeProvider.Attach;
begin
  inherited;

  if Assigned(FOnAttach) and Attached then
    FOnAttach(FTree, FNode);
end;

procedure TEditableNodeProvider.Detach;
begin
  if Assigned(FOnDetach) and Attached then
    FOnDetach(FTree, FNode);

  inherited;
end;

function TEditableNodeProvider.GetOnAttach;
begin
  Result := FOnAttach;
end;

function TEditableNodeProvider.GetOnChecked;
begin
  Result := FOnChecked;
end;

function TEditableNodeProvider.GetOnCollapsing;
begin
  Result := FOnCollapsing;
end;

function TEditableNodeProvider.GetOnDetach;
begin
  Result := FOnDetach;
end;

function TEditableNodeProvider.GetOnExpanding;
begin
  Result := FOnExpanding;
end;

function TEditableNodeProvider.GetOnSelected;
begin
  Result := FOnSelected;
end;

procedure TEditableNodeProvider.NotifyChecked;
begin
  inherited;

  if Assigned(FOnChecked) and Attached then
    FOnChecked(FTree, FNode);
end;

procedure TEditableNodeProvider.NotifyCollapsing;
begin
  inherited;

  if Assigned(FOnCollapsing) and Attached then
    FOnCollapsing(FTree, FNode);
end;

procedure TEditableNodeProvider.NotifyExpanding;
begin
  inherited;

  if Assigned(FOnExpanding) and Attached then
    FOnExpanding(FTree, FNode);
end;

procedure TEditableNodeProvider.NotifySelected;
begin
  inherited;

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

procedure TEditableNodeProvider.ResetColor;
begin
  if not FHasColor then
    Exit;

  FHasColor := False;
  Invalidate;
end;

procedure TEditableNodeProvider.ResetCursor;
begin
  if not FHasCursor then
    Exit;

  FHasCursor := False;
  Invalidate;
end;

procedure TEditableNodeProvider.ResetFontColor;
begin
  if not FHasFontColor then
    Exit;

  FHasFontColor := False;
  Invalidate;
end;

procedure TEditableNodeProvider.ResetFontColorForColumn;
begin
  if (Column < Low(FHasFontColorForColumn)) or
    not GetHasFontColorForColumn(Column) then
    Exit;

  if Column > High(FHasFontColorForColumn) then
    SetLength(FHasFontColorForColumn, Column + 1);

  FHasFontColorForColumn[Column] := False;
  Invalidate;
end;

procedure TEditableNodeProvider.ResetFontStyle;
begin
  if not FHasFontStyle then
    Exit;

  FHasFontStyle := False;
  Invalidate;
end;

procedure TEditableNodeProvider.ResetFontStyleForColumn;
begin
  if (Column < Low(FHasFontStyleForColumn)) or
    not GetHasFontColorForColumn(Column) then
    Exit;

  if Column > High(FHasFontStyleForColumn) then
    SetLength(FHasFontStyleForColumn, Column + 1);

  FHasFontStyleForColumn[Column] := False;
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
  if (Column < Low(FColumnText)) or (GetColumnText(Column) = Value) then
    Exit;

  if Column > High(FColumnText) then
    SetLength(FColumnText, Column + 1);

  FColumnText[Column] := Value;
  Invalidate;
end;

procedure TEditableNodeProvider.SetCursor;
begin
  if FHasCursor and (FCursor = Value) then
    Exit;

  FHasCursor := True;
  FCursor := Value;
  Invalidate;
end;

procedure TEditableNodeProvider.SetEnabledMainActionMenu;
begin
  FEnabledMainActionMenu := Value;
end;

procedure TEditableNodeProvider.SetFontColor;
begin
  if FHasFontColor and (FFontColor = Value) then
    Exit;

  FHasFontColor := True;
  FFontColor := Value;
  Invalidate;
end;

procedure TEditableNodeProvider.SetFontColorForColumn;
begin
  if Column < Low(FFontColorForColumn) then
    Exit;

  if GetHasFontColorForColumn(Column) and
    (GetFontColorForColumn(Column) = Value) then
    Exit;

  if Column > High(FHasFontColorForColumn) then
    SetLength(FHasFontColorForColumn, Column + 1);

  if Column > High(FFontColorForColumn) then
    SetLength(FFontColorForColumn, Column + 1);

  FHasFontColorForColumn[Column] := True;
  FFontColorForColumn[Column] := Value;
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

procedure TEditableNodeProvider.SetFontStyleForColumn;
begin
    if Column < Low(FFontStyleForColumn) then
    Exit;

  if GetHasFontStyleForColumn(Column) and
    (GetFontStyleForColumn(Column) = Value) then
    Exit;

  if Column > High(FHasFontStyleForColumn) then
    SetLength(FHasFontStyleForColumn, Column + 1);

  if Column > High(FFontStyleForColumn) then
    SetLength(FFontStyleForColumn, Column + 1);

  FHasFontStyleForColumn[Column] := True;
  FFontStyleForColumn[Column] := Value;
  Invalidate;
end;

procedure TEditableNodeProvider.SetHint;
begin
  if FHint = Value then
    Exit;

  FHint := Value;
  Invalidate;
end;

procedure TEditableNodeProvider.SetOnAttach;
begin
  FOnAttach := Value;
end;

procedure TEditableNodeProvider.SetOnChecked;
begin
  FOnChecked := Value;
end;

procedure TEditableNodeProvider.SetOnCollapsing;
begin
  FOnCollapsing := Value;
end;

procedure TEditableNodeProvider.SetOnDetach;
begin
  FOnDetach := Value;
end;

procedure TEditableNodeProvider.SetOnExpanding;
begin
  FOnExpanding := Value;
end;

procedure TEditableNodeProvider.SetOnSelected;
begin
  FOnSelected := Value;
end;

end.
