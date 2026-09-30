unit NtUtilsUI.LogonId;

{
  This module contains a (stripped down) design-time component definition for
  a logon session ID context selection control.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, NtUtilsUI.Base, NtUtilsUI.StdCtrls;

type
  TLogonId = type UInt64;

  TUiLibLogonIdBox = class (TUiLibControl)
  private
    FOnChange: TNotifyEvent;
    FComboBox: TUiLibComboBox;
    FLogonId: TLogonId;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property LogonId: TLogonId read FLogonId write FLogonId default 0;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

procedure Register;

implementation

uses
  Vcl.Controls;

{$R 'Icons\TUiLibLogonIdBox.res'}

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibLogonIdBox]);
end;

{ TUiLibLogonIdBox }

constructor TUiLibLogonIdBox.Create;
begin
  inherited;

  Width := 300;
  Height := 23;

  FComboBox := TUiLibComboBox.Create(Self);
  FComboBox.Width := Width;
  FComboBox.Height := Height;
  FComboBox.Anchors := [akLeft, akTop, akRight, akBottom];
  FComboBox.Align := alClient;
  FComboBox.Text := '0x1234 5678 (User @ 1)';
  FComboBox.Parent := Self;
end;

end.
