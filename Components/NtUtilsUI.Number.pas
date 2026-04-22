unit NtUtilsUI.Number;

{
  This module contains the full runtime component definition for the number
  selection controls.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, NtUtilsUI.Base, NtUtilsUI.StdCtrls, NtUtils.SysUtils;

type
  TUiLibNumberBox = class (TUiLibControl)
  strict private
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

  TUiLibNumberComboBoxItem = class (TCollectionItem)
  strict private
    FNumber: UInt64;
    FName: String;
    procedure SetName(const Value: String);
    procedure SetNumber(const Value: UInt64);
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Number: UInt64 read FNumber write SetNumber;
    property Name: String read FName write SetName;
  end;

  TUiLibNumberComboBox = class;

  TUiLibNumberComboBoxItems = class (TCollection)
  strict private
    FComboBox: TUiLibNumberComboBox;
    function GetItem(Index: Integer): TUiLibNumberComboBoxItem;
    procedure SetItem(Index: Integer; const Value: TUiLibNumberComboBoxItem);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(ComboBox: TUiLibNumberComboBox);
    function Add(const Number: UInt64; const Name: String): TUiLibNumberComboBoxItem;
    function FindItemID(ID: Integer): TUiLibNumberComboBoxItem;
    function Insert(Index: Integer): TUiLibNumberComboBoxItem;
    property Items[Index: Integer]: TUiLibNumberComboBoxItem read GetItem write SetItem; default;
  end;

  TUiLibNumberComboBox = class (TUiLibControl)
  strict private
    FComboBox: TUiLibComboBox;
    FKnownValues: TUiLibNumberComboBoxItems;
    FNumber: UInt64;
    FValid: Boolean;
    FNumberBase: TNumericSystem;
    FNumberSize: TIntegerSize;
    FNumberWidth: Byte;
    FNumberSign: TIntegerSign;
    FOnChange: TNotifyEvent;
    procedure ComboBoxChange(Sender: TObject);
    procedure ComboBoxExit(Sender: TObject);
    function GetNumber: UInt64;
    procedure SetNumber(const Value: UInt64);
    procedure UpdateFeedback;
    procedure SetNumberBase(const Value: TNumericSystem);
    procedure SetNumberSign(const Value: TIntegerSign);
    procedure SetNumberSize(const Value: TIntegerSize);
    procedure SetNumberWidth(const Value: Byte);
    procedure Reformat;
    procedure SetKnownValues(const Value: TUiLibNumberComboBoxItems);
  private
    procedure ItemsChanged;
  protected
    procedure CreateHandle; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function TryGetNumber(out Value: UInt64): Boolean;
  published
    property Number: UInt64 read GetNumber write SetNumber default 0;
    property NumberBase: TNumericSystem read FNumberBase write SetNumberBase default nsHexadecimal;
    property NumberSize: TIntegerSize read FNumberSize write SetNumberSize default isUInt64;
    property NumberWidth: Byte read FNumberWidth write SetNumberWidth default NUMERIC_WIDTH_ROUND_TO_GROUP;
    property NumberSign: TIntegerSign read FNumberSign write SetNumberSign default isUnsigned;
    property KnownValues: TUiLibNumberComboBoxItems read FKnownValues write SetKnownValues;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, Vcl.Controls, NtUtilsUI, DelphiUiLib.Strings,
  NtUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Functions }

function MakeNumberHint(
  const Number: UInt64;
  const NumberSize: TIntegerSize;
  const NumberWidth: Byte
): String;
var
  Sections: TArray<THintSection>;
