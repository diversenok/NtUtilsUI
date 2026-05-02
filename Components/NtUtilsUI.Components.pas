unit NtUtilsUI.Components;

{
  This module provides the central registration for optional components.
}

interface

uses
  System.Classes, Ntapi.ntseapi, NtUtils, NtUtilsUI.Components.Factories;

const
  MSG_E_NO_COMPONENT = 'The required component is not registered';

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

// Display a dialog with a list of privileges
procedure UiLibShowPrivilegeList(
  const Privileges: TArray<TPrivilege>
);

// Display a dialog with a list of all known privileges
procedure UiLibShowPrivilegeListAll;

implementation

function UiLibPickIntegritySid;
begin
  if Assigned(UiLibHostPick) and Assigned(UiLibFactoryIntegritySid) then
    Result := ISid(UiLibHostPick(Owner, UiLibFactoryIntegritySid(InitialChoice)))
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

function UiLibPickTrustSid;
begin
  if Assigned(UiLibHostPick) and Assigned(UiLibFactoryTrustSid) then
    Result := ISid(UiLibHostPick(Owner, UiLibFactoryTrustSid(InitialChoice)))
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

procedure UiLibShowPrivilegeList;
begin
  if Assigned(UiLibHostShow) and Assigned(UiLibFactoryPrivilegeList) then
    UiLibHostShow(UiLibFactoryPrivilegeList(Privileges))
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

procedure UiLibShowPrivilegeListAll;
begin
  if Assigned(UiLibHostShow) and Assigned(UiLibFactoryPrivilegeListAll) then
    UiLibHostShow(UiLibFactoryPrivilegeListAll())
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

end.
