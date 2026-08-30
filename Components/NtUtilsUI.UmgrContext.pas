unit NtUtilsUI.UmgrContext;

{
  This module contains the full runtime component definition for
  a user manager context selection control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, NtUtilsUI.Base, NtUtilsUI.Number, Ntapi.WinNt,
  NtUtilsUI.Components.Factories;

type
  [DefaultCaption('User Manager Context')]
  TUiLibUmgrContextBox = class (TUiLibControl, IModalResult<TUmgrContext>)
  private
    FOnChange: TNotifyEvent;
    FComboBox: TUiLibNumberComboBox;
    FRefreshShortcut: TUiLibShortCut;
    procedure RefreshShortcut(Sender: TObject; ShortCut: TShortCut; var Handled: Boolean);
    procedure ComboBoxChange(Sender: TObject);
    function GetUserContext: TUmgrContext;
    procedure SetUserContext(Value: TUmgrContext);
    function GetModalResult: TUmgrContext;
    function GetModalResultType: Pointer;
  protected
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Refresh(SelectCurrentSession: Boolean = False);
    class function Factory(InitialChoice: TUmgrContext): TWinControlFactory; static;
  published
    property UserContext: TUmgrContext read GetUserContext write SetUserContext default 0;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  Winapi.Windows, Ntapi.ntpebteb, NtUtils.SysUtils, NtUtils.UserManager,
  DelphiUiLib.LiteReflection, DelphiUiLib.LiteReflection.Types, Vcl.Controls,
  NtUtilsUI;

{ TUiLibUmgrContextBox }

procedure TUiLibUmgrContextBox.ComboBoxChange;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TUiLibUmgrContextBox.Create;
begin
  inherited;

  Width := 260;
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

procedure TUiLibUmgrContextBox.CreateWnd;
begin
  inherited;
  Refresh(True);
  FComboBox.OnChange := ComboBoxChange;
end;

class function TUiLibUmgrContextBox.Factory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      ResultRef : TUiLibUmgrContextBox absolute Result;
    begin
      ResultRef := TUiLibUmgrContextBox.Create(AOwner);
      try
        ResultRef.UserContext := InitialChoice;
      except
        ResultRef.Free;
        raise;
      end;
    end;
end;

function TUiLibUmgrContextBox.GetModalResult;
begin
  Result := GetUserContext;
end;

function TUiLibUmgrContextBox.GetModalResultType;
begin
  Result := TypeInfo(Ntapi.WinNt.TUmgrContext);
end;

function TUiLibUmgrContextBox.GetUserContext;
begin
  Result := Ntapi.WinNt.TUmgrContext(FComboBox.Number);
end;

procedure TUiLibUmgrContextBox.Refresh;
var
  ContextInfo: TArray<TUmgrxContextInfo>;
  i: Integer;
begin
  FComboBox.KnownValues.BeginUpdateAuto;
  FComboBox.KnownValues.Clear;
  RtlxUmgrEnumerateContexts(ContextInfo);

  for i := 0 to High(ContextInfo) do
    FComboBox.KnownValues.Add(ContextInfo[i].UserContext,
      Rttix.Format(ContextInfo[i]));

  if SelectCurrentSession then
    for i := 0 to High(ContextInfo) do
      if ContextInfo[i].SessionId = RtlGetCurrentPeb.SessionID then
      begin
        FComboBox.Number := ContextInfo[i].UserContext;
        Break;
      end;
end;

procedure TUiLibUmgrContextBox.RefreshShortcut;
begin
  Refresh;
end;

procedure TUiLibUmgrContextBox.SetUserContext;
begin
  FComboBox.Number := Value;
end;

initialization
  RttixRegisterUmgrFormatter;
end.
