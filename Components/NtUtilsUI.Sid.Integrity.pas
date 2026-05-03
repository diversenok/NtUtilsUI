unit NtUtilsUI.Sid.Integrity;

{
  This module contains the full runtime component definition for
  an integrity level selection control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, Vcl.StdCtrls, Vcl.ComCtrls, NtUtilsUI.Base, NtUtilsUI.Number,
  NtUtilsUI, Ntapi.ntseapi, NtUtils;

type
  // A control for selecting an integrity level or SID
  TUiLibIntegritySid = class (TUiLibControl, IHasDefaultCaption,
    IModalResult<ISid>)
  private
    FValue: TIntegrityRid;
    FTrackBar: TTrackBar;
    FComboBox: TUiLibNumberComboBox;
    FLabelUntrusted: TLabel;
    FLabelLow: TLabel;
    FLabelMedium: TLabel;
    FLabelHigh: TLabel;
    FLabelSystem: TLabel;
    procedure ComboBoxChange(Sender: TObject);
    procedure TrackBarChange(Sender: TObject);
    procedure UpdateComboBoxValue;
    procedure UpdateTrackBarValue;
    procedure SetValue(const Value: TIntegrityRid);
    function GetSid: ISid;
    procedure SetSid(const Value: ISid);
  private
    function GetDefaultCaption: String;
    function GetModalResult: ISid;
  public
    constructor Create(AOwner: TComponent); override;
    class function Factory(const InitialChoice: ISid = nil): TWinControlFactory; static;
    property Rid: TIntegrityRid read FValue write SetValue;
    property Sid: ISid read GetSid write SetSid;
  end;

implementation

uses
  Vcl.Controls, Ntapi.WinNt, NtUtils.SysUtils, NtUtils.Security.Sid,
  NtUtilsUI.Components.Factories;

{ TUiLibIntegritySid }

procedure TUiLibIntegritySid.ComboBoxChange;
begin
  FValue := TIntegrityRid(FComboBox.Number);
  UpdateTrackBarValue;
end;

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
  FTrackBar.OnChange := TrackBarChange;
  FTrackBar.Parent := Self;

  FComboBox := TUiLibNumberComboBox.Create(Self);
  FComboBox.Width := 280;
  FComboBox.Height := 21;
  FComboBox.Anchors := [akLeft, akTop, akRight];
  FComboBox.NumberBase := nsHexadecimal;
  FComboBox.NumberSize := isCardinal;
  FComboBox.NumberWidth := 4;
  FComboBox.KnownValues.BeginUpdate;
  FComboBox.KnownValues.Add(SECURITY_MANDATORY_UNTRUSTED_RID, 'Untrusted (0x0000)');
  FComboBox.KnownValues.Add(SECURITY_MANDATORY_LOW_RID, 'Low (0x1000)');
  FComboBox.KnownValues.Add(SECURITY_MANDATORY_MEDIUM_RID, 'Medium (0x2000)');
  FComboBox.KnownValues.Add(SECURITY_MANDATORY_MEDIUM_PLUS_RID, 'Medium Plus (0x2100)');
  FComboBox.KnownValues.Add(SECURITY_MANDATORY_HIGH_RID, 'High (0x3000)');
  FComboBox.KnownValues.Add(SECURITY_MANDATORY_SYSTEM_RID, 'System (0x4000)');
  FComboBox.KnownValues.Add(SECURITY_MANDATORY_PROTECTED_PROCESS_RID, 'Protected (0x5000)');
  FComboBox.KnownValues.EndUpdate;
  FComboBox.OnChange := ComboBoxChange;
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

  FValue := SECURITY_MANDATORY_MEDIUM_RID;
  UpdateComboBoxValue;
end;

class function TUiLibIntegritySid.Factory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      ResultRef : TUiLibIntegritySid absolute Result;
    begin
      ResultRef := TUiLibIntegritySid.Create(AOwner);
      try
        if Assigned(InitialChoice) then
          ResultRef.Sid := InitialChoice;
      except
        ResultRef.Free;
        raise;
      end;
    end;
end;

function TUiLibIntegritySid.GetDefaultCaption;
begin
  Result := 'Integrity Level';
end;

function TUiLibIntegritySid.GetModalResult;
begin
  Result := GetSid;
end;

function TUiLibIntegritySid.GetSid;
begin
  RtlxCreateSid(Result, SECURITY_MANDATORY_LABEL_AUTHORITY,
    [FValue]).RaiseOnError;
end;

procedure TUiLibIntegritySid.SetSid;
begin
  SetValue(RtlxRidSid(Value));
end;

procedure TUiLibIntegritySid.SetValue;
begin
  if Value <> FValue then
  begin
    FValue := Value;
    UpdateTrackBarValue;
    UpdateComboBoxValue;
  end;
end;

procedure TUiLibIntegritySid.TrackBarChange;
begin
  FValue := TIntegrityRid(FTrackBar.Position);

  // Make known values slightly sticky
  if $800 - Abs(Integer(FValue and $FFF) - $800) < $1C000 / FTrackBar.Width then
    FValue := Round(FValue / $1000) * $1000;

  UpdateTrackBarValue;
  UpdateComboBoxValue;
end;

procedure TUiLibIntegritySid.UpdateComboBoxValue;
begin
  FComboBox.OnChange := nil;
  try
    FComboBox.Number := FValue;
  finally
    FComboBox.OnChange := ComboBoxChange;
  end;
end;

procedure TUiLibIntegritySid.UpdateTrackBarValue;
begin
  FTrackBar.OnChange := nil;
  try
    FTrackBar.Position := Integer(FValue);
  finally
    FTrackBar.OnChange := TrackBarChange;
  end;
end;

initialization
  UiLibFactoryIntegritySid := TUiLibIntegritySid.Factory;
end.
