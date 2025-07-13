unit NtUiFrame.Sid.Trust;

{
  This module includes a control for selecting trust/protection level SIDs.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ComCtrls, Ntapi.WinNt, NtUtils, NtUiCommon.Interfaces;

type
  TFrameTrustSid = class(TFrame, ICanConsumeEscape, IHasDefaultCaption,
    IHasModalResult)
    TrackBarType: TTrackBar;
    TrackBarLevel: TTrackBar;
    lblNoneType: TLabel;
    lblLight: TLabel;
    lblFull: TLabel;
    lblNoneLevel: TLabel;
    lblAntimalware: TLabel;
    lblWindows: TLabel;
    lblWinTcb: TLabel;
    cbxType: TComboBox;
    cbxLevel: TComboBox;
    procedure cbxTypeChange(Sender: TObject);
    procedure cbxLevelChange(Sender: TObject);
    procedure TrackBarTypeChange(Sender: TObject);
    procedure TrackBarLevelChange(Sender: TObject);
  private
    FType: TSecurityTrustType;
    FLevel: TSecurityTrustLevel;
    procedure UpdateTypeComboBox;
    procedure UpdateTypeTrackBar;
    procedure UpdateLevelComboBox;
    procedure UpdateLevelTrackBar;
    function GetSid: ISid;
    procedure SetSid(const Value: ISid);
  protected
    procedure Loaded; override;
    function ConsumesEscape: Boolean;
    function GetDefaultCaption: String;
    function GetModalResult: IInterface;
  public
    property Sid: ISid read GetSid write SetSid;
  end;

implementation

uses
  NtUtils.SysUtils, NtUtils.Security.Sid, NtUiCommon.Prototypes;

{$R *.dfm}

procedure TFrameTrustSid.cbxLevelChange;
begin
  case cbxLevel.ItemIndex of
    0: FLevel := SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID;
    1: FLevel := SECURITY_PROCESS_PROTECTION_LEVEL_AUTHENTICODE_RID;
    2: FLevel := SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID;
    3: FLevel := SECURITY_PROCESS_PROTECTION_LEVEL_APP_RID;
    4: FLevel := SECURITY_PROCESS_PROTECTION_LEVEL_WINDOWS_RID;
    5: FLevel := SECURITY_PROCESS_PROTECTION_LEVEL_WINTCB_RID;
  else
    if not RtlxStrToUInt(cbxLevel.Text, Cardinal(FLevel)) then
      Exit;
  end;

  UpdateLevelTrackBar;
end;

procedure TFrameTrustSid.cbxTypeChange;
begin
  case cbxType.ItemIndex of
    0: FType := SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID;
    1: FType := SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID;
    2: FType := SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID;
  else
    if not RtlxStrToUInt(cbxType.Text, Cardinal(FType)) then
      Exit;
  end;

  UpdateTypeTrackBar;
end;

function TFrameTrustSid.ConsumesEscape;
begin
  Result := cbxType.DroppedDown or cbxLevel.DroppedDown;
end;

function TFrameTrustSid.GetDefaultCaption;
begin
  Result := 'Trust SID';
end;

function TFrameTrustSid.GetModalResult;
begin
  Result := GetSid;
end;

function TFrameTrustSid.GetSid;
begin
  Result := RtlxMakeSid(SECURITY_PROCESS_TRUST_AUTHORITY, [FType, FLevel]);
end;

procedure TFrameTrustSid.Loaded;
begin
  inherited;
  FType := SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID;
  FLevel := SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID;
end;

procedure TFrameTrustSid.SetSid;
var
  SubAuthorities: TArray<Cardinal>;
begin
  if not Assigned(Value) then
    Exit;

  // Only accept valid trust SIDs
  if (RtlxIdentifierAuthoritySid(Value) = SECURITY_PROCESS_TRUST_AUTHORITY) and
    (RtlxSubAuthorityCountSid(Value) =
    SECURITY_PROCESS_TRUST_AUTHORITY_RID_COUNT) then
  begin
    SubAuthorities := RtlxSubAuthoritiesSid(Value);
    FType := SubAuthorities[0];
    FLevel := SubAuthorities[1];
  end
  else
  begin
    FType := SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID;
    FLevel := SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID;
  end;

  UpdateTypeComboBox;
  UpdateTypeTrackBar;
  UpdateLevelComboBox;
  UpdateLevelTrackBar;
end;

procedure TFrameTrustSid.TrackBarLevelChange;
begin
  FLevel := TrackBarLevel.Position;

  // Make known values slightly sticky
  if $100 - Abs(Integer(FLevel and $1FF) - $100) < $E000 / TrackBarLevel.Width then
    FLevel := Round(FLevel / $200) * $200;

  UpdateLevelTrackBar;
  UpdateLevelComboBox;
end;

procedure TFrameTrustSid.TrackBarTypeChange;
begin
  FType := TrackBarType.Position;

  // Make known values slightly sticky
  if $100 - Abs(Integer(FType and $1FF) - $100) < $2000 / TrackBarType.Width then
    FType := Round(FType / $200) * $200;

  UpdateTypeTrackBar;
  UpdateTypeComboBox;
end;

procedure TFrameTrustSid.UpdateLevelComboBox;
var
  OnChangeReverter: IAutoReleasable;
begin
  cbxLevel.OnChange := nil;
  OnChangeReverter := Auto.Defer(
    procedure
    begin
      cbxLevel.OnChange := cbxLevelChange;
    end
  );

  cbxLevel.ItemIndex := -1;
  case FLevel of
    SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID:         cbxLevel.ItemIndex := 0;
    SECURITY_PROCESS_PROTECTION_LEVEL_AUTHENTICODE_RID: cbxLevel.ItemIndex := 1;
    SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID:  cbxLevel.ItemIndex := 2;
    SECURITY_PROCESS_PROTECTION_LEVEL_APP_RID:          cbxLevel.ItemIndex := 3;
    SECURITY_PROCESS_PROTECTION_LEVEL_WINDOWS_RID:      cbxLevel.ItemIndex := 4;
    SECURITY_PROCESS_PROTECTION_LEVEL_WINTCB_RID:       cbxLevel.ItemIndex := 5;
  else
    cbxLevel.Text := RtlxUIntToStr(FLevel, nsHexadecimal, 4);
  end;
end;

procedure TFrameTrustSid.UpdateLevelTrackBar;
var
  OnChangeReverter: IAutoReleasable;
begin
  TrackBarLevel.OnChange := nil;
  OnChangeReverter := Auto.Defer(
    procedure
    begin
      TrackBarLevel.OnChange := TrackBarLevelChange;
    end
  );

  TrackBarLevel.Position := FLevel;
end;

procedure TFrameTrustSid.UpdateTypeComboBox;
var
  OnChangeReverter: IAutoReleasable;
begin
  cbxType.OnChange := nil;
  OnChangeReverter := Auto.Defer(
    procedure
    begin
      cbxType.OnChange := cbxTypeChange;
    end
  );

  cbxType.ItemIndex := -1;
  case FType of
    SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID: cbxType.ItemIndex := 0;
    SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID: cbxType.ItemIndex := 1;
    SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID: cbxType.ItemIndex := 2;
  else
    cbxType.Text := RtlxUIntToStr(FType, nsHexadecimal, 3);
  end;
end;

procedure TFrameTrustSid.UpdateTypeTrackBar;
var
  OnChangeReverter: IAutoReleasable;
begin
  TrackBarType.OnChange := nil;
  OnChangeReverter := Auto.Defer(
    procedure
    begin
      TrackBarType.OnChange := TrackBarTypeChange;
    end
  );

  TrackBarType.Position := FType;
end;

{ Integration }

function NtUiLibSelectTrust(
  Owner: TComponent;
  [opt] const DefaultSid: ISid = nil
): ISid;
var
  Selection: IInterface;
begin
  if not Assigned(NtUiLibHostFramePick) then
    raise ENotSupportedException.Create('Frame host not available');

  Selection := NtUiLibHostFramePick(Owner,
    function (AOwner: TComponent): TFrame
    var
      Frame: TFrameTrustSid absolute Result;
    begin
      Frame := TFrameTrustSid.Create(AOwner);
      try
        Frame.Sid := DefaultSid;
      except
        Frame.Free;
        raise;
      end;
    end
  );

  Result := Selection as ISid;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibSelectTrust := NtUiLibSelectTrust;
end.
