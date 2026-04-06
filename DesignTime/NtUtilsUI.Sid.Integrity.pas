unit NtUtilsUI.Sid.Integrity;

{
  This module contains a (stripped down) design-time component definition for
  an integrity level selection control.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, Vcl.StdCtrls, Vcl.ComCtrls, NtUtilsUI, NtUtilsUI.StdCtrls;

type
  TUiLibIntegritySid = class (TUiLibControl)
  private
    FTrackBar: TTrackBar;
    FComboBox: TUiLibComboBox;
    FLabelUntrusted: TLabel;
    FLabelLow: TLabel;
    FLabelMedium: TLabel;
    FLabelHigh: TLabel;
    FLabelSystem: TLabel;
  public
    constructor Create(AOwner: TComponent); override;
end;

procedure Register;

implementation

uses
  Vcl.Controls;

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibIntegritySid]);
end;

{ TUiLibIntegritySid }

constructor TUiLibIntegritySid.Create;
begin
  inherited;
  Width := 280;
  Height := 110;
  Constraints.MinHeight := 110;
  Constraints.MinWidth := 185;
  ShowHint := True;

  FTrackBar := TTrackBar.Create(Self);
  FTrackBar.Top := 50;
  FTrackBar.Width := 280;
  FTrackBar.Height := 35;
  FTrackBar.Anchors := [akLeft, akTop, akRight];
  FTrackBar.LineSize := 512;
  FTrackBar.Max := 16384;
  FTrackBar.PageSize := 4096;
  FTrackBar.Frequency := 4096;
  FTrackBar.Position := 8192;
  FTrackBar.ShowSelRange := False;
  FTrackBar.TickMarks := tmBoth;
  FTrackBar.Parent := Self;

  FComboBox := TUiLibComboBox.Create(Self);
  FComboBox.Width := 280;
  FComboBox.Height := 21;
  FComboBox.Anchors := [akLeft, akTop, akRight];
  FComboBox.Text := 'Medium (0x2000)';
  FComboBox.Parent := Self;

  // Low: top middle-left
  FLabelLow := TLabel.Create(Self);
  FLabelLow.Left := 67;
  FLabelLow.Top := 31;
  FLabelLow.Width := 22;
  FLabelLow.Height := 15;
  FLabelLow.Anchors := [akTop];
  FLabelLow.Caption := 'Low';
  FLabelLow.Parent := Self;

  // High: top middle-right
  FLabelHigh := TLabel.Create(Self);
  FLabelHigh.Left := 195;
  FLabelHigh.Top := 31;
  FLabelHigh.Width := 26;
  FLabelHigh.Height := 15;
  FLabelHigh.Anchors := [akTop];
  FLabelHigh.Caption := 'High';
  FLabelHigh.Parent := Self;

  // Untrusted: bottom left corner
  FLabelUntrusted := TLabel.Create(Self);
  FLabelUntrusted.Left := 0;
  FLabelUntrusted.Top := 91;
  FLabelUntrusted.Width := 52;
  FLabelUntrusted.Height := 15;
  FLabelUntrusted.Anchors := [akLeft, akTop];
  FLabelUntrusted.Caption := 'Untrusted';
  FLabelUntrusted.Parent := Self;

  // Medium: bottom middle
  FLabelMedium := TLabel.Create(Self);
  FLabelMedium.Left := 118;
  FLabelMedium.Top := 91;
  FLabelMedium.Width := 45;
  FLabelMedium.Height := 15;
  FLabelMedium.Anchors := [akTop];
  FLabelMedium.Caption := 'Medium';
  FLabelMedium.Parent := Self;

  // System: bottom right
  FLabelSystem := TLabel.Create(Self);
  FLabelSystem.Left := 242;
  FLabelSystem.Top := 91;
  FLabelSystem.Width := 38;
  FLabelSystem.Height := 15;
  FLabelSystem.Anchors := [akTop, akRight];
  FLabelSystem.Caption := 'System';
  FLabelSystem.Parent := Self;
end;

end.
