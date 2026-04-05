unit NtUtilsUI;

{
  This module provides base NtUtilsUI types.
  
  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, NtUtilsUI.Forms,
  NtUtilsUI.Interfaces;

type
  // Forward base form classes
  TUiLibMainForm = NtUtilsUI.Forms.TUiLibMainForm;
  TUiLibChildForm = NtUtilsUI.Forms.TUiLibChildForm;

  // Forward known component interfaces
  ICanConsumeEscape = NtUtilsUI.Interfaces.ICanConsumeEscape;
  IHasDefaultCaption = NtUtilsUI.Interfaces.IHasDefaultCaption;
  IHasModalResult = NtUtilsUI.Interfaces.IHasModalResult;
  IHasModalResultObservation = NtUtilsUI.Interfaces.IHasModalResultObservation;

const
  // Forward child form modes
  cfmNormal = NtUtilsUI.Forms.cfmNormal;
  cfmApplication = NtUtilsUI.Forms.cfmApplication;
  cfmDesktop = NtUtilsUI.Forms.cfmDesktop;

type
  // An anonymous function that can instantiate visual controls
  TWinControlFactory = reference to function (AOwner: TComponent): TWinControl;

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
