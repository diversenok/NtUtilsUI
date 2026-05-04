unit NtUtilsUI.SessionID;

{
  This module contains a (stripped down) design-time component definition for
  a session ID selection control.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, NtUtilsUI.Base, NtUtilsUI.StdCtrls;

type
  TSessionId = type Cardinal;

  TUiLibSessionIdBox = class (TUiLibControl)
  private
    FComboBox: TUiLibComboBox;
    FSessionId: TSessionId;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property SessionID: TSessionId read FSessionId write FSessionId default TSessionId(-1);
  end;

procedure Register;

implementation

uses
  Vcl.Controls;

{$R 'Icons\TUiLibSessionIdBox.res'}

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibSessionIdBox]);
end;

{ TUiLibSessionIdBox }

constructor TUiLibSessionIdBox.Create;
begin
  inherited;

  Width := 240;
  Height := 23;

  FComboBox := TUiLibComboBox.Create(Self);
  FComboBox.Width := Width;
  FComboBox.Height := Height;
  FComboBox.Anchors := [akLeft, akTop, akRight];
  FComboBox.Text := '1: Console';
  FComboBox.Parent := Self;

  FSessionId := TSessionId(-1);
end;
end.
