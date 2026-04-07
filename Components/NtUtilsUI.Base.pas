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
  end;

  // Indicates a component that suggests a modal dialog or page caption
  IHasDefaultCaption = interface
    ['{C6238589-5504-461B-8539-F391A4DCC52B}']
    function GetDefaultCaption: String;
  end;

  // Indicates a component that allows returning a result from a modal dialog
  IHasModalResult = interface
    ['{F5CFA05F-11FE-46BD-8004-01696E95103D}']
    function GetModalResult: IInterface;
    property ModalResult: IInterface read GetModalResult;
  end;

  // Indicates ability to observe changes to modal result availability
  IHasModalResultObservation = interface (IHasModalResult)
    ['{D4AB2813-C236-43D7-9ABF-C46CE7923770}']
    function GetHasModalResult: Boolean;
    function GetOnModalResultChanged: TNotifyEvent;
    procedure SetOnModalResultChanged(const Callback: TNotifyEvent);
    property HasModalResult: Boolean read GetHasModalResult;
    property OnModalResultChanged: TNotifyEvent
      read GetOnModalResultChanged
      write SetOnModalResultChanged;
  end;

implementation

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

end.
