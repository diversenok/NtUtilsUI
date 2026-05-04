unit NtUtilsUI.SessionID;

{
  This module contains the full runtime component definition for
  a session ID selection control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, NtUtilsUI.Base, NtUtilsUI.Number, Ntapi.WinNt,
  NtUtilsUI.Components.Factories;

type
  [DefaultCaption('Session ID')]
  TUiLibSessionIdBox = class (TUiLibControl, IModalResult<TSessionId>)
  private
    FComboBox: TUiLibNumberComboBox;
    FRefreshShortcut: TUiLibShortCut;
    procedure RefreshShortcut(Sender: TUiLibShortCut; var Handled: Boolean);
    function GetSessionID: TSessionId;
    procedure SetSessionID(Value: TSessionId);
    function GetModalResult: TSessionId;
  protected
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Refresh;
    class function Factory(InitialChoice: TSessionId): TWinControlFactory; static;
  published
    property SessionID: TSessionId read GetSessionID write SetSessionID;
  end;

implementation

uses
  Winapi.Windows, Ntapi.ntpebteb, NtUtils.SysUtils, NtUtils.WinStation,
  DelphiUiLib.LiteReflection, DelphiUiLib.LiteReflection.Types, Vcl.Controls,
  NtUtilsUI;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TUiLibSessionIdBox }

constructor TUiLibSessionIdBox.Create;
begin
  inherited;

  Width := 240;
  Height := 23;
  Constraints.MinHeight := 23;
  Constraints.MinWidth := 150;

  FComboBox := TUiLibNumberComboBox.Create(Self);
  FComboBox.Width := Width;
  FComboBox.Height := Height;
  FComboBox.Anchors := [akLeft, akTop, akRight];
  FComboBox.NumberBase := nsDecimal;
  FComboBox.NumberSize := isCardinal;
  FComboBox.Parent := Self;

  FRefreshShortcut := TUiLibShortCut.Create(Self);
  FRefreshShortcut.ShortCut := VK_F5;
  FRefreshShortcut.OnExecute := RefreshShortcut;
end;

procedure TUiLibSessionIdBox.CreateWnd;
begin
  inherited;
  Refresh;
  FComboBox.Number := RtlGetCurrentPeb.SessionID;
end;

class function TUiLibSessionIdBox.Factory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      ResultRef : TUiLibSessionIdBox absolute Result;
    begin
      ResultRef := TUiLibSessionIdBox.Create(AOwner);
      try
        ResultRef.SessionID := InitialChoice;
      except
        ResultRef.Free;
        raise;
      end;
    end;
end;

function TUiLibSessionIdBox.GetModalResult;
begin
  Result := GetSessionID;
end;

function TUiLibSessionIdBox.GetSessionID;
begin
  Result := TSessionId(FComboBox.Number);
end;

procedure TUiLibSessionIdBox.Refresh;
var
  ID: TSessionId;
begin
  FComboBox.KnownValues.BeginUpdateAuto;
  FComboBox.KnownValues.Clear;

  for ID in WsxEnumerateSessionIDsWithFallback do
    FComboBox.KnownValues.Add(ID, Rttix.Format(ID));
end;

procedure TUiLibSessionIdBox.RefreshShortcut;
begin
  Refresh;
end;

procedure TUiLibSessionIdBox.SetSessionID;
begin
  if Value = TSessionId(-1) then
    Value := RtlGetCurrentPeb.SessionID;

  FComboBox.Number := Value;
end;

initialization
  RttixRegisterSessionIdFormatter;
  UiLibFactorySessionId := TUiLibSessionIdBox.Factory;
end.
