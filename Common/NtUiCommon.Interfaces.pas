unit NtUiCommon.Interfaces;

{
  This module provides interfaces for better integrating UI components.
}

interface

type
  // Indicates a component with a search bar that should obtain focus on Ctrl+F
  IHasSearch = interface
    ['{987D54D2-1AEA-4FCA-B9B5-890A94B961BD}']
    procedure SetSearchFocus;
  end;

  // Indicates a component that can prevent Escape from closing the dialog
  ICanConsumeEscape = interface
    ['{4280FDBC-97C0-41DC-9C96-98142BCABADF}']
    function ConsumesEscape: Boolean;
  end;

implementation

end.
