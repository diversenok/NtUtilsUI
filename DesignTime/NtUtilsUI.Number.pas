unit NtUtilsUI.Number;

{
  This module contains a (stripped down) design-time component definition for
  the number selection control.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, NtUtilsUI.Base, NtUtilsUI.StdCtrls;

{ From NtUtils.SysUsils.pas }

const
  NUMERIC_WIDTH_ROUND_TO_GROUP = $80;

type
  TIntegerSign = (isUnsigned, isSigned);
  TIntegerSize = (isByte, isWord, isCardinal, isUIntPtr, isUInt64);
  TNumericSystem = (nsDecimal, nsHexadecimal);

{ TUiLibNumberBox }

  TUiLibNumberBox = class (TUiLibControl)
  private
    FEdit: TUiLibEdit;
    FNumber: UInt64;
    FNumberBase: TNumericSystem;
    FNumberSize: TIntegerSize;
    FNumberWidth: Byte;
    FNumberSign: TIntegerSign;
    FOnChange: TNotifyEvent;
    procedure SetNumber(const Value: UInt64);
    procedure SetNumberBase(const Value: TNumericSystem);
    procedure SetNumberSign(const Value: TIntegerSign);
    procedure SetNumberSize(const Value: TIntegerSize);
    procedure SetNumberWidth(const Value: Byte);
    procedure Reformat;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Number: UInt64 read FNumber write SetNumber default 0;
    property NumberBase: TNumericSystem read FNumberBase write SetNumberBase default nsHexadecimal;
    property NumberSize: TIntegerSize read FNumberSize write SetNumberSize default isUInt64;
    property NumberWidth: Byte read FNumberWidth write SetNumberWidth default NUMERIC_WIDTH_ROUND_TO_GROUP;
    property NumberSign: TIntegerSign read FNumberSign write SetNumberSign default isUnsigned;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

procedure Register;

implementation

uses
  Vcl.Controls;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibNumberBox]);
end;

{ From NtUtils.SysUtils.pas }

type
  TNumericSystems = set of TNumericSystem;

  TNumericSpaceChar = (
    npNone,
    npSpace,      // Example: 123 456 789
    npAccent,     // Example: 123`456`789 (WinDbg style)
    npApostrophe, // Example: 123'456'789 (C style)
    npUnderscore  // Example: 123_456_789 (Delphi style)
  );
  TNumericSpacechars = set of TNumericSpaceChar;

const
  NUMERIC_SPACES_ALL = [npSpace, npAccent, npApostrophe, npUnderscore];
  NUMERIC_WIDTH_PER_SIZE: array [TIntegerSize] of Byte = (2, 4, 8,
    {$IF SizeOf(UIntPtr) = SizeOf(Cardinal)}8{$ELSE}16{$ENDIF}, 16);

  // NUMERIC_WIDTH_ROUND_TO_GROUP = $80; // Round the number of digits to the group size
  NUMERIC_WIDTH_ROUND_TO_BYTE = $40; // Round the number of digits to the byte size
  NUMERIC_WIDTH_FLAG_MASK = $C0;

  NUMERIC_SYSTEM_RADIX: array [TNumericSystem] of Byte = (10, 16);
  INTEGER_MAX_VALUE: array [TIntegerSize] of array [TIntegerSign] of UInt64 = (
    // (unsigned, signed)
    ($FF, $7F),
    ($FFFF, $7FFF),
    ($FFFFFFFF, $7FFFFFFF),
  {$IF SizeOf(UIntPtr) = SizeOf(Cardinal)}
    ($FFFFFFFF, $7FFFFFFF),
  {$ELSE}
    ($FFFFFFFFFFFFFFFF, $7FFFFFFFFFFFFFFF),
  {$ENDIF}
    ($FFFFFFFFFFFFFFFF, $7FFFFFFFFFFFFFFF)
  );

procedure RtlxExpadWidthForHex(
  var Width: Byte;
  const Value: UInt64;
  Size: TIntegerSize
);
var
  i, Expanded: Byte;
