unit UI.Prototypes.Forms;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Controls, Vcl.Forms,
  DelphiUtils.AutoEvents, VclEx.Form;

type
  TFormEvents = class abstract
    class var OnMainFormClose: TAutoEvent;
    class constructor Create;
  end;

  TChildFormMode = (
    cfmNormal,      // A child of the owner form
    cfmApplication, // A child of the Application form
    cfmDesktop      // A child of the desktop that appers on the taskbar
  );

  TChildForm = class abstract (TFormEx)
  private
    FChildMode: TChildFormMode;
    FMainFormCloseSubscription: IAutoReleasable;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoCreate; override;
  public
    constructor CreateChild(AOwner: TComponent; Mode: TChildFormMode);
    property ChildMode: TChildFormMode read FChildMode;
  end;

implementation

uses
  System.SysUtils, UI.Exceptions;

{ TChildForm }

constructor TChildForm.CreateChild;
begin
  FChildMode := Mode;
  inherited Create(AOwner);

  if FChildMode <> cfmDesktop then
    BorderIcons := BorderIcons - [biMinimize];
end;

procedure TChildForm.CreateParams;
begin
  inherited;

  case FChildMode of
    cfmApplication: Params.WndParent := Application.Handle;
    cfmDesktop:     Params.WndParent := HWND_DESKTOP
  end;
end;

procedure TChildForm.DoCreate;
begin
  inherited;
  FMainFormCloseSubscription := TFormEvents.OnMainFormClose.Subscribe(Close);
end;

{ TFormEvents }

class constructor TFormEvents.Create;
begin
  // Make sure exceptions cannot prevent the program from closing
  OnMainFormClose.SetCustomInvoker(TExceptionSafeInvoker.NoParameters);
end;

end.
