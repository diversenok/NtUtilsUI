unit NtUtilsUI.Sid.Trust;

{
  This module contains the full runtime component definition for
  an trust label SID selection control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, Vcl.StdCtrls, Vcl.ComCtrls, NtUtilsUI.Components.Factories,
  NtUtilsUI.Base, NtUtilsUI.StdCtrls, NtUtilsUI.Number, Ntapi.ntseapi, NtUtils;

type
  [DefaultCaption('Trust SID')]
  TUiLibTrustSid = class (TUiLibControl, IModalResult<ISid>)
  private
    FTypeValue: Cardinal;
    FLevelValue: Cardinal;
    FTypeComboBox: TUiLibNumberComboBox;
    FTypeTrackBar: TTrackBar;
    FLevelComboBox: TUiLibNumberComboBox;
    FLevelTrackBar: TTrackBar;
    FTypeLabelNone: TLabel;
    FTypeLabelLight: TLabel;
    FTypeLabelFull: TLabel;
    FLevelLabelNone: TLabel;
    FLevelLabelAntimalware: TLabel;
    FLevelLabelWindows: TLabel;
    FLevelLabelWinTcb: TLabel;
    procedure TypeComboBoxChange(Sender: TObject);
    procedure TypeTrackBarChange(Sender: TObject);
    procedure UpdateTypeComboBox;
    procedure UpdateTypeTrackBar;
    procedure LevelComboBoxChange(Sender: TObject);
    procedure LevelTrackBarChange(Sender: TObject);
    procedure UpdateLevelComboBox;
    procedure UpdateLevelTrackBar;
    function GetSid: ISid;
    procedure SetSid(const Value: ISid);
  private
    function GetModalResult: ISid;
  public
    constructor Create(AOwner: TComponent); override;
    class function Factory(const InitialChoice: ISid = nil): TWinControlFactory; static;
    property Sid: ISid read GetSid write SetSid;
  end;

implementation

uses
  Vcl.Controls, Ntapi.WinNt, NtUtils.SysUtils, NtUtils.Security.Sid;

{ TUiLibTrustSid }

constructor TUiLibTrustSid.Create;
begin
  inherited;

  Width := 400;
  Height := 185;
  Constraints.MinHeight := 185;
  Constraints.MinWidth := 330;
  ShowHint := True;

  { Type }

  FTypeComboBox := TUiLibNumberComboBox.Create(Self);
  FTypeComboBox.Width := 400;
  FTypeComboBox.Height := 21;
  FTypeComboBox.Anchors := [akLeft, akTop, akRight];
  FTypeComboBox.NumberBase := nsHexadecimal;
  FTypeComboBox.NumberSize := isCardinal;
  FTypeComboBox.NumberWidth := 3;
  FTypeComboBox.KnownValues.BeginUpdate;
  FTypeComboBox.KnownValues.Add(SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID, 'None (0x000)');
  FTypeComboBox.KnownValues.Add(SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID, 'Light (0x200)');
  FTypeComboBox.KnownValues.Add(SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID, 'Full (0x400)');
  FTypeComboBox.KnownValues.EndUpdate;
  FTypeComboBox.OnChange := TypeComboBoxChange;
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
  FTypeTrackBar.OnChange := TypeTrackBarChange;
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

  FLevelComboBox := TUiLibNumberComboBox.Create(Self);
  FLevelComboBox.Top := 99;
  FLevelComboBox.Width := 400;
  FLevelComboBox.Height := 21;
  FLevelComboBox.Anchors := [akLeft, akTop, akRight];
  FLevelComboBox.NumberBase := nsHexadecimal;
  FLevelComboBox.NumberSize := isCardinal;
  FLevelComboBox.NumberWidth := 4;
  FLevelComboBox.KnownValues.BeginUpdate;
  FLevelComboBox.KnownValues.Add(SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID, 'None (0x0000)');
  FLevelComboBox.KnownValues.Add(SECURITY_PROCESS_PROTECTION_LEVEL_AUTHENTICODE_RID, 'Authenticode (0x0400)');
  FLevelComboBox.KnownValues.Add(SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID, 'Antimalware (0x0600)');
  FLevelComboBox.KnownValues.Add(SECURITY_PROCESS_PROTECTION_LEVEL_APP_RID, 'Store App (0x0800)');
  FLevelComboBox.KnownValues.Add(SECURITY_PROCESS_PROTECTION_LEVEL_WINDOWS_RID, 'Windows (0x1000)');
  FLevelComboBox.KnownValues.Add(SECURITY_PROCESS_PROTECTION_LEVEL_WINTCB_RID, 'WinTcb (0x2000)');
  FLevelComboBox.KnownValues.EndUpdate;
  FLevelComboBox.OnChange := LevelComboBoxChange;
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
  FLevelTrackBar.OnChange := LevelTrackBarChange;
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

  FTypeValue := SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID;
  FLevelValue := SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID;
  UpdateTypeComboBox;
  UpdateLevelComboBox;
end;

class function TUiLibTrustSid.Factory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      ResultRef : TUiLibTrustSid absolute Result;
    begin
      ResultRef := TUiLibTrustSid.Create(AOwner);
      try
        if Assigned(InitialChoice) then
          ResultRef.Sid := InitialChoice;
      except
        ResultRef.Free;
        raise;
      end;
    end;
end;

function TUiLibTrustSid.GetModalResult;
begin
  Result := GetSid;
end;

function TUiLibTrustSid.GetSid;
begin
  RtlxCreateSid(Result, SECURITY_PROCESS_TRUST_AUTHORITY,
    [FTypeValue, FLevelValue]).RaiseOnError;
end;

procedure TUiLibTrustSid.LevelComboBoxChange;
begin
  FLevelValue := Cardinal(FLevelComboBox.Number);
  UpdateLevelTrackBar;
end;

procedure TUiLibTrustSid.LevelTrackBarChange;
begin
  FLevelValue := Cardinal(FLevelTrackBar.Position);

  // Make known values slightly sticky
  if $100 - Abs(Integer(FLevelValue and $1FF) - $100) <
    $E000 / FLevelTrackBar.Width then
    FLevelValue := Round(FLevelValue / $200) * $200;

  UpdateLevelTrackBar;
  UpdateLevelComboBox;
end;

procedure TUiLibTrustSid.SetSid;
begin
  if (RtlxIdentifierAuthoritySid(Value) = SECURITY_PROCESS_TRUST_AUTHORITY) and
    (RtlxSubAuthorityCountSid(Value) = SECURITY_PROCESS_TRUST_AUTHORITY_RID_COUNT) then
  begin
    FTypeValue := RtlxSubAuthoritySid(Value, 0);
    FLevelValue := RtlxSubAuthoritySid(Value, 1);
  end
  else
  begin
    FTypeValue := SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID;
    FLevelValue := SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID;
  end;

  UpdateTypeTrackBar;
  UpdateLevelTrackBar;
  UpdateTypeComboBox;
  UpdateLevelComboBox;
end;

procedure TUiLibTrustSid.TypeComboBoxChange;
begin
  FTypeValue := Cardinal(FTypeComboBox.Number);
  UpdateTypeTrackBar;
end;

procedure TUiLibTrustSid.TypeTrackBarChange;
begin
  FTypeValue := Cardinal(FTypeTrackBar.Position);

  // Make known values slightly sticky
  if $100 - Abs(Integer(FTypeValue and $1FF) - $100) <
    $2000 / FTypeTrackBar.Width then
    FTypeValue := Round(FTypeValue / $200) * $200;

  UpdateTypeTrackBar;
  UpdateTypeComboBox;
end;

procedure TUiLibTrustSid.UpdateLevelComboBox;
begin
  FLevelComboBox.OnChange := nil;
  try
    FLevelComboBox.Number := FLevelValue;
  finally
    FLevelComboBox.OnChange := LevelComboBoxChange;
  end;
end;

procedure TUiLibTrustSid.UpdateLevelTrackBar;
begin
  FLevelTrackBar.OnChange := nil;
  try
    FLevelTrackBar.Position := Integer(FLevelValue);
  finally
    FLevelTrackBar.OnChange := LevelTrackBarChange;
  end;
end;

procedure TUiLibTrustSid.UpdateTypeComboBox;
begin
  FTypeComboBox.OnChange := nil;
  try
    FTypeComboBox.Number := FTypeValue;
  finally
    FTypeComboBox.OnChange := TypeComboBoxChange;
  end;
end;

procedure TUiLibTrustSid.UpdateTypeTrackBar;
begin
  FTypeTrackBar.OnChange := nil;
  try
    FTypeTrackBar.Position := Integer(FTypeValue);
  finally
    FTypeTrackBar.OnChange := TypeTrackBarChange;
  end;
end;

initialization
  UiLibFactoryTrustSid := TUiLibTrustSid.Factory;
end.
