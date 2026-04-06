unit NtUtilsUI.StdCtrls;

{
  This module contains the full runtime component definitions for the improved
  standard controls.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ImgList,
  Winapi.Windows, Winapi.Messages, NtUtilsUI.Interfaces;

type
  TUiLibEdit = class(TEdit)
  private
    FOnDelayedChange: TNotifyEvent;
    FOnTypingChange: TNotifyEvent;
    FDelayedChangeTimeout: Cardinal;
    FTyping: Boolean;
    procedure SetTyping(Value: Boolean);
    function GetText: String;
  protected
    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;
    procedure WMKeyDown(var Message: TWMKeyDown); message WM_KEYDOWN;
    procedure KeyPress(var Key: Char); override;
    procedure CreateWindowHandle(const Params: TCreateParams); override;
    procedure DelayedChange; virtual;
    procedure Change; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Typing: Boolean read FTyping;
  published
    property DelayedChangeTimeout: Cardinal read FDelayedChangeTimeout write FDelayedChangeTimeout default 500;
    property OnDelayedChange: TNotifyEvent read FOnDelayedChange write FOnDelayedChange;
    property OnTypingChange: TNotifyEvent read FOnTypingChange write FOnTypingChange;
  end;

  TUiLibButtonedEdit = class(TButtonedEdit)
  private
    FOnDelayedChange: TNotifyEvent;
    FOnTypingChange: TNotifyEvent;
    FDelayedChangeTimeout: Cardinal;
    FTyping: Boolean;
    procedure SetTyping(Value: Boolean);
    function GetText: String;
  protected
    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;
    procedure WMKeyDown(var Message: TWMKeyDown); message WM_KEYDOWN;
    procedure KeyPress(var Key: Char); override;
    procedure CreateWindowHandle(const Params: TCreateParams); override;
    procedure DelayedChange; virtual;
    procedure Change; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Typing: Boolean read FTyping;
  published
    property DelayedChangeTimeout: Cardinal read FDelayedChangeTimeout write FDelayedChangeTimeout default 500;
    property OnDelayedChange: TNotifyEvent read FOnDelayedChange write FOnDelayedChange;
    property OnTypingChange: TNotifyEvent read FOnTypingChange write FOnTypingChange;
  end;

  TUiLibComboBox = class(TComboBox, ICanConsumeEscape)
  private
    function GetText: String;
    function ConsumesEscape: Boolean;
  protected
    procedure CreateWnd; override;
    procedure ComboWndProc(var Message: TMessage; ComboWnd: HWnd; ComboProc: TWindowProcPtr); override;
    procedure KeyPress(var Key: Char); override;
  end;

  TUiLibButton = class(TButton)
  private
    FImageList: TCustomImageList;
    FImageResource: String;
    procedure SetImageResource(Value: String);
  protected
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
  published
    property ImageResource: String read FImageResource write SetImageResource;
  end;

  TUiLibImageListHelper = class helper for TCustomImageList
    function AddIconFromResource(Instance: THandle; const ResourceName: String): Integer;
  end;

implementation

uses
  System.SysUtils, Winapi.CommCtrl;

var
  SuppressLeftMove: Boolean;

function EditWordBreakProc(
  TextStart: PWideChar;
  Index: Integer;
  TextLength: Integer;
  Code: Cardinal
): Integer; stdcall;
var
  LastChar, Cursor: PWideChar;
  FoundNonDelimiter: Boolean;
  function IsCursorDelimiter: Boolean;
  const
    DELIMITERS = [#9, ' ', '!', '"', '#', '$', '%', '&', '''', '(', ')', '*',
      '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\', ']',
      '^', '_', '`', '{', '|', '}', '~'];
  begin
    Result := (Cursor < TextStart) or (Cursor > LastChar) or CharInSet(Cursor^,
      DELIMITERS);
  end;
