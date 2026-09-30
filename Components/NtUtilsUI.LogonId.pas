unit NtUtilsUI.LogonId;

{
  This module contains the full runtime component definition for
  a logon session ID selection control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, NtUtilsUI.Base, NtUtilsUI.Number, Ntapi.WinNt,
  NtUtilsUI.Components.Factories;

type
  [DefaultCaption('Logon Session ID')]
  TUiLibLogonIdBox = class (TUiLibControl, IModalResult<TLogonId>)
  private
    FOnChange: TNotifyEvent;
    FComboBox: TUiLibNumberComboBox;
    FRefreshShortcut: TUiLibShortCut;
    procedure RefreshShortcut(Sender: TObject; ShortCut: TShortCut; var Handled: Boolean);
    procedure ComboBoxChange(Sender: TObject);
    function GetLogonId: TLogonId;
    procedure SetLogonId(Value: TLogonId);
    function GetModalResult: TLogonId;
    function GetModalResultType: Pointer;
  protected
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Refresh(SelectCurrent: Boolean = False);
    class function Factory(InitialChoice: TLogonId = TLogonId(-1)): TWinControlFactory; static;
  published
    property LogonId: TLogonId read GetLogonId write SetLogonId default 0;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  Winapi.Windows, Ntapi.ntseapi, NtUtils.SysUtils, NtUtils.Lsa.Logon, NtUtils,
  NtUtils.Tokens.Info, DelphiUiLib.LiteReflection,
  DelphiUiLib.LiteReflection.Types, Vcl.Controls, NtUtilsUI;

{ TUiLibLogonIdBox }

procedure TUiLibLogonIdBox.ComboBoxChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TUiLibLogonIdBox.Create;
begin
  inherited;

  Width := 300;
  Height := 23;
  Constraints.MinHeight := 23;
  Constraints.MinWidth := 150;

  FComboBox := TUiLibNumberComboBox.Create(Self);
  FComboBox.Width := Width;
  FComboBox.Height := Height;
  FComboBox.Anchors := [akLeft, akTop, akRight, akBottom];
  FComboBox.Align := alClient;
  FComboBox.NumberBase := nsHexadecimal;
  FComboBox.NumberSize := isUInt64;
  FComboBox.Parent := Self;

  FRefreshShortcut := TUiLibShortCut.Create(Self);
  FRefreshShortcut.ShortCut := VK_F5;
  FRefreshShortcut.OnExecute := RefreshShortcut;
end;

procedure TUiLibLogonIdBox.CreateWnd;
begin
  inherited;
  Refresh(True);
  FComboBox.OnChange := ComboBoxChange;
end;

class function TUiLibLogonIdBox.Factory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      ResultRef : TUiLibLogonIdBox absolute Result;
    begin
      ResultRef := TUiLibLogonIdBox.Create(AOwner);
      try
        if InitialChoice <> TLogonId(-1) then
          ResultRef.LogonId := InitialChoice;
      except
        ResultRef.Free;
        raise;
      end;
    end;
end;

function TUiLibLogonIdBox.GetLogonId;
begin
  Result := FComboBox.Number;
end;

function TUiLibLogonIdBox.GetModalResult;
begin
  Result := GetLogonId;
end;

function TUiLibLogonIdBox.GetModalResultType;
begin
  Result := TypeInfo(Ntapi.WinNt.TLogonId);
end;

procedure TUiLibLogonIdBox.Refresh;
var
  Luids: TArray<TLogonId>;
  Statistics: TTokenStatistics;
  i: Integer;
begin
  FComboBox.KnownValues.BeginUpdateAuto;
  FComboBox.KnownValues.Clear;
  LsaxEnumerateLogonSessions(Luids);

  for i := 0 to High(Luids) do
    FComboBox.KnownValues.Add(Luids[i],
      Rttix.Format(Luids[i]));

  if SelectCurrent then
  begin
    if NtxToken.Query(NtxCurrentEffectiveToken, TokenStatistics,
      Statistics).IsSuccess then
      FComboBox.Number := Statistics.AuthenticationId
    else
      FComboBox.Number := ANONYMOUS_LOGON_LUID;
  end;
end;

procedure TUiLibLogonIdBox.RefreshShortcut;
begin
  Refresh;
end;

procedure TUiLibLogonIdBox.SetLogonId;
begin
  FComboBox.Number := Value;
end;

initialization
  RttixRegisterLogonIdFormatter;
  UiLibFactoryLogonId := TUiLibLogonIdBox.Factory;
end.
