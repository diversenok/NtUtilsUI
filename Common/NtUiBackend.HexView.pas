unit NtUiBackend.HexView;

{
  This module provides support for parsing and representing binary data as hex.
}

interface

uses
  NtUtils;

// Parse a variable-length hexadecimal string
function UiLibParseHexData(
  const HexString: String;
  out Data: IMemory
): Boolean;

// Represent variable-length data as a hexadecimal string
function UiLibRepresentHexData(
  const Data: IMemory
): String;

implementation

type
  TParsingState = (
    psBetweenBytes,
    psInsideByte
  );

function UiLibParseHexData;
var
  i: Integer;
  State: TParsingState;
  ByteCount: NativeUInt;
  DataCursor: PByte;
  SymbolShift: Word;
  Value: Byte;
begin
  Result := False;
  ByteCount := 0;
  State := psBetweenBytes;

  for i := Low(HexString) to High(HexString) do
  begin
    // Determine symbol category
    case HexString[i] of
      '0'..'9', 'a'..'f', 'A'..'F':
        ;

      ' ', #9, #$D, #$A:
        if State = psInsideByte then
          Exit
        else
          Continue;
    else
      Exit;
    end;

    // Update the state
    case State of
      psBetweenBytes:
        State := psInsideByte;

      psInsideByte:
      begin
        State := psBetweenBytes;
        Inc(ByteCount);
      end;
    end;
  end;

  // Make sure the last byte is complete
  if State = psInsideByte then
    Exit;

  // Prepare the buffer for successful parsing
  Data := Auto.AllocateDynamic(ByteCount);
  DataCursor := Data.Data;
  Value := 0;

  for i := Low(HexString) to High(HexString) do
  begin
    // Read and interpret the symbol
    case HexString[i] of
      '0'..'9': SymbolShift := Ord('0');
      'a'..'f': SymbolShift := Ord('a') - $a;
      'A'..'F': SymbolShift := Ord('A') - $A;
    else
      Continue;
    end;

    case State of
      psBetweenBytes:
        begin
          // The first half of the byte
          State := psInsideByte;
          Value := Byte(Ord(HexString[i]) - SymbolShift);
        end;

      psInsideByte:
        begin
          // The second half of the byte
          State := psBetweenBytes;
          Value := (Value shl 4) or Byte(Ord(HexString[i]) - SymbolShift);
          DataCursor^ := Value;
          Inc(DataCursor);
        end;
    end;
  end;

  Result := True;
end;

function UiLibRepresentHexData;
const
  HEX_DIGITS: array [0..15] of WideChar = ('0', '1', '2', '3', '4', '5', '6',
    '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
var
  i: Integer;
  DataCursor: PByte;
begin
  if not Assigned(Data) or (Data.Size = 0) then
    Exit('');

  // Two characters per byte + padding in between
  SetLength(Result, (Data.Size * 3) - 1);
  DataCursor := Data.Data;

  for i := Low(Result) to High(Result) do
  begin
    case (i - Low(Result)) mod 3 of
      0: Result[i] := HEX_DIGITS[DataCursor^ shr 4];
      1: Result[i] := HEX_DIGITS[DataCursor^ and $0F];
    else
      Result[i] := ' ';
      Inc(DataCursor);
    end;
  end;
end;

end.