begin
  if Index < 0 then
    Index := 0
  else if Index > TextLength then
    Index := TextLength;

  Cursor := TextStart + Index;
  LastChar := TextStart + TextLength - 1;

  case Code of
    WB_ISDELIMITER:
    begin
      // Hack: Windows only calls this code for Ctrl+Right; use it to suppress
      // the effect of WB_LEFT (which can be invoked as part of WB_RIGHT and
      // cancel it out)
      SuppressLeftMove := True;
      Result := Integer(IsCursorDelimiter);
    end;

    WB_LEFT:
      if SuppressLeftMove then
      begin
        // Hack: Suppress most of WB_LEFT's effects when called from Ctrl+Right,
        // but keep a left shift by one (since WB_RIGHT will start on the next
        // character)
        SuppressLeftMove := False;

        if Index > 0 then
          Result := Index - 1
        else
          Result := 0;
      end
      else if Cursor <= TextStart then
        Result := 0
      else
      begin
        // If we are inside a word, find where is starts by skipping all
        // non-delimiters to the left. If we are next to a delimiter,
        // skip all delimiters plus one word to the left.
        FoundNonDelimiter := False;

        repeat
          Cursor := CharPrevW(TextStart, Cursor);

          if Cursor <= TextStart then
            Break
          else if IsCursorDelimiter then
          begin
            if FoundNonDelimiter then
              Break;
          end
          else
            FoundNonDelimiter := True;

        until False;

        Result := Cursor - TextStart;

        if (Result > 0) and (Result < TextLength) then
        begin
          Inc(Cursor);
          Inc(Result);
        end;
      end;

    WB_RIGHT:
    begin
      // Skip the word (when inside) and the delimiter after it.
      SuppressLeftMove := False;
      FoundNonDelimiter := not IsCursorDelimiter;

      repeat
        if Cursor > LastChar then
          Break;

        Cursor := CharNextW(Cursor);

        if Cursor > LastChar then
          Break;

        if IsCursorDelimiter then
          FoundNonDelimiter := False
        else if not FoundNonDelimiter then
          Break;

      until False;

      Result := Cursor - TextStart;
    end;
  else
    Result := 0;
  end;
end;

type
  TTextQueryMethod = function: String of object;

function HandleCtrlBackspace(
  Handle: HWND;
  TextQueryMethod: TTextQueryMethod;
  var Message: TWMKeyDown
): Boolean;
var
  SelStart, SelEnd: Integer;
begin
  Result := False;

  // Handle Ctrl+Backspace to erase the word on the left
  if (GetKeyState(VK_CONTROL) < 0) and (Message.CharCode = VK_BACK) then
  begin
    // Query the selection range
    SendMessageW(Handle, EM_GETSEL, WPARAM(@SelStart), LPARAM(@SelEnd));

    // Only if nothing is selected
    if SelStart = SelEnd then
    begin
      // Identify where the word starts
      SelStart := EditWordBreakProc(PWideChar(TextQueryMethod), SelStart,
        SelStart + 1, WB_LEFT);

      // Select and erase it
      SendMessageW(Handle, EM_SETSEL, WPARAM(SelStart), LPARAM(SelEnd));
      SendMessageW(Handle, EM_REPLACESEL, 1, LPARAM(nil));
      Result := True;
    end;
  end;
end;

{ TUiLibEdit }

const
  DELAYED_CHANGE_TIMER_ID = $DE7A4D1;

procedure TUiLibEdit.Change;
begin
  inherited;

  if not HandleAllocated then
    Exit;

  if Text = '' then
  begin
    KillTimer(Handle, DELAYED_CHANGE_TIMER_ID);
    SetTyping(False);
    DelayedChange;
  end
  else if FDelayedChangeTimeout = 0 then
    DelayedChange
  else
  begin
    SetTimer(Handle, DELAYED_CHANGE_TIMER_ID, FDelayedChangeTimeout, nil);
    SetTyping(True);
  end;
end;

constructor TUiLibEdit.Create;
begin
  inherited;
  FDelayedChangeTimeout := 500;
end;

procedure TUiLibEdit.CreateWindowHandle;
begin
  inherited;
  SendMessageW(Handle, EM_SETWORDBREAKPROC, 0, LPARAM(@EditWordBreakProc));
end;

procedure TUiLibEdit.DelayedChange;
begin
  if Assigned(FOnDelayedChange) then
    FOnDelayedChange(Self);
end;

function TUiLibEdit.GetText;
begin
  Result := Text;
end;

