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

  // Component's suggestion for a static modal dialog or a page caption
  DefaultCaptionAttribute = class (TCustomAttribute)
    FDefaultCaption: String;
    constructor Create(const Value: String);
  end;

  // Component's suggestion for a dynamic modal dialog or a page caption
  IDefaultCaption = interface
    ['{C6238589-5504-461B-8539-F391A4DCC52B}']
    function GetDefaultCaption: String;
  end;

  // Indicates a component that allows returning something
  IModalResult<T> = interface
    ['{F7252A37-B3BD-4004-8054-05E502CBFADC}']
    function GetModalResult: T;
    function GetModalResultType: Pointer;

    // Data that the user selected in a modal dialog
    property ModalResult: T read GetModalResult;

    // A TypeInfo(T) for type runtime type compatibility checks
    property ModalResultType: Pointer read GetModalResultType;
  end;

  TOnHasModalResultChange = procedure (HasModalResult: Boolean) of object;

  // Indicates ability to observe changes to modal result availability
  IModalResultAvailability = interface
    ['{1819242C-25BA-4DF5-9CD6-121C039D2D8A}']
    procedure SetOnHasModalResultChange(Value: TOnHasModalResultChange);
    property OnHasModalResultChange: TOnHasModalResultChange write SetOnHasModalResultChange;
  end;

  // A reference to a modal result cache
  IModalResultCache = interface
    ['{62C0D393-F610-4167-8A79-7FD9C9B8AB35}']
    procedure Save(const ModalResultImplementor: IInterface);
  end;

  // A generic storage for a modal result
  TModalResultCache<T> = class (TInterfacedObject, IModalResult<T>,
    IModalResultCache)
  protected
    FModalResult: T;
    FModalResultSet: Boolean;
    function GetModalResult: T; virtual;
    function GetModalResultType: Pointer; virtual;
    procedure Save(const ModalResultImplementor: IInterface); virtual;
  end;

// Verify that TypeInfo's match and raise an exception if they don't
procedure VerifyGenericTypesMatch(
  ExpectedType: Pointer;
  FoundType: Pointer
);

implementation

uses
  System.SysUtils, DelphiUtils.LiteRTTI.Base;

procedure VerifyGenericTypesMatch;
var
  ExpectedName, FoundName, Message: String;
begin
  if ExpectedType <> FoundType then
  begin
    if Assigned(ExpectedType) then
      ExpectedName := PLiteRttiTypeInfo(ExpectedType).Name
    else
      ExpectedName := '<void>';

    if Assigned(FoundType) then
      FoundName := PLiteRttiTypeInfo(FoundType).Name
    else
      FoundName := '<void>';

    Message := 'Generic type mismatch detected: expected ' + ExpectedName +
      ' found ' + FoundName;
    raise EAssertionFailed.Create(Message);
  end;
end;

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

{ DefaultCaptionAttribute }

constructor DefaultCaptionAttribute.Create;
begin
  FDefaultCaption := Value;
end;

{ TModalResultCache<T> }

function TModalResultCache<T>.GetModalResult;
begin
  if FModalResultSet then
    Result := FModalResult
  else
    raise EArgumentException.Create('Modal result not available');
end;

function TModalResultCache<T>.GetModalResultType;
begin
  Result := TypeInfo(T);
end;

procedure TModalResultCache<T>.Save;
var
  Source: IModalResult<T>;
begin
  if ModalResultImplementor.QueryInterface(IModalResult<T>, Source) = S_OK then
  begin
    VerifyGenericTypesMatch(TypeInfo(T), Source.ModalResultType);
    FModalResult := Source.ModalResult;
    FModalResultSet := True;
  end;
end;

end.
