unit NtUiFrame.Hex.Edit;

{
  This module includes a simple control for viewing/editing binary data as hex.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, NtUtils;

type
  THexEditFrame = class(TFrame)
    tbxHexString: TEdit;
    procedure tbxHexStringChange(Sender: TObject);
    procedure tbxHexStringExit(Sender: TObject);
  private
    FOnDataChanged: TNotifyEvent;
    FData: IMemory;
    function GetData: IMemory;
    procedure SetData(const Value: IMemory);
    procedure UpdateHint;
  protected
    procedure FrameEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    function TryGetData(out Value: IMemory): Boolean;
    property Data: IMemory read GetData write SetData;
    property OnDataChange: TNotifyEvent read FOnDataChanged write FOnDataChanged;
  end;

implementation

uses
  NtUiBackend.HexView, UI.Colors, DelphiUiLib.Reflection.Strings,
  DelphiUiLib.Strings;

{$R *.dfm}

{ THexEditFrame }

procedure THexEditFrame.FrameEnabledChanged;
begin
  inherited;
  tbxHexString.Enabled := Enabled;
end;

function THexEditFrame.GetData;
begin
  if not TryGetData(Result) then
    raise EParserError.Create('Invalid hexadecimal data specified.');
end;

procedure THexEditFrame.SetData;
begin
  // Prevent recursive calls
  tbxHexString.OnChange := nil;
  Auto.Delay(
    procedure
    begin
      tbxHexString.OnChange := tbxHexStringChange;
    end
  );

  FData := Value;
  tbxHexString.Text := UiLibRepresentHexData(Value);
  tbxHexString.Color := clWindow;
  UpdateHint;
end;

procedure THexEditFrame.tbxHexStringChange;
begin
  // Refresh the cached data
  FData := nil;
  TryGetData(FData);

  if Assigned(FOnDataChanged) then
    FOnDataChanged(Self);
end;

procedure THexEditFrame.tbxHexStringExit;
begin
  SetData(FData);
end;

function THexEditFrame.TryGetData;
begin
  // Use cached data when available
  if Assigned(FData) then
  begin
    Value := FData;
    Result := True;
    Exit;
  end;

  Result := UiLibParseHexData(tbxHexString.Text, FData);

  if Result then
    tbxHexString.Color := clWindow
  else
    tbxHexString.Color := ColorSettings.clBackgroundError;

  UpdateHint;
end;

procedure THexEditFrame.UpdateHint;
begin
  if Assigned(FData) then
    tbxHexString.Hint := BuildHint([
      THintSection.New('Number of bytes (dec)', IntToStrEx(FData.Size)),
      THintSection.New('Number of bytes (hex)', IntToHexEx(FData.Size))
    ])
  else
    tbxHexString.Hint := '';
end;

end.
