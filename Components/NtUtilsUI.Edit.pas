unit NtUtilsUI.Edit;

{
  This module contains the full runtime component definitions for
  TEditEx and TButtonedEditEx.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Winapi.Messages;

type
  TEditEx = class(TEdit)
  private
    FOnDelayedChange: TNotifyEvent;
    FOnTypingChange: TNotifyEvent;
    FDelayedChangeTimeout: Cardinal;
    FTyping: Boolean;
    procedure SetTyping(Value: Boolean);
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

  TButtonedEditEx = class(TButtonedEdit)
  private
    FOnDelayedChange: TNotifyEvent;
    FOnTypingChange: TNotifyEvent;
    FDelayedChangeTimeout: Cardinal;
    FTyping: Boolean;
    procedure SetTyping(Value: Boolean);
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

implementation

uses
  Winapi.Windows;

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

function HandleCtrlBackspace(
  Edit: TCustomEdit;
  var Message: TWMKeyDown
): Boolean;
var
  SelStart, SelEnd: Integer;
begin
  Result := False;

  // Handle Ctrl+Backspace to erase the word on the left
  if (GetKeyState(VK_CONTROL) < 0) and (Message.CharCode = VK_BACK) then
  begin
    SendMessageW(Edit.Handle, EM_GETSEL, WPARAM(@SelStart), LPARAM(@SelEnd));

    // Only if nothing is selected
    if SelStart = SelEnd then
    begin
      // Identify where the word starts
      SelStart := EditWordBreakProc(PWideChar(Edit.Text), SelStart, SelStart + 1,
        WB_LEFT);

      // Select and erase it
      SendMessageW(Edit.Handle, EM_SETSEL, WPARAM(SelStart), LPARAM(SelEnd));
      SendMessageW(Edit.Handle, EM_REPLACESEL, 1, LPARAM(nil));
      Result := True;
    end;
  end;
end;

{ TEditEx }

const
  DELAYED_CHANGE_TIMER_ID = $DE7A4D1;

procedure TEditEx.Change;
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

constructor TEditEx.Create;
begin
  inherited;
  FDelayedChangeTimeout := 500;
end;

procedure TEditEx.CreateWindowHandle;
begin
  inherited;
  SendMessageW(Handle, EM_SETWORDBREAKPROC, 0, LPARAM(@EditWordBreakProc));
end;

procedure TEditEx.DelayedChange;
begin
  if Assigned(FOnDelayedChange) then
    FOnDelayedChange(Self);
end;

procedure TEditEx.KeyPress;
begin
  // Avoid adding the DEL character on Crtl+Backspace
  if (GetKeyState(VK_CONTROL) < 0) and (Key = #$7F) then
    Key := #0;

  inherited;
end;

procedure TEditEx.SetTyping;
begin
  if Value <> FTyping then
  begin
    FTyping := Value;

    if Assigned(FOnTypingChange) then
      FOnTypingChange(Self);
  end;
end;

procedure TEditEx.WMKeyDown;
begin
  if not HandleCtrlBackspace(Self, Message) then
    inherited;
end;

procedure TEditEx.WMTimer;
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

{ TButtonedEditEx }

procedure TButtonedEditEx.Change;
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

constructor TButtonedEditEx.Create;
begin
  inherited;
  FDelayedChangeTimeout := 500;
end;

procedure TButtonedEditEx.CreateWindowHandle;
begin
  inherited;
  SendMessageW(Handle, EM_SETWORDBREAKPROC, 0, LPARAM(@EditWordBreakProc));
end;

procedure TButtonedEditEx.DelayedChange;
begin
  if Assigned(FOnDelayedChange) then
    FOnDelayedChange(Self);
end;

procedure TButtonedEditEx.KeyPress;
begin
  // Avoid adding the DEL character on Crtl+Backspace
  if (GetKeyState(VK_CONTROL) < 0) and (Key = #$7F) then
    Key := #0;

  inherited;
end;

procedure TButtonedEditEx.SetTyping;
begin
  if Value <> FTyping then
  begin
    FTyping := Value;

    if Assigned(FOnTypingChange) then
      FOnTypingChange(Self);
  end;
end;

procedure TButtonedEditEx.WMKeyDown;
begin
  if not HandleCtrlBackspace(Self, Message) then
    inherited;
end;

procedure TButtonedEditEx.WMTimer;
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

end.
