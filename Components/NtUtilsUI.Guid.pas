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
    FGuid: TGuid;
    FValid: TNtxStatus;
    procedure EditChange(Sender: TObject);
    procedure EditExit(Sender: TObject);
    function GetGuid: TGuid;
    procedure SetGuid(const Value: TGuid);
    procedure UpdateFeedbackColor;
  public
    constructor Create(AOwner: TComponent); override;
    function TryGetGuid(out Value: TGuid): TNtxStatus;
    property Guid: TGuid read GetGuid write SetGuid;
  end;

implementation

uses
  Vcl.Controls, NtUtils.SysUtils, NtUtilsUI;

{ TUiLibGuidBox }

constructor TUiLibGuidBox.Create;
begin
  inherited;

  Width := 300;
  Height := 21;
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
  FValid := RtlxStringToGuid(FEdit.Text, FGuid);
  UpdateFeedbackColor;
end;

procedure TUiLibGuidBox.EditExit;
begin
  // Reset to the last valid GUID when leaving the control
  if not FValid.IsSuccess then
    SetGuid(FGuid);
end;

function TUiLibGuidBox.GetGuid;
begin
  FValid.RaiseOnError;
  Result := FGuid;
end;

procedure TUiLibGuidBox.SetGuid;
begin
  // The provided Guid is always valid
  FGuid := Value;
  FValid := NtxSuccess;

  // Format it
  FEdit.OnChange := nil;
  FEdit.Text := RtlxGuidToString(FGuid);
  FEdit.OnChange := EditChange;
  UpdateFeedbackColor;
end;

function TUiLibGuidBox.TryGetGuid;
begin
  Result := FValid;

  if Result.IsSuccess then
    Value := FGuid;
end;

procedure TUiLibGuidBox.UpdateFeedbackColor;
begin
  if FValid.IsSuccess then
    FEdit.Color := ColorSettings.clBackground
  else
    FEdit.Color := ColorSettings.clBackgroundError;
end;

end.
