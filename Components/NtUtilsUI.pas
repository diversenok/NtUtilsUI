unit NtUtilsUI;

{
  This module provides base NtUtilsUI types.
  
  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, NtUtilsUI.Forms,
  NtUtilsUI.Interfaces, NtUtilsUI.Components, NtUtilsUI.Colors;

const
  // Forward child form modes
  cfmNormal = NtUtilsUI.Forms.cfmNormal;
  cfmApplication = NtUtilsUI.Forms.cfmApplication;
  cfmDesktop = NtUtilsUI.Forms.cfmDesktop;

var
  // Choose the default color settings
  ColorSettings: PColorSettings = @DefaultColorSettings;

type
  // Forward base form and shortcut classes
  TUiLibMainForm = NtUtilsUI.Forms.TUiLibMainForm;
  TUiLibChildForm = NtUtilsUI.Forms.TUiLibChildForm;
  TUiLibShortCut = NtUtilsUI.Interfaces.TUiLibShortCut;

  // Forward known component interfaces
  IHasDefaultCaption = NtUtilsUI.Interfaces.IHasDefaultCaption;
  IHasModalResult = NtUtilsUI.Interfaces.IHasModalResult;
  IHasModalResultObservation = NtUtilsUI.Interfaces.IHasModalResultObservation;

  // Forward control factory
  TWinControlFactory = NtUtilsUI.Components.TWinControlFactory;

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

// Show a control in a dialog
procedure UiLibShow(
  ControlFactory: TWinControlFactory
);

// Show a control in a modal dialog and return its modal result
function UiLibPick(
  AOwner: TComponent;
  ControlFactory: TWinControlFactory
): IInterface;

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

{ Functions }

const
  MSG_E_NO_HOST = 'The component hosting dialog is not registered';

procedure UiLibShow(ControlFactory: TWinControlFactory);
begin
  if Assigned(UiLibHostShow) then
    UiLibHostShow(ControlFactory)
  else
    raise EClassNotFound.Create(MSG_E_NO_HOST);
end;

function UiLibPick;
begin
  if Assigned(UiLibHostPick) then
    Result := UiLibHostPick(AOwner, ControlFactory)
  else
    raise EClassNotFound.Create(MSG_E_NO_HOST);
end;

function TUiLibControl.Focused;
var
  i: Integer;
begin
  Result := inherited;

  if not Result then
    for i := 0 to Pred(ControlCount) do
      if (Controls[i] is TWinControl) and TWinControl(Controls[i]).Focused then
      begin
        Result := True;
        Break;
      end;
end;

end.
