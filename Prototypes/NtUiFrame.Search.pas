unit NtUiFrame.Search;

{
  This module provides a frame for searching within devirtualized trees.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, VirtualTrees, NtUtilsUI.DevirtualizedTree, NtUiFrame,
  NtUiCommon.Interfaces, NtUtilsUI, NtUtilsUI.StdCtrls, NtUtilsUI.Base,
  NtUtilsUI.SearchBox;

type
  TSearchFrame = class(TBaseFrame)
    cbxColumn: TComboBox;
    Splitter: TSplitter;
    SearchBox: TUiLibSearchBox;
    procedure cbxColumnChange(Sender: TObject);
    procedure SearchBoxSearch(Sender: TObject);
    procedure SearchBoxArrow(Sender: TObject);
  private
    FTree: TDevirtualizedTree;
    FColumnIndexes: TArray<TColumnIndex>;
    FOnQueryChange: TNotifyEvent;
    FEscShortCut: TUiLibShortCut;
    procedure UpdateColumns;
    function GetQueryColumns: TArray<TColumnIndex>;
    procedure ColumnVisibilityChanged(const Sender: TBaseVirtualTree; const Column: TColumnIndex; Visible: Boolean);
    procedure OnEscShortcut(Sender: TUiLibShortcut; var Handled: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    procedure AttachToTree(Tree: TDevirtualizedTree);
    procedure ApplySearch;
  end;

implementation

uses
  NtUtilsUI.VirtualTreeEx, NtUiCommon.Helpers, NtUtils.SysUtils;

{$R *.dfm}

{ TSearchFrame }

procedure TSearchFrame.ApplySearch;
var
  Node, Parent: PVirtualNode;
  VisibleNodes: TArray<PVirtualNode>;
  Provider: INodeProvider;
  SearchColumns: TArray<TColumnIndex>;
  Column: TColumnIndex;
  Matches, IsNumberSearch, IsSignedNumber: Boolean;
  Expression: String;
  NumberQuery: UInt64;
begin
  if not Assigned(FTree) then
    Exit;

  SearchColumns := GetQueryColumns;
  FTree.BeginUpdateAuto;

  // Reset visibility
  for Node in FTree.Nodes do
    if Node.TryGetProvider(Provider) then
      FTree.IsVisible[Node] := Provider.SearchExpression('', -1);

  if not SearchBox.HasQuery then
    Exit;

  Expression := SearchBox.Query;

  // Check if the query parses into a number
  IsNumberSearch := RtlxStrToUInt64(Expression, NumberQuery, nsDecimal,
    [nsHexadecimal], True, [npSpace, npAccent, npApostrophe, npUnderscore]);
  IsSignedNumber := IsNumberSearch and (Length(Expression) > 1) and
    (Expression[Low(String)] = '-');

  // Prepare an upcased expression for text search
  Expression := '*' + RtlxUpperString(Expression) + '*';

  // Collect nodes that are visible without the search
  VisibleNodes := FTree.VisibleNodes.ToArray;

  // Test each node against the query
  for Node in VisibleNodes do
    if Node.TryGetProvider(Provider) then
    begin
      Matches := False;

      // At least one coulmn should match
      for Column in SearchColumns do
      begin
        Matches := (IsNumberSearch and
          Provider.SearchNumber(NumberQuery, IsSignedNumber, Column)) or
          Provider.SearchExpression(Expression, Column);

        if Matches then
          Break;
      end;

      if Matches then
      begin
        // Make the node and all of its parents visible
        Parent := Node;
        repeat
          FTree.IsVisible[Parent] := True;
          Parent := FTree.NodeParent[Parent];
        until not Assigned(Parent);
      end
      else
        FTree.IsVisible[Node] := False;
    end;
end;

procedure TSearchFrame.AttachToTree;
begin
  FTree := Tree;
  Tree.OnColumnVisibilityChanged := ColumnVisibilityChanged;
  UpdateColumns;
end;

procedure TSearchFrame.cbxColumnChange;
begin
  ApplySearch;

  // Notify subscribers
  if Assigned(FOnQueryChange) then
    FOnQueryChange(Self);
end;

procedure TSearchFrame.ColumnVisibilityChanged;
begin
  UpdateColumns;
end;

constructor TSearchFrame.Create;
begin
  inherited;

  FEscShortCut := TUiLibShortCut.Create(Self);
  FEscShortCut.ShortCut := VK_ESCAPE;
  FEscShortCut.OnExecute := OnEscShortCut;
end;

function TSearchFrame.GetQueryColumns;
var
  VisibleColumns: TColumnsArray;
  i: Integer;
begin
  i := cbxColumn.ItemIndex;

  if (i > 0) and (i <= High(FColumnIndexes)) then
    // Only the specified column
    Result := [FColumnIndexes[i]]
  else
  begin
    // All visible columns
    VisibleColumns := FTree.Header.Columns.GetVisibleColumns;
    SetLength(Result, Length(VisibleColumns));

    for i := 0 to High(VisibleColumns) do
      Result[i] := VisibleColumns[i].Index;
  end;
end;

procedure TSearchFrame.OnEscShortcut;
begin
  if not SearchBox.Focused then
    Exit;

  if SearchBox.HasQuery then
  begin
    SearchBox.ClearQuery;
    Handled := True;
  end
  else if Assigned(FTree) and FTree.CanFocus then
    FTree.SetFocus;
end;

procedure TSearchFrame.SearchBoxArrow;
begin
  if Assigned(FTree) and FTree.CanFocus then
    FTree.SetFocus;
end;

procedure TSearchFrame.SearchBoxSearch;
begin
  ApplySearch;
end;

procedure TSearchFrame.UpdateColumns;
var
  NewColumns: TColumnsArray;
  NewItems: TArray<String>;
  i: Integer;
begin
  if not Assigned(FTree) then
    Exit;

  // Collect all visible columns + one for searching all at once
  NewColumns := FTree.Header.Columns.GetVisibleColumns;
  SetLength(NewItems, Length(NewColumns) + 1);
  SetLength(FColumnIndexes, Length(NewColumns) + 1);
  NewItems[0] := 'All visible columns';
  FColumnIndexes[0] := -1;

  for i := 0 to High(NewColumns) do
  begin
    NewItems[i + 1] := NewColumns[i].Text;
    FColumnIndexes[i + 1] := NewColumns[i].Index;
  end;

  cbxColumn.UpdateItems(NewItems, 0);
  ApplySearch;
end;

end.
