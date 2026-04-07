unit NtUtilsUI.Sid.Integrity;

{
  This module contains the full runtime component definition for
  an integrity level selection control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, Vcl.StdCtrls, Vcl.ComCtrls, NtUtilsUI, NtUtilsUI.StdCtrls,
  Ntapi.ntseapi, NtUtils;

type
  // A control for selecting an integrity level or SID
  TUiLibIntegritySid = class (TUiLibControl, IHasDefaultCaption, IHasModalResult)
  private
    FValue: TIntegrityRid;
    FTrackBar: TTrackBar;
    FComboBox: TUiLibComboBox;
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
    function GetModalResult: IInterface;
  protected
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    class function Factory(const InitialChoice: ISid = nil): TWinControlFactory; static;
    class function Pick(
      AOwner: TComponent;
      [opt] const InitialChoice: ISid = nil
    ): ISid; static;
    property Rid: TIntegrityRid read FValue write SetValue;
    property Sid: ISid read GetSid write SetSid;
end;

implementation

uses
  Vcl.Controls, Ntapi.WinNt, NtUtils.Security.Sid, DelphiUiLib.Strings,
  NtUtilsUI.Components;

{
  Potential improvements:
   - Hints showing the RID value in decimal
   - Highlight the combobox in red on invalid input
}

{ TUiLibIntegritySid }

procedure TUiLibIntegritySid.ComboBoxChange;
begin
  case FComboBox.ItemIndex of
    0: FValue := SECURITY_MANDATORY_UNTRUSTED_RID;
    1: FValue := SECURITY_MANDATORY_LOW_RID;
    2: FValue := SECURITY_MANDATORY_MEDIUM_RID;
    3: FValue := SECURITY_MANDATORY_MEDIUM_PLUS_RID;
    4: FValue := SECURITY_MANDATORY_HIGH_RID;
    5: FValue := SECURITY_MANDATORY_SYSTEM_RID;
    6: FValue := SECURITY_MANDATORY_PROTECTED_PROCESS_RID;
  else
    if not UiLibStringToUInt(FComboBox.Text, Cardinal(FValue)) then
      Exit;
  end;

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

  FValue := SECURITY_MANDATORY_MEDIUM_RID;
end;

procedure TUiLibIntegritySid.CreateWnd;
begin
  inherited;

  FComboBox.Items.AddStrings([
    'Untrusted (0x0000)',
    'Low (0x1000)',
    'Medium (0x2000)',
    'Medium Plus (0x2100)',
    'High (0x3000)',
    'System (0x4000)',
    'Protected (0x5000)'
  ]);
  UpdateComboBoxValue;

  FComboBox.OnChange := ComboBoxChange;
  FTrackBar.OnChange := TrackBarChange;
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

class function TUiLibIntegritySid.Pick;
begin
  Result := ISid(UiLibPick(AOwner, TUiLibIntegritySid.Factory(InitialChoice)));
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
  FValue := FTrackBar.Position;

  // Make known values slightly sticky
  if $800 - Abs(Integer(FValue and $FFF) - $800) < $1C000 / FTrackBar.Width then
    FValue := Round(FValue / $1000) * $1000;

  UpdateTrackBarValue;
  UpdateComboBoxValue;
end;

procedure TUiLibIntegritySid.UpdateComboBoxValue;
var
  OnChangeReverter: IDeferredOperation;
begin
  // Before handle allocation, the combo box is not populated yet
  if not HandleAllocated then
    Exit;

  FComboBox.OnChange := nil;
  OnChangeReverter := Auto.Defer(
    procedure
    begin
      FComboBox.OnChange := ComboBoxChange;
    end
  );

  // Choosing the item automatically selects its text
  FComboBox.ItemIndex := -1;
  case FValue of
    SECURITY_MANDATORY_UNTRUSTED_RID:         FComboBox.ItemIndex := 0;
    SECURITY_MANDATORY_LOW_RID:               FComboBox.ItemIndex := 1;
    SECURITY_MANDATORY_MEDIUM_RID:            FComboBox.ItemIndex := 2;
    SECURITY_MANDATORY_MEDIUM_PLUS_RID:       FComboBox.ItemIndex := 3;
    SECURITY_MANDATORY_HIGH_RID:              FComboBox.ItemIndex := 4;
    SECURITY_MANDATORY_SYSTEM_RID:            FComboBox.ItemIndex := 5;
    SECURITY_MANDATORY_PROTECTED_PROCESS_RID: FComboBox.ItemIndex := 6;
  else
    FComboBox.Text := UiLibUIntToHex(FValue, 4);
  end;
end;

procedure TUiLibIntegritySid.UpdateTrackBarValue;
var
  OnChangeReverter: IDeferredOperation;
begin
  FTrackBar.OnChange := nil;
  OnChangeReverter := Auto.Defer(
    procedure
    begin
      FTrackBar.OnChange := TrackBarChange;
    end
  );

  FTrackBar.Position := FValue;
end;

initialization
  UiLibHostPickIntegritySid := TUiLibIntegritySid.Pick;
end.
