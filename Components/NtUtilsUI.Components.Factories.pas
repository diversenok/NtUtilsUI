unit NtUtilsUI.Components.Factories;

{
  This module provides the central registration for optional components.
}

interface

uses
  System.Classes, Vcl.Controls, Ntapi.ntseapi, NtUtils, NtUtilsUI.Base;

type
  // An anonymous function that can instantiate visual controls
  TWinControlFactory = reference to function (AOwner: TComponent): TWinControl;

var
  // A host for showing a control in a dialog
  UiLibHostShow: procedure (
    ControlFactory: TWinControlFactory
  );

  // A host for showing a control in a modal dialog
  UiLibHostPick: procedure (
    AOwner: TComponent;
    ControlFactory: TWinControlFactory;
    ModalResultCache: IModalResultCache
  );

  { SIDs }

  // A control factory for selecting an integrity SID
  UiLibFactoryIntegritySid: function (
    const InitialChoice: ISid = nil
  ): TWinControlFactory;

    // A control factory for selecting a trust SID
  UiLibFactoryTrustSid: function (
    [opt] const InitialChoice: ISid = nil
  ): TWinControlFactory;

  { Privileges }

  // A control factory for displaying a list of privileges
  UiLibFactoryPrivilegeList: function (
    const Privileges: TArray<TPrivilege>
  ): TWinControlFactory;

  // A control factory for displaying a list of all known privileges
  UiLibFactoryPrivilegeListAll: function (
  ): TWinControlFactory;

implementation

end.
