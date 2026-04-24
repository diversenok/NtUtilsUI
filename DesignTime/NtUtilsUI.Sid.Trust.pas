unit NtUtilsUI.Sid.Trust;

{
  This module contains a (stripped down) design-time component definition for
  an trust label SID selection control.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, Vcl.StdCtrls, Vcl.ComCtrls, NtUtilsUI.Base, NtUtilsUI.StdCtrls;

type
  TUiLibTrustSid = class (TUiLibControl)
  private
    FTypeComboBox: TUiLibComboBox;
    FTypeTrackBar: TTrackBar;
    FLevelComboBox: TUiLibComboBox;
    FLevelTrackBar: TTrackBar;
    FTypeLabelNone: TLabel;
    FTypeLabelLight: TLabel;
    FTypeLabelFull: TLabel;
    FLevelLabelNone: TLabel;
    FLevelLabelAntimalware: TLabel;
    FLevelLabelWindows: TLabel;
    FLevelLabelWinTcb: TLabel;
  public
    constructor Create(AOwner: TComponent); override;
  end;

procedure Register;

implementation

uses
  Vcl.Controls;

{$R 'Icons\TUiLibTrustSid.res'}

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibTrustSid]);
end;

{ TUiLibTrustSid }

constructor TUiLibTrustSid.Create;
begin
  inherited;

  Width := 400;
  Height := 185;
  Constraints.MinHeight := 185;
  Constraints.MinWidth := 330;

  { Type }

  FTypeComboBox := TUiLibComboBox.Create(Self);
  FTypeComboBox.Width := 400;
  FTypeComboBox.Height := 21;
  FTypeComboBox.Anchors := [akLeft, akTop, akRight];
  FTypeComboBox.Text := 'Light (0x200)';
  FTypeComboBox.Parent := Self;

  FTypeTrackBar := TTrackBar.Create(Self);
  FTypeTrackBar.Top := 47;
  FTypeTrackBar.Width := 400;
  FTypeTrackBar.Height := 35;
  FTypeTrackBar.Anchors := [akLeft, akTop, akRight];
  FTypeTrackBar.LineSize := 128;
  FTypeTrackBar.Max := 1024;
  FTypeTrackBar.PageSize := 512;
  FTypeTrackBar.Frequency := 512;
  FTypeTrackBar.Position := 512;
  FTypeTrackBar.ShowSelRange := False;
  FTypeTrackBar.TickMarks := tmBoth;
  FTypeTrackBar.Parent := Self;

  FTypeLabelNone := TLabel.Create(Self);
  FTypeLabelNone.Left := 0;
  FTypeLabelNone.Top := 27;
  FTypeLabelNone.Width := 29;
  FTypeLabelNone.Height := 15;
  FTypeLabelNone.Anchors := [akTop, akLeft];
  FTypeLabelNone.Caption := 'None';
  FTypeLabelNone.Parent := Self;

  FTypeLabelLight := TLabel.Create(Self);
  FTypeLabelLight.Left := 187;
  FTypeLabelLight.Top := 27;
  FTypeLabelLight.Width := 27;
  FTypeLabelLight.Height := 15;
  FTypeLabelLight.Anchors := [akTop];
  FTypeLabelLight.Caption := 'Light';
  FTypeLabelLight.Parent := Self;

  FTypeLabelFull := TLabel.Create(Self);
  FTypeLabelFull.Left := 378;
  FTypeLabelFull.Top := 27;
  FTypeLabelFull.Width := 19;
  FTypeLabelFull.Height := 15;
  FTypeLabelFull.Anchors := [akTop, akRight];
  FTypeLabelFull.Caption := 'Full';
  FTypeLabelFull.Parent := Self;

  { Level }

  FLevelComboBox := TUiLibComboBox.Create(Self);
  FLevelComboBox.Top := 99;
  FLevelComboBox.Width := 400;
  FLevelComboBox.Height := 21;
  FLevelComboBox.Anchors := [akLeft, akTop, akRight];
  FLevelComboBox.Text := 'Antimalware (0x0600)';
  FLevelComboBox.Parent := Self;

  FLevelTrackBar := TTrackBar.Create(Self);
  FLevelTrackBar.Top := 126;
  FLevelTrackBar.Width := 400;
  FLevelTrackBar.Height := 35;
  FLevelTrackBar.Anchors := [akLeft, akTop, akRight];
  FLevelTrackBar.LineSize := 256;
  FLevelTrackBar.Max := 8192;
  FLevelTrackBar.PageSize := 512;
  FLevelTrackBar.Frequency := 512;
  FLevelTrackBar.Position := 1536;
  FLevelTrackBar.ShowSelRange := False;
  FLevelTrackBar.TickMarks := tmBoth;
  FLevelTrackBar.Parent := Self;

  FLevelLabelNone := TLabel.Create(Self);
  FLevelLabelNone.Left := 0;
  FLevelLabelNone.Top := 167;
  FLevelLabelNone.Width := 29;
  FLevelLabelNone.Height := 15;
  FLevelLabelNone.Anchors := [akTop, akLeft];
  FLevelLabelNone.Caption := 'None';
  FLevelLabelNone.Parent := Self;

  FLevelLabelAntimalware := TLabel.Create(Self);
  FLevelLabelAntimalware.Left := 50;
  FLevelLabelAntimalware.Top := 167;
  FLevelLabelAntimalware.Width := 67;
  FLevelLabelAntimalware.Height := 15;
  FLevelLabelAntimalware.Anchors := [akTop];
  FLevelLabelAntimalware.Caption := 'Antimalware';
  FLevelLabelAntimalware.Parent := Self;

  FLevelLabelWindows := TLabel.Create(Self);
  FLevelLabelWindows.Left := 176;
  FLevelLabelWindows.Top := 167;
  FLevelLabelWindows.Width := 49;
  FLevelLabelWindows.Height := 15;
  FLevelLabelWindows.Anchors := [akTop];
  FLevelLabelWindows.Caption := 'Windows';
  FLevelLabelWindows.Parent := Self;

  FLevelLabelWinTcb := TLabel.Create(Self);
  FLevelLabelWinTcb.Left := 358;
  FLevelLabelWinTcb.Top := 167;
  FLevelLabelWinTcb.Width := 42;
  FLevelLabelWinTcb.Height := 15;
  FLevelLabelWinTcb.Anchors := [akTop, akRight];
  FLevelLabelWinTcb.Caption := 'WinTCB';
  FLevelLabelWinTcb.Parent := Self;
end;

end.
