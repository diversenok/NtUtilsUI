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

// Add stack trace support to exception handling
procedure EnableStackTracingExceptions;

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
  NtUtils, NtUtils.Ldr, NtUtils.DbgHelp, DelphiUtils.AutoObjects,
  NtUiLib.Exceptions.Dialog, Vcl.Forms;

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

{ Stack Trace Support }

// A callback for capturing the stack trace when an exception occurs
function GetExceptionStackInfoProc(P: PExceptionRecord): Pointer;
var
  Trace: TArray<Pointer> absolute Result;
  i: Integer;
begin
  // Clean-up before assigning
  Result := nil;

  // Capture the backtrace
  Trace := RtlxCaptureStackTrace;

  // Trim it by removing exception-handling frames
  for i := 0 to High(Trace) do
    if Trace[i] = P.ExceptionAddress then
    begin
      Delete(Trace, 0, i);
      Break;
    end;
end;

{$IFDEF Win64}
// A callback for representing the stack trace
function GetStackInfoStringProc(Info: Pointer): string;
var
  Trace: TArray<Pointer> absolute Info;
  Modules: TArray<TModuleEntry>;
  Frames: TArray<String>;
  i: Integer;
begin
  Modules := LdrxEnumerateModules;
  SetLength(Frames, Length(Trace));

  for i := 0 to High(Trace) do
    Frames[i] := SymxFindBestMatch(Modules, Trace[i]).ToString;

  Result := String.Join(#$D#$A, Frames);
end;
{$ELSE}
function GetStackInfoStringProc(Info: Pointer): string;
begin
  // TODO: fix NtUtils's DbgHelp support on WoW64
  // TODO: fallback to export-based symbol enumeration
  Result := '(not supported under WoW64)';
end;
{$ENDIF}

procedure CleanUpStackInfoProc(Info: Pointer);
var
  Trace: TArray<Pointer> absolute Info;
begin
  Finalize(Trace);
end;

procedure EnableStackTracingExceptions;
begin
  Exception.GetExceptionStackInfoProc := GetExceptionStackInfoProc;
  Exception.GetStackInfoStringProc := GetStackInfoStringProc;
  Exception.CleanUpStackInfoProc := CleanUpStackInfoProc;
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

