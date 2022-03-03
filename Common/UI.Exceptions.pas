unit UI.Exceptions;

{
  This module allows configuring default exception handling for UI applications.
}

interface

uses
  System.SysUtils;

// Show the default exception dialog
procedure ReportException(E: Exception);

// Adjust Application.OnException to use our exception dialog.
procedure EnableNtxExceptionHandling;

implementation

uses
  DelphiUtils.AutoObjects, NtUiLib.Exceptions.Dialog, Vcl.Forms;

type
  TUIExceptionHandler = class
    procedure Display(Sender: TObject; E: Exception);
    class var Instance: IAutoObject<TUIExceptionHandler>;
  end;

procedure ReportException;
begin
  ShowNtxException(Application.Handle, E)
end;

procedure EnableNtxExceptionHandling;
begin
  // Cache the instance since we need a "procedure of object"
  if not Assigned(TUIExceptionHandler.Instance) then
    TUIExceptionHandler.Instance := Auto.From(TUIExceptionHandler.Create);

  Application.OnException := TUIExceptionHandler.Instance.Data.Display;
end;

procedure TUIExceptionHandler.Display;
begin
  ReportException(E);
end;

end.

