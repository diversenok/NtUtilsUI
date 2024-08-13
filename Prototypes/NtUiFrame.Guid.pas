unit NtUiFrame.Guid;

{
  This module provides a control for specifying GUIDs.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, NtUtils;

type
  TGuidFrame = class(TFrame)
    tbxGuid: TEdit;
    procedure tbxGuidChange(Sender: TObject);
    procedure tbxGuidExit(Sender: TObject);
  private
    FGuid: TGuid;
    FGuidValid: Boolean;
    function GetGuid: TGuid;
    procedure SetGuid(const Value: TGuid);
  protected
    procedure FrameEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    function TryGetGuid(out Value: TGuid): TNtxStatus;
    property Guid: TGuid read GetGuid write SetGuid;
  end;

implementation

uses
  NtUtils.SysUtils, UI.Colors;

{$R *.dfm}

{ TGuidFrame }

procedure TGuidFrame.FrameEnabledChanged;
begin
  inherited;
  tbxGuid.Enabled := Enabled;
end;

function TGuidFrame.GetGuid;
begin
  TryGetGuid(Result).RaiseOnError;
end;

procedure TGuidFrame.SetGuid;
begin
  // Prevent recursion
  tbxGuid.OnChange := nil;
  Auto.Delay(
    procedure
    begin
      tbxGuid.OnChange := tbxGuidChange;
    end
  );

  FGuid := Value;
  FGuidValid := True;
  tbxGuid.Text := RtlxGuidToString(Value);
  tbxGuid.Color := clWindow;
end;

procedure TGuidFrame.tbxGuidChange;
begin
  FGuidValid := False;
  TryGetGuid(FGuid);
end;

procedure TGuidFrame.tbxGuidExit;
begin
  if not FGuidValid then
    SetGuid(Default(TGuid));
end;

function TGuidFrame.TryGetGuid;
begin
  if FGuidValid then
  begin
    Value := FGuid;
    Exit(NtxSuccess);
  end;

  Result := RtlxStringToGuid(tbxGuid.Text, FGuid);
  FGuidValid := Result.IsSuccess;

  if FGuidValid then
  begin
    Value := FGuid;
    tbxGuid.Color := clWindow;
  end
  else
    tbxGuid.Color := ColorSettings.clBackgroundError;
end;

end.
