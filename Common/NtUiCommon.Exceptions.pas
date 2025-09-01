unit NtUiCommon.Exceptions;

{
  This module allows configuring default exception handling for UI applications
  and adds support for capturing stack traces.
}

interface

// Show NtUiLib exception dialog
procedure ReportException(E: TObject);

// Set NtUiLib exception dialog as the handler for Application.OnException
procedure EnableNtUiLibExceptionHandling;

implementation

uses
  DelphiUtils.AutoObjects, DelphiUtils.AutoEvents, NtUiLib.Exceptions.Dialog,
  System.SysUtils, Vcl.Forms;

{ NtUiLib Exception Handler }

procedure ReportException;
begin
  ShowNtxException(Application.Handle, E);
end;

type
  TUIExceptionHandler = class
    procedure Display(Sender: TObject; E: Exception);
    class var Instance: IObject<TUIExceptionHandler>;
  end;

procedure EnableNtUiLibExceptionHandling;
begin
  // Cache the instance since we need a "procedure of object"
  if not Assigned(TUIExceptionHandler.Instance) then
    TUIExceptionHandler.Instance := Auto.CaptureObject(TUIExceptionHandler.Create);

  Application.OnException := TUIExceptionHandler.Instance.Self.Display;
end;

procedure TUIExceptionHandler.Display;
begin
  ReportException(E);
end;

function ReportAutoEventsException(
  E: TObject
): Boolean;
begin
  ReportException(E);
  Result := True;
end;

initialization
  // Enable exception handling for DelphiUtils.AutoEvents
  AutoExceptionHanlder := ReportAutoEventsException;
end.