procedure TUiLibEdit.KeyPress;
begin
  // Avoid adding the DEL character on Crtl+Backspace
  if (GetKeyState(VK_CONTROL) < 0) and (Key = #$7F) then
    Key := #0;

  inherited;
end;

procedure TUiLibEdit.SetTyping;
begin
  if Value <> FTyping then
  begin
    FTyping := Value;

    if Assigned(FOnTypingChange) then
      FOnTypingChange(Self);
  end;
end;

procedure TUiLibEdit.WMKeyDown;
begin
  if not HandleCtrlBackspace(Handle, GetText, Message) then
    inherited;
end;

procedure TUiLibEdit.WMTimer;
begin
  if Message.TimerID = DELAYED_CHANGE_TIMER_ID then
  begin
    // Prevent repetitive invocation
    KillTimer(Handle, DELAYED_CHANGE_TIMER_ID);
    SetTyping(False);
    DelayedChange;
  end
  else
    inherited;
end;

{ TUiLibButtonedEdit }

procedure TUiLibButtonedEdit.Change;
begin
  inherited;

  if not HandleAllocated then
    Exit;

  if Text = '' then
  begin
    KillTimer(Handle, DELAYED_CHANGE_TIMER_ID);
    SetTyping(False);
    DelayedChange;
  end
  else if FDelayedChangeTimeout = 0 then
    DelayedChange
  else
  begin
    SetTimer(Handle, DELAYED_CHANGE_TIMER_ID, FDelayedChangeTimeout, nil);
    SetTyping(True);
  end;
end;

constructor TUiLibButtonedEdit.Create;
begin
  inherited;
  FDelayedChangeTimeout := 500;
end;

procedure TUiLibButtonedEdit.CreateWindowHandle;
begin
  inherited;
  SendMessageW(Handle, EM_SETWORDBREAKPROC, 0, LPARAM(@EditWordBreakProc));
end;

procedure TUiLibButtonedEdit.DelayedChange;
begin
  if Assigned(FOnDelayedChange) then
    FOnDelayedChange(Self);
end;

function TUiLibButtonedEdit.GetText;
begin
  Result := Text;
end;

procedure TUiLibButtonedEdit.KeyPress;
begin
  // Avoid adding the DEL character on Crtl+Backspace
  if (GetKeyState(VK_CONTROL) < 0) and (Key = #$7F) then
    Key := #0;

  inherited;
end;

procedure TUiLibButtonedEdit.SetTyping;
begin
  if Value <> FTyping then
  begin
    FTyping := Value;

    if Assigned(FOnTypingChange) then
      FOnTypingChange(Self);
  end;
end;

procedure TUiLibButtonedEdit.WMKeyDown;
begin
  if not HandleCtrlBackspace(Handle, GetText, Message) then
    inherited;
end;

procedure TUiLibButtonedEdit.WMTimer;
begin
  if Message.TimerID = DELAYED_CHANGE_TIMER_ID then
  begin
    // Prevent repetitive invocation
    KillTimer(Handle, DELAYED_CHANGE_TIMER_ID);
    SetTyping(False);
    DelayedChange;
  end
  else
    inherited;
end;

{ TUiLibComboBox }

procedure TUiLibComboBox.ComboWndProc;
begin
  if (Message.Msg <> WM_KEYDOWN) or (EditHandle = 0) or
    not HandleCtrlBackspace(EditHandle, GetText, TWMKeyDown(Message)) then
    inherited;
end;

function TUiLibComboBox.ConsumesEscape;
begin
  Result := DroppedDown;
end;

procedure TUiLibComboBox.CreateWnd;
begin
  inherited;

  if EditHandle <> 0 then
    SendMessageW(EditHandle, EM_SETWORDBREAKPROC, 0, LPARAM(@EditWordBreakProc));
end;

function TUiLibComboBox.GetText;
begin
  Result := Text;
end;

procedure TUiLibComboBox.KeyPress;
begin
  // Avoid adding the DEL character on Crtl+Backspace
  if (GetKeyState(VK_CONTROL) < 0) and (Key = #$7F) then
    Key := #0;

  inherited;
end;

{ TUiLibButton }

procedure TUiLibButton.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;

  // Reload the icon on DPI change
  if isDpiChange and (FImageResource <> '') then
    SetImageResource(FImageResource);
end;

procedure TUiLibButton.SetImageResource;
begin
  FImageResource := Value;

  if Value = '' then
  begin
    ImageIndex := -1;
    Exit;
  end;

  // Create and select the image list if necessary
  if not Assigned(FImageList) then
  begin
    FImageList := TCustomImageList.Create(Self);
    FImageList.ColorDepth := cd32Bit;
    ImageIndex := -1;
    Images := FImageList;
  end;

  // Adjust the size to match the current DPI
  FImageList.Clear;
  FImageList.Width := 16 * CurrentPPI div 96;
  FImageList.Height := FImageList.Width;

  // Load the resource
  ImageIndex := FImageList.AddIconFromResource(HInstance, Value)
end;

{ TUiLibImageListHelper }

function TUiLibImageListHelper.AddIconFromResource;
begin
  Result := ImageList_AddIcon(Handle, LoadIcon(Instance, PChar(ResourceName)));
  Change;
end;

end.
