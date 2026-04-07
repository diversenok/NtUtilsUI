unit NtUiFrame.Search;

{
  This module provides a frame for searching within devirtualized trees.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, VirtualTrees, NtUtilsUI.DevirtualizedTree, NtUiFrame,
  NtUiCommon.Interfaces, NtUtilsUI, NtUtilsUI.StdCtrls;

type
  TSearchFrame = class(TBaseFrame)
    tbxSearchBox: TUiLibButtonedEdit;
    cbxColumn: TComboBox;
    Splitter: TSplitter;
    procedure tbxSearchBoxChange(Sender: TObject);
    procedure tbxSearchBoxRightButtonClick(Sender: TObject);
    procedure cbxColumnChange(Sender: TObject);
    procedure tbxSearchBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure tbxSearchBoxTypingChange(Sender: TObject);
  private
    FTree: TDevirtualizedTree;
    FColumnIndexes: TArray<TColumnIndex>;
    FOnQueryChange: TNotifyEvent;
    FSearchIconIndex, FSearchAltIconIndex: Integer;
    FFocusShortCut: TUiLibShortCut;
    FEscShortCut: TUiLibShortCut;
    procedure UpdateColumns;
    function GetQueryText: String;
    function GetHasQueryText: Boolean;
    function GetQueryColumn: TColumnIndex;
    function GetQueryColumns: TArray<TColumnIndex>;
    procedure ColumnVisibilityChanged(const Sender: TBaseVirtualTree; const Column: TColumnIndex; Visible: Boolean);
    procedure LeftButtonIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure LeftButtonAltIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure RightButtonIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure RefreshSearchIcon;
    procedure OnFocusShortCut(Sender: TUiLibShortCut; var Handled: Boolean);
    procedure OnEscShortcut(Sender: TUiLibShortcut; var Handled: Boolean);
  protected
    procedure LoadedOnce; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ClearQuery;
    property HasQueryText: Boolean read GetHasQueryText;
    property QueryText: String read GetQueryText;
    property QueryColumn: TColumnIndex read GetQueryColumn;
    property QueryColumns: TArray<TColumnIndex> read GetQueryColumns;
    property OnQueryChange: TNotifyEvent read FOnQueryChange write FOnQueryChange;
    procedure AttachToTree(Tree: TDevirtualizedTree);
    procedure ApplySearch;
  end;

implementation

uses
  NtUtilsUI.VirtualTreeEx, NtUiCommon.Helpers, NtUtils.SysUtils;

{$R *.dfm}
{$R '..\Icons\SearchBox.res'}

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

  if QueryText = '' then
    Exit;

  // Check if the query parses into a number
  IsNumberSearch := RtlxStrToUInt64(QueryText, NumberQuery, nsDecimal,
    [nsHexadecimal], True, [npSpace, npAccent, npApostrophe, npUnderscore]);
  IsSignedNumber := IsNumberSearch and (Length(QueryText) > 1) and
    (QueryText[Low(String)] = '-');

  // Prepare an upcased expression for text search
  Expression := '*' + RtlxUpperString(QueryText) + '*';

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

procedure TSearchFrame.ClearQuery;
begin
  // This will also re-apply the search
  tbxSearchBox.Text := '';
end;

procedure TSearchFrame.ColumnVisibilityChanged;
begin
  UpdateColumns;
end;

constructor TSearchFrame.Create;
begin
  inherited;

  FFocusShortCut := TUiLibShortCut.Create(Self);
  FFocusShortCut.ShortCut := scCtrl or Ord('F');
  FFocusShortCut.OnExecute := OnFocusShortCut;

  FEscShortCut := TUiLibShortCut.Create(Self);
  FEscShortCut.ShortCut := VK_ESCAPE;
  FEscShortCut.OnExecute := OnEscShortCut;
end;

function TSearchFrame.GetHasQueryText;
begin
  Result := tbxSearchBox.Text <> '';
end;

function TSearchFrame.GetQueryColumn;
begin
  Result := cbxColumn.ItemIndex;

  if (Result > 0) and (Result <= High(FColumnIndexes)) then
    Result := FColumnIndexes[Result]
  else
    Result := -1;
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

function TSearchFrame.GetQueryText;
begin
  Result := tbxSearchBox.Text;
end;

procedure TSearchFrame.LeftButtonAltIconChanged;
begin
  FSearchAltIconIndex := ImageIndex;
  tbxSearchBox.Images := ImageList;
  tbxSearchBox.LeftButton.Visible := Assigned(ImageList);
  RefreshSearchIcon;
end;

procedure TSearchFrame.LeftButtonIconChanged;
begin
  FSearchIconIndex := ImageIndex;
  tbxSearchBox.Images := ImageList;
  tbxSearchBox.LeftButton.Visible := Assigned(ImageList);
  RefreshSearchIcon;
end;

procedure TSearchFrame.LoadedOnce;
begin
  inherited;
  RegisterResourceIcon('SearchBox.Search', LeftButtonIconChanged);
  RegisterResourceIcon('SearchBox.Clear', RightButtonIconChanged);
  RegisterResourceIcon('SearchBox.Typing', LeftButtonAltIconChanged);
end;

procedure TSearchFrame.OnEscShortcut;
begin
  if not tbxSearchBox.Focused then
    Exit;

  if HasQueryText then
  begin
    ClearQuery;
    Handled := True;
  end
  else if Assigned(FTree) and FTree.CanFocus then
    FTree.SetFocus;
end;

procedure TSearchFrame.OnFocusShortCut;
begin
  if CanFocus then
  begin
    tbxSearchBox.SetFocus;
    Handled := True;
  end;
end;

procedure TSearchFrame.RefreshSearchIcon;
begin
  if tbxSearchBox.Typing then
    tbxSearchBox.LeftButton.ImageIndex := FSearchAltIconIndex
  else
    tbxSearchBox.LeftButton.ImageIndex := FSearchIconIndex;
end;

procedure TSearchFrame.RightButtonIconChanged;
begin
  tbxSearchBox.Images := ImageList;
  tbxSearchBox.RightButton.ImageIndex := ImageIndex;
end;

procedure TSearchFrame.tbxSearchBoxChange;
begin
  tbxSearchBox.RightButton.Visible := HasQueryText;
  ApplySearch;

  // Notify subscribers
  if Assigned(FOnQueryChange) then
    FOnQueryChange(Self);
end;

procedure TSearchFrame.tbxSearchBoxKeyDown;
begin
  if (Key in [VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT]) and
    Assigned(FTree) and FTree.CanFocus then
    FTree.SetFocus;
end;

procedure TSearchFrame.tbxSearchBoxRightButtonClick;
begin
  ClearQuery;
end;

procedure TSearchFrame.tbxSearchBoxTypingChange;
begin
  RefreshSearchIcon;
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
