unit DevirtualizedTree.Provider;

{
  This module defined the base class for creting node state providers for the
  devirtualized tree view.
}

interface

uses
  VirtualTrees, DevirtualizedTree, Vcl.Graphics;

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
    FHasFontStyle: Boolean;
    FFontStyle: TFontStyles;
    FEnabledInspectMenu: Boolean;

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
    function GetColumnText(Index: Integer): String; virtual;
    function GetHint: String; virtual;
    function GetColor: TColor; virtual;
    function GetHasColor: Boolean; virtual;
    function GetFontColor: TColor; virtual;
    function GetHasFontColor: Boolean; virtual;
    function GetFontStyle: TFontStyles; virtual;
    function GetHasFontStyle: Boolean; virtual;
    function GetEnabledInspectMenu: Boolean; virtual;
  public
    constructor Create(InitialColumnCount: Integer = 1);
  end;

  IEditableNodeProvider = interface (INodeProvider)
    ['{A0F36B1F-7838-41C2-B1EE-700BC7FFDE9D}']

    procedure SetColumnText(Index: Integer; const Value: String);
    procedure SetHint(const Value: String);
    procedure SetColor(Value: TColor);
    procedure SetFontColor(Value: TColor);
    procedure SetFontStyle(Value: TFontStyles);
    procedure SetEnabledInspectMenu(Value: Boolean);

    procedure ResetColor;
    procedure ResetFontColor;
    procedure ResetFontStyle;

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
    property ColumnText[Index: Integer]: String read GetColumnText write SetColumnText;
    property Hint: String read GetHint write SetHint;
    property Color: TColor read GetColor write SetColor;
    property HasColor: Boolean read GetHasColor;
    property FontColor: TColor read GetFontColor write SetFontColor;
    property HasFontColor: Boolean read GetHasFontColor;
    property FontStyle: TFontStyles read GetFontStyle write SetFontStyle;
    property HasFontStyle: Boolean read GetHasFontStyle;
    property EnabledInspectMenu: Boolean read GetEnabledInspectMenu write SetEnabledInspectMenu;
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

    procedure SetColumnText(Index: Integer; const Value: String); virtual;
    procedure SetHint(const Value: String); virtual;
    procedure SetColor(Value: TColor); virtual;
    procedure SetFontColor(Value: TColor); virtual;
    procedure SetFontStyle(Value: TFontStyles); virtual;
    procedure SetEnabledInspectMenu(Value: Boolean); virtual;

    procedure ResetColor; virtual;
    procedure ResetFontColor; virtual;
    procedure ResetFontStyle; virtual;

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
  FEnabledInspectMenu := True;
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
