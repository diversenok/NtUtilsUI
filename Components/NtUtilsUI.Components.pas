unit NtUtilsUI.Components;

{
  This module provides the central registration for optional components.
}

interface

uses
  System.Classes, Vcl.Controls, NtUtils;

type
  // An anonymous function that can instantiate visual controls
  TWinControlFactory = reference to function (AOwner: TComponent): TWinControl;

var
  // A host for showing a control in a dialog
  UiLibHostShow: procedure (
    ControlFactory: TWinControlFactory
  );

  // A host for showing a control in a modal dialog
  UiLibHostPick: function (
    AOwner: TComponent;
    ControlFactory: TWinControlFactory
  ): IInterface;

  { SIDs }

  // A host for selecting an integrity SID
  UiLibHostPickIntegritySid: function (
    Owner: TComponent;
    [opt] const InitialChoice: ISid = nil
  ): ISid;

    // A host for selecting a trust SID
  UiLibHostPickTrustSid: function (
    Owner: TComponent;
    [opt] const InitialChoice: ISid = nil
  ): ISid;

// Show a modal dialog to choose an integrity SID
function UiLibPickIntegritySid(
  Owner: TComponent;
  [opt] const InitialChoice: ISid = nil
): ISid;

// Show a modal dialog to choose a trust SID
function UiLibPickTrustSid(
  Owner: TComponent;
  [opt] const InitialChoice: ISid = nil
): ISid;

implementation

const
  MSG_E_NO_COMPONENT = 'The required component is not registered';

function UiLibPickIntegritySid;
begin
  if Assigned(UiLibHostPickIntegritySid) then
    Result := UiLibHostPickIntegritySid(Owner, InitialChoice)
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

function UiLibPickTrustSid;
begin
  if Assigned(UiLibHostPickTrustSid) then
    Result := UiLibHostPickTrustSid(Owner, InitialChoice)
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

end.
