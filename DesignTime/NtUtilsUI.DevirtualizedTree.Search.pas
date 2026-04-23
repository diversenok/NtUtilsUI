unit NtUtilsUI.DevirtualizedTree.Search;

{
  This module contains a (stripped down) design-time component definition for
  the tree view search (filtration) control.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, Vcl.ExtCtrls, NtUtilsUI.Base, NtUtilsUI.StdCtrls,
  NtUtilsUI.SearchBox;

type
  TUiLibTreeSearchBox = class (TUiLibControl)
  private
    FSearchBox: TUiLibSearchBox;
    FColumnsBox: TUiLibComboBox;
    FSplitter: TSplitter;
  protected
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

procedure Register;

implementation

uses
  Vcl.Controls, Vcl.StdCtrls;

{$R 'Icons\TUiLibTreeSearchBox.res'}

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibTreeSearchBox]);
end;

{ TUiLibTreeSearchBox }

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
end;

procedure TUiLibTreeSearchBox.CreateWnd;
begin
  inherited;
  FColumnsBox.Items.Add('All visible columns');
  FColumnsBox.ItemIndex := 0;
end;

end.