begin
  Expanded := 0;

  case Width and NUMERIC_WIDTH_FLAG_MASK of

    NUMERIC_WIDTH_ROUND_TO_GROUP:
      if Value > $FFFFFFFFFFFF then
        Expanded := 16
      else if Value > $FFFFFFFF then
        Expanded := 12
      else if Value > $FFFF then
        Expanded := 8
      else if Value > $FF then
        Expanded := 4
      else
        Expanded := 2;

    NUMERIC_WIDTH_ROUND_TO_BYTE:
    begin
      Expanded := 2;

      for i := 7 downto 1 do
        if (Value and (UInt64($FF) shl (i shl 3))) <> 0 then
        begin
          Expanded := (i + 1) shl 1;
          Break;
        end;
    end;
  end;

  Width := Width and not NUMERIC_WIDTH_FLAG_MASK;

  if Expanded > Width then
    Width := Expanded;
end;

// Convert a signed/unsigned integer to a string
function RtlxIntToStr(
  const Value: UInt64;
  Base: TNumericSystem;
  Width: Byte = 0; // can be OR'ed with NUMERIC_WIDTH_*
  ValueSize: TIntegerSize = isUInt64;
  ValueSign: TIntegerSign = isUnsigned;
  PrefixBases: TNumericSystems = [nsHexadecimal];
  SpaceDigits: TNumericSpaceChar = npNone
): String;
const
  MIN_DIGITS_TO_GROUP: array [TNumericSystem] of Byte = (7, 4);
  DIGITS_PER_GROUP: array [TNumericSystem] of ShortInt = (3, 4);
  SPACE_CHAR: array [TNumericSpaceChar] of AnsiChar = (#0, ' ', '`', '''', '_');
  DIGIT_MAP: array [0..15] of AnsiChar = ('0', '1', '2', '3', '4', '5', '6',
    '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
var
  Remaining: UInt64;
  ShortResult: ShortString;
  Negative: Boolean;
  i: Integer;
begin
  if (Base > nsHexadecimal) or (ValueSize > isUInt64) or
    (ValueSign > isSigned) then
    Error(reRangeError);

  // Clear unused bits
  Remaining := Value and INTEGER_MAX_VALUE[ValueSize, isUnsigned];

  // Check if we need the minus sign
  if (ValueSign = isSigned) and
    (Remaining > INTEGER_MAX_VALUE[ValueSize, isSigned]) then
  begin
    Negative := True;
    Remaining := INTEGER_MAX_VALUE[ValueSize, isUnsigned] - Remaining + 1;
  end
  else
    Negative := False;

  // Dynamically choose the width
  if Base = nsHexadecimal then
    RtlxExpadWidthForHex(Width, Remaining, ValueSize)
  else
    Width := Width and not NUMERIC_WIDTH_FLAG_MASK;

  // Print digits
  SetLength(ShortResult, 0);

  repeat
    Insert(DIGIT_MAP[Remaining mod NUMERIC_SYSTEM_RADIX[Base]], ShortResult, 1);
    Remaining := Remaining div NUMERIC_SYSTEM_RADIX[Base];
  until Remaining = 0;

  // Pad to width
  while Length(ShortResult) < Width do
    Insert('0', ShortResult, 1);

  // Group digits
  if (SpaceDigits <> npNone) and
    (Length(ShortResult) >= MIN_DIGITS_TO_GROUP[Base]) then
  begin
    i := Length(ShortResult) - DIGITS_PER_GROUP[Base] + 1;
    while i >= DIGITS_PER_GROUP[Base] - 1 do
    begin
      Insert(SPACE_CHAR[SpaceDigits], ShortResult, i);
      Dec(i, DIGITS_PER_GROUP[Base]);
    end;
  end;

  // Add the base prefix
  if Base in PrefixBases then
    case Base of
      nsDecimal:     Insert('0n', ShortResult, 1);
      nsHexadecimal: Insert('0x', ShortResult, 1);
    end;

  // Add the minus sign
  if Negative then
    Insert('-', ShortResult, 1);

  Result := String(ShortResult);
end;

// Convert a string to an 64-bit integer
function RtlxStrToUInt64(
  const S: String;
  out Value: UInt64;
  DefaultBase: TNumericSystem = nsDecimal;
  RecognizeBasePrefixes: TNumericSystems = [nsHexadecimal];
  AllowMinusSign: Boolean = False;
  AllowSpaces: TNumericSpacechars = [];
  ValueSize: TIntegerSize = isUInt64
): Boolean;
var
  Cursor: PWideChar;
  DigitIndex, Remaining: Cardinal;
  Negate: Boolean;
  CurrentSystem: TNumericSystem;
  Accumulated: UInt64;
  CurrentDigit: Byte;
  MaxNonOverflow: UInt64;
begin
  Result := False;

  if Length(S) <= 0 then
    Exit;

  Cursor := PWideChar(S);
  Remaining := Length(S); // including the cursor
  DigitIndex := 0;
  Negate := False;
  CurrentSystem := DefaultBase;
  Accumulated := 0;

  // Check for the minus sign
  if AllowMinusSign and (Remaining >= 1) and (Cursor[0] = '-') then
  begin
    Negate := True;
    Inc(Cursor);
    Dec(Remaining);
  end;

  repeat
    // Check for the numeric system
    if (RecognizeBasePrefixes <> []) and (Remaining >= 2) and (Cursor[0] = '0') then
    begin
      case Cursor[1] of
        'n', 'N': CurrentSystem := nsDecimal;
        'x', 'X': CurrentSystem := nsHexadecimal;
      else
        Break;
      end;

      if not (CurrentSystem in RecognizeBasePrefixes) then
      begin
        // Undo recognition when the caller explicitly disabled the one we got
        CurrentSystem := DefaultBase;
        Break;
      end;

      // Consume the characters
      Inc(Cursor, 2);
      Dec(Remaining, 2);
    end;
  until True;

  if Remaining <= 0 then
    Exit;

  MaxNonOverflow := INTEGER_MAX_VALUE[ValueSize, TIntegerSign(Negate)] div
    NUMERIC_SYSTEM_RADIX[CurrentSystem];

  // The bulk of parsing
  while Remaining > 0 do
  begin
    case Cursor[0] of
      '0'..'9': CurrentDigit := Ord(Cursor[0]) - Ord('0') + $0;
      'a'..'f': CurrentDigit := Ord(Cursor[0]) - Ord('a') + $a;
      'A'..'F': CurrentDigit := Ord(Cursor[0]) - Ord('A') + $A;
      ' ', '`', '''', '_':
        if (DigitIndex > 0) and (Remaining > 1) and (
          ((Cursor[0] = ' ') and (npSpace in AllowSpaces)) or
          ((Cursor[0] = '`') and (npAccent in AllowSpaces)) or
          ((Cursor[0] = '''') and (npApostrophe in AllowSpaces)) or
          ((Cursor[0] = '_') and (npUnderscore in AllowSpaces))) then
        begin
          Inc(Cursor);
          Dec(Remaining);
          Continue;
        end
        else
          Exit;
    else
      Exit;
    end;

    if CurrentDigit >= NUMERIC_SYSTEM_RADIX[CurrentSystem] then
      Exit;

    // Make sure shifting doesn't cause an overflow
    if Accumulated > MaxNonOverflow then
      Exit;

    {$Q-}
    Accumulated := Accumulated * NUMERIC_SYSTEM_RADIX[CurrentSystem];
    {$IFDEF Q+}{$Q+}{$ENDIF}

    // Make sure digit addition doesn't cause an overflow
    if Accumulated > (INTEGER_MAX_VALUE[ValueSize,
      TIntegerSign(Negate)] - CurrentDigit) then
      Exit;

    {$Q-}
    Inc(Accumulated, CurrentDigit);
    {$IFDEF Q+}{$Q+}{$ENDIF}

    Inc(Cursor);
    Dec(Remaining);
    Inc(DigitIndex);
  end;

  {$Q-}
  if Negate then
    Accumulated := -Accumulated;
  {$IFDEF Q+}{$Q+}{$ENDIF}

  Value := Accumulated;
  Result := True;
end;

{ TUiLibNumberBox }

constructor TUiLibNumberBox.Create;
begin
  inherited;

  Width := 150;
  Height := 23;
  Constraints.MinWidth := 100;

  FEdit := TUiLibEdit.Create(Self);
  FEdit.Width := Width;
  FEdit.Height := Height;
  FEdit.Align := alClient;
  FEdit.Parent := Self;

  FNumberBase := nsHexadecimal;
  FNumberSize := isUInt64;
  FNumberWidth := NUMERIC_WIDTH_ROUND_TO_GROUP;
  FNumberSign := isUnsigned;
  Reformat;
end;

procedure TUiLibNumberBox.Reformat;
begin
  // Print according to the settings
  FEdit.Text := RtlxIntToStr(FNumber, FNumberBase, FNumberWidth, FNumberSize,
    FNumberSign, [nsHexadecimal], npSpace);
end;

procedure TUiLibNumberBox.SetNumber;
begin
  FNumber := Value;
  Reformat;
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

end.
