unit NtUtilsUI;

{
  This module provides base NtUtilsUI types.
  
  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, NtUtilsUI.Forms;

type
  // Forward base form classes
  TUiLibMainForm = NtUtilsUI.Forms.TUiLibMainForm;
  TUiLibChildForm = NtUtilsUI.Forms.TUiLibChildForm;

const
  // Forward child form modes
  cfmNormal = NtUtilsUI.Forms.cfmNormal;
  cfmApplication = NtUtilsUI.Forms.cfmApplication;
  cfmDesktop = NtUtilsUI.Forms.cfmDesktop;

type
  // Indicates a component that can prevent Escape from closing the dialog
  ICanConsumeEscape = interface
    ['{4280FDBC-97C0-41DC-9C96-98142BCABADF}']
    function ConsumesEscape: Boolean;
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

  // A base class for composite visual controls
  TUiLibControl = class abstract (TWinControl)
  protected
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  published
    property Align;
    property Anchors;
    property Enabled;
    property TabOrder;
    property TabStop;
    property Visible;
  end;

implementation

uses
  NtUtilsUI.Exceptions;
  
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

end.
