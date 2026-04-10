unit NtUtilsUI.Guid;

{
  This module contains a (stripped down) design-time component definition for
  the GUID selection control.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, NtUtilsUI.Base, NtUtilsUI.StdCtrls;

type
  TUiLibGuidBox = class (TUiLibControl)
  private
    FEdit: TUiLibEdit;
  public
    constructor Create(AOwner: TComponent); override;
  end;

procedure Register;

implementation

uses
  Vcl.Controls;

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibGuidBox]);
end;

{ TUiLibGuidBox }

constructor TUiLibGuidBox.Create;
begin
  inherited;

  Width := 300;
  Height := 23;
  Constraints.MinWidth := 300;

  FEdit := TUiLibEdit.Create(Self);
  FEdit.Width := Width;
  FEdit.Height := Height;
  FEdit.Align := alClient;
  FEdit.Text := '{00000000-0000-0000-0000-000000000000}';
  FEdit.Parent := Self;
end;

end.
