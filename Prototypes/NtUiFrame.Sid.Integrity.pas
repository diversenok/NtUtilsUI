unit NtUiFrame.Sid.Integrity;

{
  This module includes a control for selecting integrity levels.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.StdCtrls, NtUiCommon.Interfaces, Ntapi.WinNt, Ntapi.ntseapi, NtUtils;

type
  TFrameIntegrity = class(TFrame, ICanConsumeEscape, IHasDefaultCaption,
    IHasModalResult)
    ComboBox: TComboBox;
    lblUntrusted: TLabel;
    lblSystem: TLabel;
    lblMedium: TLabel;
    lblHigh: TLabel;
    lblLow: TLabel;
    TrackBar: TTrackBar;
    procedure ComboBoxChange(Sender: TObject);
    procedure TrackBarChange(Sender: TObject);
  private
    FValue: TIntegrityRid;
    procedure UpdateComboBoxValue;
    procedure UpdateTrackBarValue;
    procedure SetValue(const Value: TIntegrityRid);
    function GetSid: ISid;
    procedure SetSid(const Value: ISid);
  protected
    procedure Loaded; override;
    function ConsumesEscape: Boolean;
    function GetDefaultCaption: String;
    function GetModalResult: IInterface;
  public
    property Value: TIntegrityRid read FValue write SetValue;
    property Sid: ISid read GetSid write SetSid;
  end;

implementation

uses
  DelphiUiLib.Strings, NtUtils.Security.Sid, NtUiCommon.Prototypes;

{$R *.dfm}

procedure TFrameIntegrity.ComboBoxChange;
begin
  case ComboBox.ItemIndex of
    0: FValue := SECURITY_MANDATORY_UNTRUSTED_RID;
    1: FValue := SECURITY_MANDATORY_LOW_RID;
    2: FValue := SECURITY_MANDATORY_MEDIUM_RID;
    3: FValue := SECURITY_MANDATORY_MEDIUM_PLUS_RID;
    4: FValue := SECURITY_MANDATORY_HIGH_RID;
    5: FValue := SECURITY_MANDATORY_SYSTEM_RID;
    6: FValue := SECURITY_MANDATORY_PROTECTED_PROCESS_RID;
  else
    if not UiLibStringToUInt(ComboBox.Text, Cardinal(FValue)) then
      Exit;
  end;

  UpdateTrackBarValue;
end;

function TFrameIntegrity.ConsumesEscape;
begin
  Result := ComboBox.DroppedDown;
end;

function TFrameIntegrity.GetDefaultCaption;
begin
  Result := 'Integrity Level';
end;

function TFrameIntegrity.GetModalResult;
begin
  Result := GetSid;
end;

function TFrameIntegrity.GetSid;
begin
  Result := RtlxMakeSid(SECURITY_MANDATORY_LABEL_AUTHORITY, [FValue]);
end;

procedure TFrameIntegrity.Loaded;
begin
  inherited;
  FValue := SECURITY_MANDATORY_MEDIUM_RID;
end;

procedure TFrameIntegrity.SetSid;
begin
  if Assigned(Value) and (RtlxIdentifierAuthoritySid(Value) =
    SECURITY_MANDATORY_LABEL_AUTHORITY) then
    SetValue(RtlxRidSid(Value));
end;

procedure TFrameIntegrity.SetValue;
begin
  FValue := Value;
  UpdateComboBoxValue;
  UpdateTrackBarValue;
end;

procedure TFrameIntegrity.TrackBarChange;
begin
  FValue := TrackBar.Position;

  // Make known values slightly sticky
  if $800 - Abs(Integer(FValue and $FFF) - $800) < $1C000 / TrackBar.Width then
    FValue := Round(FValue / $1000) * $1000;

  UpdateTrackBarValue;
  UpdateComboBoxValue;
end;

procedure TFrameIntegrity.UpdateComboBoxValue;
var
  OnChangeReverter: IDeferredOperation;
begin
  ComboBox.OnChange := nil;
  OnChangeReverter := Auto.Defer(
    procedure
    begin
      ComboBox.OnChange := ComboBoxChange;
    end
  );

  ComboBox.ItemIndex := -1;
  case FValue of
    SECURITY_MANDATORY_UNTRUSTED_RID:         ComboBox.ItemIndex := 0;
    SECURITY_MANDATORY_LOW_RID:               ComboBox.ItemIndex := 1;
    SECURITY_MANDATORY_MEDIUM_RID:            ComboBox.ItemIndex := 2;
    SECURITY_MANDATORY_MEDIUM_PLUS_RID:       ComboBox.ItemIndex := 3;
    SECURITY_MANDATORY_HIGH_RID:              ComboBox.ItemIndex := 4;
    SECURITY_MANDATORY_SYSTEM_RID:            ComboBox.ItemIndex := 5;
    SECURITY_MANDATORY_PROTECTED_PROCESS_RID: ComboBox.ItemIndex := 6;
  else
    ComboBox.Text := UiLibUIntToHex(FValue, 4);
  end;
end;

procedure TFrameIntegrity.UpdateTrackBarValue;
var
  OnChangeReverter: IDeferredOperation;
begin
  TrackBar.OnChange := nil;
  OnChangeReverter := Auto.Defer(
    procedure
    begin
      TrackBar.OnChange := TrackBarChange;
    end
  );

  TrackBar.Position := FValue;
end;

{ Integration }

function NtUiLibSelectIntegrity(
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
      Frame: TFrameIntegrity absolute Result;
    begin
      Frame := TFrameIntegrity.Create(AOwner);
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
  NtUiCommon.Prototypes.NtUiLibSelectIntegrity := NtUiLibSelectIntegrity;
end.
