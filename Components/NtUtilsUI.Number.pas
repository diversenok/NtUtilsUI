unit NtUtilsUI.Number;

{
  This module contains the full runtime component definition for the number
  selection control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, NtUtilsUI.Base, NtUtilsUI.StdCtrls, NtUtils.SysUtils;

type
  TUiLibNumberBox = class (TUiLibControl)
  private
    FEdit: TUiLibEdit;
    FNumber: UInt64;
    FValid: Boolean;
    FNumberBase: TNumericSystem;
    FNumberSize: TIntegerSize;
    FNumberWidth: Byte;
    FNumberSign: TIntegerSign;
    FOnChange: TNotifyEvent;
    procedure EditChange(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function GetNumber: UInt64;
    procedure SetNumber(const Value: UInt64);
    procedure UpdateFeedback;
    procedure SetNumberBase(const Value: TNumericSystem);
    procedure SetNumberSign(const Value: TIntegerSign);
    procedure SetNumberSize(const Value: TIntegerSize);
    procedure SetNumberWidth(const Value: Byte);
    procedure Reformat;
  public
    constructor Create(AOwner: TComponent); override;
    function TryGetNumber(out Value: UInt64): Boolean;
  published
    property Number: UInt64 read GetNumber write SetNumber default 0;
    property NumberBase: TNumericSystem read FNumberBase write SetNumberBase default nsHexadecimal;
    property NumberSize: TIntegerSize read FNumberSize write SetNumberSize default isUInt64;
    property NumberWidth: Byte read FNumberWidth write SetNumberWidth default NUMERIC_WIDTH_ROUND_TO_GROUP;
    property NumberSign: TIntegerSign read FNumberSign write SetNumberSign default isUnsigned;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, Vcl.Controls, NtUtilsUI, DelphiUiLib.Strings;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TUiLibNumberBox }

constructor TUiLibNumberBox.Create;
begin
  inherited;

  Width := 150;
  Height := 21;
  Constraints.MinWidth := 100;

  FEdit := TUiLibEdit.Create(Self);
  FEdit.Width := Width;
  FEdit.Height := Height;
  FEdit.Align := alClient;
  FEdit.Parent := Self;
  FEdit.OnChange := EditChange;
  FEdit.OnExit := EditExit;
  FEdit.OnKeyDown := EditKeyDown;

  FNumberBase := nsHexadecimal;
  FNumberSize := isUInt64;
  FNumberWidth := NUMERIC_WIDTH_ROUND_TO_GROUP;
  FNumberSign := isUnsigned;
  FValid := True;
  Reformat;
end;

procedure TUiLibNumberBox.EditChange;
begin
  // Attempt to parse the input while being as flexible as possible
  FValid := RtlxStrToUInt64(FEdit.Text, FNumber, nsDecimal, [nsDecimal,
    nsHexadecimal], True, NUMERIC_SPACES_ALL, FNumberSize);
  UpdateFeedback;

  if FValid and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TUiLibNumberBox.EditExit;
begin
  // Reset to the last valid number before leaving the control
  if not FValid then
    SetNumber(FNumber);
end;

procedure TUiLibNumberBox.EditKeyDown;
const
  INCREMENT_VALUE: array [TNumericSystem, 0..3] of Cardinal = (
    (1, 10, 1000, 100000),
    (1, $10, $1000, $100000)
  );
var
  NewValue, Increment: UInt64;
begin
  // Allow incrementing/decrementing the value similar to an up-down control
  if FValid and ((Ord(Key) = VK_UP) or (Ord(Key) = VK_DOWN)) and
    (Shift - [ssShift, ssCtrl] = []) then
  begin
    if Shift = [] then
      Increment := INCREMENT_VALUE[FNumberBase, 0]
    else if Shift = [ssShift] then
      Increment := INCREMENT_VALUE[FNumberBase, 1]
    else if Shift = [ssCtrl] then
      Increment := INCREMENT_VALUE[FNumberBase, 2]
    else { Shift = [ssCtrl, ssShift] }
      Increment := INCREMENT_VALUE[FNumberBase, 3];

    {$Q-}
    if Ord(Key) = VK_DOWN then
      Increment := -Increment;

    case FNumberSize of
      isByte:     NewValue := Byte(Byte(FNumber) + Byte(Increment));
      isWord:     NewValue := Word(Word(FNumber) + Word(Increment));
      isCardinal: NewValue := Cardinal(Cardinal(FNumber) + Cardinal(Increment));
      isUIntPtr:  NewValue := UIntPtr(UIntPtr(FNumber) + UIntPtr(Increment));
      isUInt64:   NewValue := FNumber + Increment;
    else
      NewValue := FNumber;
    end;
    {$IFDEF Q+}{$Q+}{$ENDIF}

    SetNumber(NewValue);
    Key := 0;
  end;

  inherited;
end;

function TUiLibNumberBox.GetNumber;
begin
  if not FValid then
    raise Exception.Create('Invalid numeric value specified');

  Result := FNumber;
end;

procedure TUiLibNumberBox.Reformat;
begin
  if FValid then
  begin
    // Print according to the settings
    FEdit.OnChange := nil;
    FEdit.Text := RtlxIntToStr(FNumber, FNumberBase, FNumberWidth, FNumberSize,
      FNumberSign, [nsHexadecimal], npSpace);
    FEdit.OnChange := EditChange;
  end
  else
    // Reset to the last valid number
    SetNumber(FNumber);

  UpdateFeedback;
end;

procedure TUiLibNumberBox.SetNumber;
begin
  FNumber := Value;
  FValid := True;
  Reformat;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TUiLibNumberBox.SetNumberBase;
begin
  FNumberBase := Value;
  Reformat;
end;

procedure TUiLibNumberBox.SetNumberSign;
begin
  FNumberSign := Value;
  Reformat;
end;

procedure TUiLibNumberBox.SetNumberSize;
begin
  FNumberSize := Value;
  Reformat;
end;

procedure TUiLibNumberBox.SetNumberWidth;
begin
  FNumberWidth := Value;
  Reformat
end;

function TUiLibNumberBox.TryGetNumber;
begin
  Result := FValid;

  if Result then
    Value := FNumber;
end;

procedure TUiLibNumberBox.UpdateFeedback;
begin
  if FValid then
  begin
    FEdit.Color := ColorSettings.clBackground;
    FEdit.Hint := BuildHint([
      THintSection.New('Signed Decimal', RtlxIntToDec(FNumber,
        FNumberSize, isSigned, FNumberWidth, npSpace)),
      THintSection.New('Unsigned Decimal', RtlxIntToDec(FNumber,
        FNumberSize, isUnsigned, FNumberWidth, npSpace)),
      THintSection.New('Hexadecimal', RtlxIntToHex(FNumber, FNumberWidth,
        True, npSpace))
    ]);
  end
  else
  begin
    FEdit.Color := ColorSettings.clBackgroundError;
    FEdit.Hint := ''
  end;
end;

end.
