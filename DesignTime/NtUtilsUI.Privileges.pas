unit NtUtilsUI.Privileges;

{
  This module contains a (stripped down) design-time component definition for
  a privilege list control.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, Vcl.Menus, NtUtilsUI.Base, NtUtilsUI.Tree,
  NtUtilsUI.Tree.Search;

type
  TUiLibPrivilegeListMode = (pmNormal, pmAdding, pmRemoving);

  TUiLibPrivilegeList = class (TUiLibControl)
  private
    FSearch: TUiLibTreeSearchBox;
    FTree: TUiLibTree;
    FMode: TUiLibPrivilegeListMode;
    function GetPopupMenu: TPopupMenu; reintroduce;
    procedure SetPopupMenu(const Value: TPopupMenu);
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Mode: TUiLibPrivilegeListMode read FMode write FMode default pmNormal;
    property PopupMenu: TPopupMenu read GetPopupMenu write SetPopupMenu;
  end;

procedure Register;

implementation

uses
  Vcl.Controls, VirtualTrees, VirtualTrees.Types, VirtualTrees.Header;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R 'Icons\TUiLibPrivilegeList.res'}

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibPrivilegeList]);
end;

const
  colFriendly = 0;
  colName = 1;
  colValue = 2;
  colState = 3;
  colDescription = 4;
  colIntegrity = 5;
  colMax = 6;

{ TUiLibPrivilegeList }

constructor TUiLibPrivilegeList.Create;
var
  Column: TVirtualTreeColumn;
begin
  inherited;

  Width := 500;
  Height := 400;
  Constraints.MinHeight := 120;
  DoubleBuffered := True;

  FSearch := TUiLibTreeSearchBox.Create(Self);
  FSearch.Width := Width;
  FSearch.Align := alTop;
  FSearch.Parent := Self;

  FTree := TUiLibTree.Create(Self);
  FTree.Width := Width;
  FTree.Height := Height - FSearch.Height;
  FTree.Align := alClient;
  FTree.Header.Columns.BeginUpdate;

  Column := FTree.Header.Columns.Add;
  Column.Text := 'Friendly Name';
  Column.Width := 160;

  Column := FTree.Header.Columns.Add;
  Column.Text := 'Name';
  Column.Width := 140;
  Column.Options := Column.Options - [coVisible];

  Column := FTree.Header.Columns.Add;
  Column.Text := 'Value';
  Column.Width := 50;
  Column.Options := Column.Options - [coVisible];

  Column := FTree.Header.Columns.Add;
  Column.Text := 'State';
  Column.Width := 100;

  Column := FTree.Header.Columns.Add;
  Column.Text := 'Description';
  Column.Width := 200;

  Column := FTree.Header.Columns.Add;
  Column.Text := 'Required Integrity';
  Column.Width := 110;
  Column.Options := Column.Options - [coVisible];

  FTree.Header.AutoSizeIndex := colDescription;
  FTree.Header.Columns.EndUpdate;
  FTree.Parent := Self;
end;

function TUiLibPrivilegeList.GetPopupMenu;
begin
  Result := FTree.PopupMenu;
end;

procedure TUiLibPrivilegeList.SetPopupMenu;
begin
  FTree.PopupMenu := Value;
end;

end.
