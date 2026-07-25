unit NtUtilsUI.UmgrContext;

{
  This module contains a (stripped down) design-time component definition for
  a user manager context selection control.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, NtUtilsUI.Base, NtUtilsUI.StdCtrls;

type
  TUmgrContext = type UInt64;

  TUiLibUmgrContextBox = class (TUiLibControl)
  private
    FOnChange: TNotifyEvent;
    FComboBox: TUiLibComboBox;
    FUserContext: TUmgrContext;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property UserContext: TUmgrContext read FUserContext write FUserContext default 0;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

procedure Register;

implementation

uses
  Vcl.Controls;

{$R 'Icons\TUiLibUmgrContextBox.res'}

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibUmgrContextBox]);
end;

{ TUiLibUmgrContextBox }

constructor TUiLibUmgrContextBox.Create;
begin
  inherited;

  Width := 260;
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