begin
  // Do signed and unsigned interpretations differ?
  if Number > INTEGER_MAX_VALUE[NumberSize, isSigned] then
  begin
    SetLength(Sections, 3);
    Sections[0].Title := 'Signed Decimal';
    Sections[0].Content := RtlxIntToDec(Number, NumberSize, isSigned,
      NUMERIC_WIDTH_ROUND_TO_GROUP, npSpace);
    Sections[1].Title := 'Unsigned Decimal';
    Sections[1].Content := RtlxIntToDec(Number, NumberSize, isUnsigned,
      NUMERIC_WIDTH_ROUND_TO_GROUP, npSpace);
  end
  else
  begin
    SetLength(Sections, 2);
    Sections[0].Title := 'Decimal';
    Sections[0].Content := RtlxIntToDec(Number, NumberSize, isUnsigned,
      NUMERIC_WIDTH_ROUND_TO_GROUP, npSpace);
  end;

  Sections[High(Sections)].Title := 'Hexadecimal';
  Sections[High(Sections)].Content := RtlxIntToStr(Number, nsHexadecimal,
    NumberWidth or NUMERIC_WIDTH_ROUND_TO_GROUP, NumberSize, isUnsigned,
    [nsHexadecimal], npSpace);

  Result := BuildHint(Sections);
end;

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
    FEdit.Hint := MakeNumberHint(FNumber, FNumberSize, FNumberWidth);
  end
  else
  begin
    FEdit.Color := ColorSettings.clBackgroundError;
    FEdit.Hint := ''
  end;
end;

{ TUiLibNumberComboBoxItem }

procedure TUiLibNumberComboBoxItem.Assign;
var
  SourceItem: TUiLibNumberComboBoxItem absolute Source;
begin
  if Source is TUiLibNumberComboBoxItem then
  begin
    FNumber := SourceItem.FNumber;
    FName := SourceItem.FName;
  end
  else
    inherited Assign(Source);
end;

procedure TUiLibNumberComboBoxItem.SetName;
begin
  if FName <> Value then
  begin
    FName := Value;
    Changed(False);
  end;
end;

procedure TUiLibNumberComboBoxItem.SetNumber;
begin
  if FNumber <> Value then
  begin
    FNumber := Value;
    Changed(False);
  end;
end;

{ TUiLibNumberComboBoxItems }

function TUiLibNumberComboBoxItems.Add;
begin
  BeginUpdate;
  try
    Result := TUiLibNumberComboBoxItem(inherited Add);
    Result.Number := Number;
    Result.Name := Name;
  finally
    EndUpdate;
  end;
end;

constructor TUiLibNumberComboBoxItems.Create;
begin
  FComboBox := ComboBox;
  inherited Create(TUiLibNumberComboBoxItem);
end;

function TUiLibNumberComboBoxItems.FindItemID;
begin
  Result := TUiLibNumberComboBoxItem(inherited FindItemID(ID));
end;

function TUiLibNumberComboBoxItems.GetItem;
begin
  Result := TUiLibNumberComboBoxItem(inherited GetItem(Index));
end;

function TUiLibNumberComboBoxItems.Insert;
begin
  Result := TUiLibNumberComboBoxItem(inherited Insert(Index));
end;

procedure TUiLibNumberComboBoxItems.SetItem;
begin
  inherited SetItem(Index, Value);
end;

procedure TUiLibNumberComboBoxItems.Update;
begin
  inherited;

  // Notify the combobox about the change
  if Assigned(FComboBox) then
    FComboBox.ItemsChanged;
end;

{ TUiLibNumberComboBox }

procedure TUiLibNumberComboBox.ComboBoxChange;
begin
  if FComboBox.ItemIndex >= 0 then
  begin
    // Use the known value
    FNumber := FKnownValues[FComboBox.ItemIndex].Number;
    FValid := True;
  end
  else
  begin
    // Attempt to parse the input while being as flexible as possible
    FValid := RtlxStrToUInt64(FComboBox.Text, FNumber, nsDecimal, [nsDecimal,
      nsHexadecimal], True, NUMERIC_SPACES_ALL, FNumberSize);
  end;

  UpdateFeedback;

  if FValid and Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TUiLibNumberComboBox.ComboBoxExit;
begin
  // Reset to the last valid number before leaving the control
  if not FValid then
    SetNumber(FNumber);
end;

