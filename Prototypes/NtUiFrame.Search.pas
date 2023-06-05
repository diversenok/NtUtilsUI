unit NtUiFrame.Search;

{
  This module provides a frame for searching within devirtualized trees.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, VirtualTrees, DevirtualizedTree, NtUiCommon.Interfaces;

type
  TSearchFrame = class(TFrame, IHasSearch, ICanConsumeEscape)
    tbxSearchBox: TButtonedEdit;
    cbxColumn: TComboBox;
    Splitter: TSplitter;
    procedure tbxSearchBoxChange(Sender: TObject);
    procedure tbxSearchBoxRightButtonClick(Sender: TObject);
    procedure tbxSearchBoxKeyPress(Sender: TObject; var Key: Char);
    procedure cbxColumnChange(Sender: TObject);
    procedure tbxSearchBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FLoaded: Boolean;
    FImages: TImageList;
    FTree: TDevirtualizedTree;
    FColumnIndexes: TArray<TColumnIndex>;
    FOnQueryChange: TNotifyEvent;
    procedure LoadIcons;
    procedure UpdateColumns;
    function GetQueryText: String;
    function GetHasQueryText: Boolean;
    function GetQueryColumn: Integer;
    procedure ColumnVisibilityChanged(const Sender: TBaseVirtualTree; const Column: TColumnIndex; Visible: Boolean);
  protected
    procedure Loaded; override;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
  public
    procedure ClearQuery;
    property HasQueryText: Boolean read GetHasQueryText;
    property QueryText: String read GetQueryText;
    property QueryColumn: Integer read GetQueryColumn;
    property OnQueryChange: TNotifyEvent read FOnQueryChange write FOnQueryChange;
    procedure AttachToTree(Tree: TDevirtualizedTree);
    procedure ApplySearch;
    procedure SetSearchFocus;
    function ConsumesEscape: Boolean;
  end;

implementation

uses
  Vcl.ImgList, DelphiUtils.AutoObjects, VirtualTreesEx, UI.Helper;

{$R *.dfm}
{$R '..\Icons\SearchBox.res'}

{ TSearchFrame }

procedure TSearchFrame.ApplySearch;
var
  Node: PVirtualNode;
begin
  if not Assigned(FTree) then
    Exit;

  FTree.BeginUpdateAuto;

  // Adjust node visibility
  for Node in FTree.Nodes.ToArray do
    FTree.IsVisible[Node] := not HasQueryText or (Node.HasProvider and
      Node.Provider.MatchesSearch(QueryText, QueryColumn));
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

procedure TSearchFrame.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;

  if isDpiChange and FLoaded then
    LoadIcons;
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

function TSearchFrame.ConsumesEscape;
begin
  Result := (tbxSearchBox.Focused and HasQueryText) or
    (cbxColumn.Focused and cbxColumn.DroppedDown);
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

function TSearchFrame.GetQueryText;
begin
  Result := tbxSearchBox.Text;
end;

procedure TSearchFrame.Loaded;
begin
  inherited;

  if FLoaded then
    Exit;

  FLoaded := True;
  FImages := TImageList.Create(Self);
  FImages.ColorDepth := cd32Bit;
  tbxSearchBox.Images := FImages;
  LoadIcons;
end;

procedure TSearchFrame.LoadIcons;
var
  Icon: TIcon;
begin
  tbxSearchBox.LeftButton.ImageIndex := -1;
  tbxSearchBox.RightButton.ImageIndex := -1;

  FImages.Clear;
  FImages.Width := 16 * CurrentPPI div 96;
  FImages.Height := 16 * CurrentPPI div 96;

  try
    Icon := Auto.From(TIcon.Create).Self;
    Icon.LoadFromResourceName(HInstance, 'SearchBox.Search');
    tbxSearchBox.LeftButton.ImageIndex := FImages.AddIcon(Icon);
    tbxSearchBox.LeftButton.Visible := True;

    Icon := Auto.From(TIcon.Create).Self;
    Icon.LoadFromResourceName(HInstance, 'SearchBox.Clear');
    tbxSearchBox.RightButton.ImageIndex := FImages.AddIcon(Icon);
  except
    ; // Missing icons should not prevent loading
  end;
end;

procedure TSearchFrame.SetSearchFocus;
begin
  tbxSearchBox.SetFocus;
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
  if Assigned(FTree) and ((Key = VK_UP) or (Key = VK_DOWN)) then
    FTree.SetFocus;
end;

procedure TSearchFrame.tbxSearchBoxKeyPress;
begin
  if (Key = Chr(VK_ESCAPE)) and HasQueryText then
  begin
    ClearQuery;
    Key := #0;
  end;
end;

procedure TSearchFrame.tbxSearchBoxRightButtonClick;
begin
  ClearQuery;
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
