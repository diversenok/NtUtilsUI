unit UI.Exceptions;

{
  This module allows configuring default exception handling for UI applications
  and adds support for capturing stack traces.
}

interface

uses
  System.SysUtils, DelphiUtils.AutoEvents;

// Show NtUiLib exception dialog
procedure ReportException(E: Exception);

// Set NtUiLib exception dialog as the hander for Application.OnException
procedure EnableNtUiLibExceptionHandling;

type
  // Custom exception-safe invokers for automatic events
  TExceptionSafeInvoker = record
    class procedure NoParameters(
      const Callback: TEventCallback
    ); static;

    class procedure OneParameter<T>(
      const Callback: TEventCallback<T>;
      const Parameter: T
    ); static;

    class procedure TwoParameters<T1, T2>(
      const Callback: TEventCallback<T1, T2>;
      const Parameter1: T1;
      const Parameter2: T2
    ); static;
  end;

implementation

uses
  DelphiUtils.AutoObjects, NtUiLib.Exceptions.Dialog, Vcl.Forms;

{ NtUiLib Exception Hanlder }

procedure ReportException;
begin
  ShowNtxException(Application.Handle, E)
end;

type
  TUIExceptionHandler = class
    procedure Display(Sender: TObject; E: Exception);
    class var Instance: IAutoObject<TUIExceptionHandler>;
  end;

procedure EnableNtUiLibExceptionHandling;
begin
  // Cache the instance since we need a "procedure of object"
  if not Assigned(TUIExceptionHandler.Instance) then
    TUIExceptionHandler.Instance := Auto.From(TUIExceptionHandler.Create);

  Application.OnException := TUIExceptionHandler.Instance.Self.Display;
end;

procedure TUIExceptionHandler.Display;
begin
  ReportException(E);
end;

{ Safe Event Invoker }

class procedure TExceptionSafeInvoker.NoParameters;
begin
  try
    Callback;
  except
    on E: Exception do
      ReportException(E);
  end;
end;

class procedure TExceptionSafeInvoker.OneParameter<T>;
begin
  try
    Callback(Parameter);
  except
    on E: Exception do
      ReportException(E);
  end;
end;

class procedure TExceptionSafeInvoker.TwoParameters<T1, T2>;
begin
  try
    Callback(Parameter1, Parameter2);
  except
    on E: Exception do
      ReportException(E);
  end;
end;

end.

