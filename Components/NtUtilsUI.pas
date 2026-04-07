unit NtUtilsUI;

{
  This module aggregates the base NtUtilsUI types.
}

interface

uses
  System.Classes, NtUtilsUI.Forms, NtUtilsUI.Base, NtUtilsUI.Components,
  NtUtilsUI.Colors;

const
  // Forward child form modes
  cfmNormal = NtUtilsUI.Forms.cfmNormal;
  cfmApplication = NtUtilsUI.Forms.cfmApplication;
  cfmDesktop = NtUtilsUI.Forms.cfmDesktop;

var
  // Choose the default color settings
  ColorSettings: PColorSettings = @DefaultColorSettings;

type
  // Forward known base classes and interfaces
  TUiLibMainForm = NtUtilsUI.Forms.TUiLibMainForm;
  TUiLibChildForm = NtUtilsUI.Forms.TUiLibChildForm;
  TUiLibShortCut = NtUtilsUI.Base.TUiLibShortCut;
  TUiLibControl = NtUtilsUI.Base.TUiLibControl;
  IHasDefaultCaption = NtUtilsUI.Base.IHasDefaultCaption;
  IHasModalResult = NtUtilsUI.Base.IHasModalResult;
  IHasModalResultObservation = NtUtilsUI.Base.IHasModalResultObservation;
  TWinControlFactory = NtUtilsUI.Components.TWinControlFactory;

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

end.