constructor TUiLibNumberComboBox.Create;
begin
  inherited;

  FKnownValues := TUiLibNumberComboBoxItems.Create(Self);
  Width := 150;
  Height := 21;
  Constraints.MinWidth := 100;

  FComboBox := TUiLibComboBox.Create(Self);
  FComboBox.Width := Width;
  FComboBox.Height := Height;
  FComboBox.Align := alClient;
  FComboBox.Parent := Self;
  FComboBox.OnChange := ComboBoxChange;
  FComboBox.OnExit := ComboBoxExit;

  FNumberBase := nsHexadecimal;
  FNumberSize := isUInt64;
  FNumberWidth := NUMERIC_WIDTH_ROUND_TO_GROUP;
  FNumberSign := isUnsigned;
  FValid := True;
  Reformat;
end;

procedure TUiLibNumberComboBox.CreateHandle;
begin
  inherited;
  ItemsChanged;
end;

destructor TUiLibNumberComboBox.Destroy;
begin
  FreeAndNil(FKnownValues);
  inherited;
end;

function TUiLibNumberComboBox.GetNumber;
begin
  if not FValid then
    raise Exception.Create('Invalid numeric value specified');

  Result := FNumber;
end;

procedure TUiLibNumberComboBox.ItemsChanged;
var
  i: Integer;
begin
  // Delay the item sync until we get a handle
  if not HandleAllocated then
    Exit;

  FComboBox.Items.BeginUpdate;
  try
    FComboBox.Clear;

    for i := 0 to Pred(FKnownValues.Count) do
      FComboBox.Items.Add(FKnownValues[i].Name);
  finally
    FComboBox.Items.EndUpdate;
  end;

  Reformat;
end;

procedure TUiLibNumberComboBox.Reformat;
var
  i: Integer;
  IsKnown: Boolean;
begin
  if not FValid then
  begin
    // Reset to the last valid number
    SetNumber(FNumber);
    Exit;
  end;

  IsKnown := False;

  // Try one of the known numbers first
  for i := 0 to Pred(FKnownValues.Count) do
    if FKnownValues[i].Number = FNumber then
    begin
      if HandleAllocated then
        FComboBox.ItemIndex := i
      else
        FComboBox.Text := FKnownValues[i].Name;

      IsKnown := True;
      Break;
    end;

  if not IsKnown then
  begin
    if HandleAllocated then
      FComboBox.ItemIndex := -1;

    // Print unknown numbers according to the settings
    FComboBox.Text := RtlxIntToStr(FNumber, FNumberBase, FNumberWidth,
      FNumberSize, FNumberSign, [nsHexadecimal], npSpace);
  end;

  UpdateFeedback;
end;

procedure TUiLibNumberComboBox.SetKnownValues;
begin
  FKnownValues.Assign(Value);
end;

procedure TUiLibNumberComboBox.SetNumber;
begin
  FNumber := Value;
  FValid := True;
  Reformat;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TUiLibNumberComboBox.SetNumberBase;
begin
  FNumberBase := Value;
  Reformat;
end;

procedure TUiLibNumberComboBox.SetNumberSign;
begin
  FNumberSign := Value;
  Reformat;
end;

procedure TUiLibNumberComboBox.SetNumberSize;
begin
  FNumberSize := Value;
  Reformat;
end;

procedure TUiLibNumberComboBox.SetNumberWidth;
begin
  FNumberWidth := Value;
  Reformat;
end;

function TUiLibNumberComboBox.TryGetNumber;
begin
  Result := FValid;

  if Result then
    Value := FNumber;
end;

procedure TUiLibNumberComboBox.UpdateFeedback;
begin
  if FValid then
  begin
    FComboBox.Color := ColorSettings.clBackground;
    FComboBox.Hint := MakeNumberHint(FNumber, FNumberSize, FNumberWidth);
  end
  else
  begin
    FComboBox.Color := ColorSettings.clBackgroundError;
    FComboBox.Hint := ''
  end;
end;

end.
