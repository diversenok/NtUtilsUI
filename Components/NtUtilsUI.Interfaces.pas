unit NtUtilsUI.Interfaces;

{
  This module provides definitions for optional component interfaces.
}

interface

uses
  System.Classes;

type
  TUiLibShortCut = class;
  TUiLibShortCutEvent = procedure (Sender: TUiLibShortCut; var Handled: Boolean) of object;

  TUiLibShortCut = class (TComponent)
  private
    FShortCut: TShortCut;
    FOnExecute: TUiLibShortCutEvent;
  public
    property ShortCut: TShortCut read FShortCut write FShortCut;
    property OnExecute: TUiLibShortCutEvent read FOnExecute write FOnExecute;
    function Invoke: Boolean;
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

{ TUiLibShortCut }

function TUiLibShortCut.Invoke;
begin
  Result := False;

  if Assigned(FOnExecute) then
    FOnExecute(Self, Result);
end;

end.
