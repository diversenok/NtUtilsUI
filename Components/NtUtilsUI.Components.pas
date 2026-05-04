unit NtUtilsUI.Components;

{
  This module provides the central registration for optional components.
}

interface

uses
  System.Classes, Vcl.Controls, Ntapi.WinNt, Ntapi.ntseapi, NtUtils,
  NtUtilsUI.Components.Factories;

const
  MSG_E_NO_COMPONENT = 'The required component is not registered';

type
  UiLibHost = class abstract
    // Display a control in a non-modal dialog
    class procedure Show(ControlFactory: TWinControlFactory); static;

    // Display a control in a modal dialog and return its modal result
    class function Pick<T>(AOwner: TComponent; ControlFactory: TWinControlFactory): T; static;
  end;

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

// Show a modal dialog to choose a session ID
function UiLibPickSessionId(
  Owner: TComponent;
  InitialChoice: TSessionId = TSessionId(-1)
): TSessionId;

implementation

uses
  NtUtilsUI.Base;

{ UiLibHost }

class function UiLibHost.Pick<T>;
var
  Cache: IModalResult<T>;
begin
  if not Assigned(UiLibHostPick) then
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);

  Cache := TModalResultCache<T>.Create;
  UiLibHostPick(AOwner, ControlFactory, Cache as IModalResultCache);
  Result := Cache.ModalResult;
end;

class procedure UiLibHost.Show;
begin
  if not Assigned(UiLibHostShow) then
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);

  UiLibHostShow(ControlFactory);
end;

{ Functions }

function UiLibPickIntegritySid;
begin
  if Assigned(UiLibFactoryIntegritySid) then
    Result := UiLibHost.Pick<ISid>(Owner,
      UiLibFactoryIntegritySid(InitialChoice))
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

function UiLibPickTrustSid;
begin
  if Assigned(UiLibFactoryTrustSid) then
    Result := UiLibHost.Pick<ISid>(Owner,
      UiLibFactoryTrustSid(InitialChoice))
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

procedure UiLibShowPrivilegeList;
begin
  if Assigned(UiLibFactoryPrivilegeList) then
    UiLibHost.Show(UiLibFactoryPrivilegeList(Privileges))
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

procedure UiLibShowPrivilegeListAll;
begin
  if Assigned(UiLibFactoryPrivilegeListAll) then
    UiLibHost.Show(UiLibFactoryPrivilegeListAll())
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

function UiLibPickSessionId;
begin
  if Assigned(UiLibFactorySessionId) then
    Result := UiLibHost.Pick<TSessionId>(Owner,
      UiLibFactorySessionId(InitialChoice))
  else
    raise EClassNotFound.Create(MSG_E_NO_COMPONENT);
end;

end.
