unit NtUtilsUI.Tree.Search;

{
  This module contains the full runtime component definition for the tree view
  search (filtration) control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, Vcl.ExtCtrls, VirtualTrees, DelphiUtils.AutoObjects,
  NtUtilsUI.Base, NtUtilsUI.StdCtrls, NtUtilsUI.SearchBox,
  NtUtilsUI.Tree;

type
  TUiLibTreeSearchBox = class (TUiLibControl)
  private
    FSearchBox: TUiLibSearchBox;
    FColumnsBox: TUiLibComboBox;
    FSplitter: TSplitter;
    FEscShortCut: TUiLibShortCut;
    FTree: TUiLibTree;
    FTreeWeakRef: IWeak;
    FColumnIndexes: TArray<TColumnIndex>;
    function HasTree: Boolean;
    procedure SearchBoxSearch(Sender: TObject);
    procedure SearchBoxArrow(Sender: TObject);
    procedure OnEscShortcut(Sender: TUiLibShortCut; var Handled: Boolean);
    procedure ColumnVisibilityChanged(const Sender: TBaseVirtualTree; const Column: TColumnIndex; Visible: Boolean);
    procedure UpdateColumns;
  protected
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AttachToTree(Tree: TUiLibTree);
  end;

implementation

uses
  Winapi.Windows, Vcl.Controls, Vcl.StdCtrls;

{ TUiLibTreeSearchBox }

procedure TUiLibTreeSearchBox.AttachToTree;
begin
  // Detach from the previous tree
  if HasTree then
    FTree.OnColumnVisibilityChanged := nil;

  FTree := Tree;

  // Attach to the new one
  if Assigned(FTree) then
  begin
    FTreeWeakRef := Auto.RefWeak(Tree);
    FTree.OnColumnVisibilityChanged := ColumnVisibilityChanged;
  end
  else
    FTreeWeakRef := nil;

  if HandleAllocated then
    UpdateColumns;
end;

procedure TUiLibTreeSearchBox.ColumnVisibilityChanged;
begin
  UpdateColumns;
end;

constructor TUiLibTreeSearchBox.Create;
begin
  inherited;

  Width := 436;
  Height := 21;
  Constraints.MinWidth := 240;
  Constraints.MinHeight := 21;
  DoubleBuffered := True;

  FSearchBox := TUiLibSearchBox.Create(Self);
  FSearchBox.Left := 0;
  FSearchBox.Top := 0;
  FSearchBox.Width := 270;
  FSearchBox.Height := Height;
  FSearchBox.Align := alClient;
  FSearchBox.TabOrder := 0;
  FSearchBox.OnSearch := SearchBoxSearch;
  FSearchBox.OnArrowUp := SearchBoxArrow;
  FSearchBox.OnArrowDown := SearchBoxArrow;
  FSearchBox.Parent := Self;

  FColumnsBox := TUiLibComboBox.Create(Self);
  FColumnsBox.Left := 276;
  FColumnsBox.Top := 0;
  FColumnsBox.Width := 160;
  FColumnsBox.Height := Height;
  FColumnsBox.Align := alRight;
  FColumnsBox.Style := csDropDownList;
  FColumnsBox.ExtendedUI := True;
  FColumnsBox.TabOrder := 1;
  FColumnsBox.OnChange := SearchBoxSearch;
  FColumnsBox.Parent := Self;

  FSplitter := TSplitter.Create(Self);
  FSplitter.Left := 270;
  FSplitter.Top := 0;
  FSplitter.Width := 6;
  FSplitter.Height := Height;
  FSplitter.Align := alRight;
  FSplitter.AutoSnap := False;
  FSplitter.MinSize := 110;
  FSplitter.ResizeStyle := rsUpdate;
  FSplitter.Parent := Self;

  FEscShortCut := TUiLibShortCut.Create(Self);
  FEscShortCut.ShortCut := VK_ESCAPE;
  FEscShortCut.OnExecute := OnEscShortCut;
end;

procedure TUiLibTreeSearchBox.CreateWnd;
begin
  inherited;
  UpdateColumns;
end;

destructor TUiLibTreeSearchBox.Destroy;
begin
  if HasTree then
  begin
    FTree.OnColumnVisibilityChanged := nil;
    FTree := nil;
    FTreeWeakRef := nil;
  end;

  inherited;
end;

function TUiLibTreeSearchBox.HasTree;
begin
  Result := Assigned(FTreeWeakRef) and FTreeWeakRef.HasRef and Assigned(FTree);
end;

procedure TUiLibTreeSearchBox.OnEscShortcut;
begin
  if not FSearchBox.Focused then
    Exit;

  if FSearchBox.HasQuery then
  begin
    FSearchBox.ClearQuery;
    Handled := True;
  end
  else if HasTree and FTree.CanFocus then
    FTree.SetFocus;
end;

procedure TUiLibTreeSearchBox.SearchBoxArrow;
begin
  if HasTree and FTree.CanFocus then
    FTree.SetFocus;
end;

procedure TUiLibTreeSearchBox.SearchBoxSearch;
var
  SearchColumn: TColumnIndex;
begin
  if HasTree then
  begin
    if FColumnsBox.ItemIndex > 0 then
      SearchColumn := FColumnIndexes[FColumnsBox.ItemIndex]
    else
      SearchColumn := -1;

    FTree.ApplyFilter(FSearchBox.Query, SearchColumn);
  end;
end;

procedure TUiLibTreeSearchBox.UpdateColumns;
var
  NewColumns: TColumnsArray;
  NewItems: TArray<String>;
  i: Integer;
begin
  // Collect all visible columns + one for searching all at once
  if HasTree then
    NewColumns := FTree.Header.Columns.GetVisibleColumns
  else
    NewColumns := nil;

  SetLength(NewItems, Length(NewColumns) + 1);
  SetLength(FColumnIndexes, Length(NewColumns) + 1);
  NewItems[0] := 'All visible columns';
  FColumnIndexes[0] := -1;

  for i := 0 to High(NewColumns) do
  begin
    NewItems[i + 1] := NewColumns[i].Text;
    FColumnIndexes[i + 1] := NewColumns[i].Index;
  end;

  FColumnsBox.UpdateItems(NewItems, 0);
  SearchBoxSearch(Self);
end;

end.
