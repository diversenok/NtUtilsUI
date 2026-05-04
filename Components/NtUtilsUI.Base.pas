unit NtUtilsUI.Base;

{
  This module contains the full runtime definitions definitions for the base
  component classes and interfaces.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls;

type
  TUiLibShortCut = class;
  TUiLibShortCutEvent = procedure (Sender: TUiLibShortCut; var Handled: Boolean) of object;

  // An auto-registering shortcut handler
  TUiLibShortCut = class (TComponent)
  private
    FShortCut: TShortCut;
    FOnExecute: TUiLibShortCutEvent;
  public
    property ShortCut: TShortCut read FShortCut write FShortCut;
    property OnExecute: TUiLibShortCutEvent read FOnExecute write FOnExecute;
    function Invoke: Boolean;
  end;

  // A base class for composite visual controls
  TUiLibControl = class abstract (TWinControl)
  protected
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    function Focused: Boolean; override;
  published
    property Align;
    property Anchors;
    property Enabled;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnEnter;
    property OnExit;
  end;

  // Indicates a component that suggests a modal dialog or page caption
  IHasDefaultCaption = interface
    ['{C6238589-5504-461B-8539-F391A4DCC52B}']
    function GetDefaultCaption: String;
  end;

  // Indicates a component that allows returning something
  IModalResult<T> = interface
    ['{FC2CA11B-5A28-4632-ABCF-3399AAB1828A}']
    function GetModalResult: T;
    property ModalResult: T read GetModalResult;
  end;

  // Indicates ability to observe changes to modal result availability
  IModalResultAvailability = interface
    ['{F37BB1AA-08F3-4A70-B985-AAC472E2196D}']
    function GetHasModalResult: Boolean;
    function GetOnHasModalResultChanged: TNotifyEvent;
    procedure SetOnHasModalResultChanged(Callback: TNotifyEvent);
    property HasModalResult: Boolean read GetHasModalResult;
    property OnHasModalResultChanged: TNotifyEvent
      read GetOnHasModalResultChanged
      write SetOnHasModalResultChanged;
  end;

  // A reference to a modal result cache
  IModalResultCache = interface
    ['{62C0D393-F610-4167-8A79-7FD9C9B8AB35}']
    procedure Save(const ModalResultImplementor: IInterface);
  end;

  // A generic storage for a modal result
  TModalResultCache<T> = class (TInterfacedObject, IModalResult<T>,
    IModalResultCache)
  private
    FModalResult: T;
    FModalResultSet: Boolean;
    function GetModalResult: T;
    procedure Save(const ModalResultImplementor: IInterface);
  end;

implementation

uses
  System.SysUtils;

{ TUiLibShortCut }

function TUiLibShortCut.Invoke;
begin
  Result := False;

  if Assigned(FOnExecute) then
    FOnExecute(Self, Result);
end;

{ TUiLibControl }

procedure TUiLibControl.CMEnabledChanged;
var
  i: Integer;
begin
  inherited;

  // Notify all children of the enabled state change
  for i := 0 to ControlCount - 1 do
    if (Controls[i].Owner = Self) and (Controls[i] is TWinControl) then
      TWinControl(Controls[i]).Enabled := Enabled;
end;

function TUiLibControl.Focused;
var
  i: Integer;
begin
  Result := inherited;

  // Check nested controls for the focus
  if not Result then
    for i := 0 to Pred(ControlCount) do
      if (Controls[i] is TWinControl) and TWinControl(Controls[i]).Focused then
      begin
        Result := True;
        Break;
      end;
end;

{ TModalResultCache<T> }

function TModalResultCache<T>.GetModalResult;
begin
  if FModalResultSet then
    Result := FModalResult
  else
    raise EArgumentException.Create('Modal result not available');
end;

procedure TModalResultCache<T>.Save;
var
  Source: IModalResult<T>;
begin
  if ModalResultImplementor.QueryInterface(IModalResult<T>, Source) = S_OK then
  begin
    FModalResult := Source.ModalResult;
    FModalResultSet := True;
  end;
end;

end.
