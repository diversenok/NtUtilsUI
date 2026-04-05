unit NtUtilsUI.Components;

{
  This module provides the central registration for optional components.
}

interface

uses
  System.Classes, Vcl.Controls;

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

implementation

end.
