unit NtUiFrame.Search;

{
  This module provides a frame for searching within devirtualized trees.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, VirtualTrees, NtUtilsUI.DevirtualizedTree,
  NtUtilsUI, NtUtilsUI.StdCtrls, NtUtilsUI.Base, NtUtilsUI.SearchBox;

type
  TSearchFrame = class(TFrame)
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
    procedure ColumnVisibilityChanged(const Sender: TBaseVirtualTree; const Column: TColumnIndex; Visible: Boolean);
    procedure OnEscShortcut(Sender: TUiLibShortcut; var Handled: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    procedure AttachToTree(Tree: TDevirtualizedTree);
    procedure ApplySearch;
  end;

implementation

uses
  NtUiCommon.Helpers;

{$R *.dfm}

{ TSearchFrame }

procedure TSearchFrame.ApplySearch;
var
  SearchColumn: TColumnIndex;
begin
  if not Assigned(FTree) then
    Exit;

  if cbxColumn.ItemIndex > 0 then
    SearchColumn := FColumnIndexes[cbxColumn.ItemIndex]
  else
    SearchColumn := -1;

  FTree.ApplyFilter(SearchBox.Query, SearchColumn);
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
