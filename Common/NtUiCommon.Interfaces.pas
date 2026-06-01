unit NtUiCommon.Interfaces;

{
  This module provides interfaces for better integrating UI components.
}

interface

type
  { Common interfaces }

  // Indicates a component that can show a message when no data is available
  ICanShowEmptyMessage = interface
    ['{A56C56BB-9839-4B48-B727-03610765C488}']
    procedure SetEmptyMessage(const Value: String);
  end;

  // Indicates a control that can delay initialization until unhidden
  IDelayedLoad = interface
    ['{B095F57F-79C5-4205-B9F8-5EE3618AD8CA}']
    procedure DelayedLoad;
  end;

  { Modal dialog support }

  // Indicates a component that controls button caption for the modal dialog host
  IHasModalButtonCaptions = interface
    ['{730893B5-A88C-42A0-9AC3-C7CD1867CA48}']
    function GetConfirmationCaption: String;
    function GetCancellationCaption: String;
    property ConfirmationCaption: String read GetConfirmationCaption;
    property CancellationCaption: String read GetCancellationCaption;
  end;

  // Allows a tree node to opt-out of being returned as a modal result
  IOptionalModalResultNode = interface
    ['{0B51C7F3-0E9A-4691-A1B0-6EF1769E05F2}']
    function GetAllowsModalReturn: Boolean;
    property AllowsModalReturn: Boolean read GetAllowsModalReturn;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
