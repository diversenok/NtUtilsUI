unit NtUtilsUI.Edit;

{
  This module contains a (stripped down) design-time component definitions for
  TEditEx and TButtonedEditEx.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TEditEx = class(TEdit)
  private
    FOnDelayedChange: TNotifyEvent;
    FOnTypingChange: TNotifyEvent;
    FDelayedChangeTimeout: Cardinal;
  public
    constructor Create(AOwner: TComponent); override;
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
  public
    constructor Create(AOwner: TComponent); override;
  published
    property DelayedChangeTimeout: Cardinal read FDelayedChangeTimeout write FDelayedChangeTimeout default 500;
    property OnDelayedChange: TNotifyEvent read FOnDelayedChange write FOnDelayedChange;
    property OnTypingChange: TNotifyEvent read FOnTypingChange write FOnTypingChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TEditEx, TButtonedEditEx]);
end;

{ TEditEx }

constructor TEditEx.Create;
begin
  inherited;
  FDelayedChangeTimeout := 500;
end;

{ TButtonedEditEx }

constructor TButtonedEditEx.Create;
begin
  inherited;
  FDelayedChangeTimeout := 500;
end;

end.

