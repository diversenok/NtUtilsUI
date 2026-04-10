unit NtUtilsUI.Guid;

{
  This module contains the full runtime component definition for the GUID
  selection control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, NtUtils, NtUtilsUI.Base, NtUtilsUI.StdCtrls;

type
  TUiLibGuidBox = class (TUiLibControl)
  private
    FEdit: TUiLibEdit;
    FGuid, FFallbackGuid: TGuid;
    FGuidValid: TNtxStatus;
    procedure EditChange(Sender: TObject);
    procedure EditExit(Sender: TObject);
    function GetGuid: TGuid;
    procedure SetGuid(const Value: TGuid);
    procedure UpdateFeedbackColor;
  public
    constructor Create(AOwner: TComponent); override;
    function TryGetGuid(out Value: TGuid): TNtxStatus;
    property Guid: TGuid read GetGuid write SetGuid;
    property FallbackGuid: TGuid read FFallbackGuid write FFallbackGuid;
  end;

implementation

uses
  Vcl.Controls, NtUtils.SysUtils, NtUtilsUI;

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
  FEdit.OnChange := EditChange;
  FEdit.OnExit := EditExit;
end;

procedure TUiLibGuidBox.EditChange;
begin
  // Attempt to parse it
  FGuidValid := RtlxStringToGuid(FEdit.Text, FGuid);
  UpdateFeedbackColor;
end;

procedure TUiLibGuidBox.EditExit;
begin
  // Reset invalid GUIDs when leaving the control
  if not FGuidValid.IsSuccess then
    SetGuid(FFallbackGuid);
end;

function TUiLibGuidBox.GetGuid;
begin
  FGuidValid.RaiseOnError;
  Result := FGuid;
end;

procedure TUiLibGuidBox.SetGuid;
begin
  // The provided Guid is always valid
  FGuid := Value;
  FFallbackGuid := Value;
  FGuidValid := NtxSuccess;

  // Format it
  FEdit.OnChange := nil;
  FEdit.Text := RtlxGuidToString(FGuid);
  FEdit.OnChange := EditChange;
  UpdateFeedbackColor;
end;

function TUiLibGuidBox.TryGetGuid;
begin
  Result := FGuidValid;

  if Result.IsSuccess then
    Value := FGuid;
end;

procedure TUiLibGuidBox.UpdateFeedbackColor;
begin
  if FGuidValid.IsSuccess then
    FEdit.Color := ColorSettings.clBackground
  else
    FEdit.Color := ColorSettings.clBackgroundError;
end;

end.
