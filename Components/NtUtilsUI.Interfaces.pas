unit NtUtilsUI.Interfaces;

{
  This module provides definitions for optional component interfaces.
}

interface

uses
  System.Classes;

type
  // Indicates a component that can prevent Escape from closing the dialog
  ICanConsumeEscape = interface
    ['{4280FDBC-97C0-41DC-9C96-98142BCABADF}']
    function ConsumesEscape: Boolean;
  end;

  // Indicates a component that suggests a modal dialog or page caption
  IHasDefaultCaption = interface
    ['{C6238589-5504-461B-8539-F391A4DCC52B}']
    function GetDefaultCaption: String;
  end;

  // Indicates a component that allows returning a result from a modal dialog
  IHasModalResult = interface
    ['{F5CFA05F-11FE-46BD-8004-01696E95103D}']
    function GetModalResult: IInterface;
    property ModalResult: IInterface read GetModalResult;
  end;

  // Indicates ability to observe changes to modal result availability
  IHasModalResultObservation = interface (IHasModalResult)
    ['{D4AB2813-C236-43D7-9ABF-C46CE7923770}']
    function GetHasModalResult: Boolean;
    function GetOnModalResultChanged: TNotifyEvent;
    procedure SetOnModalResultChanged(const Callback: TNotifyEvent);
    property HasModalResult: Boolean read GetHasModalResult;
    property OnModalResultChanged: TNotifyEvent
      read GetOnModalResultChanged
      write SetOnModalResultChanged;
  end;

implementation

end.
