unit NtUiCommon.Forms;

{
  This module provides base classes for forms.
}

interface

uses
  Winapi.Windows, System.Classes, Vcl.Controls, Vcl.Forms,
  DelphiUtils.AutoObjects, DelphiUtils.AutoEvents, VclEx.Form;

type
  TMainForm = class abstract (TFormEx)
  private
    class var FInstance: TMainForm;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class property Instance: TMainForm read FInstance;
    class var OnMainFormClose: TAutoEvent;
  end;

  TChildFormMode = (
    cfmNormal,      // No taskbar; overlaps the owner
    cfmApplication, // No taskbar; side-by-side with the owner; use with modal
    cfmDesktop      // Visible on taskbar; side-by-side with the owner
  );

  TChildForm = class abstract (TFormEx)
  private
    FChildMode: TChildFormMode;
    FMainFormCloseSubscription: IAutoReleasable;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoCreate; override;
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent; Mode: TChildFormMode); reintroduce;
    property ChildMode: TChildFormMode read FChildMode;
  end;

implementation

uses
  System.SysUtils, NtUiCommon.Exceptions;

{ TMainForm }

constructor TMainForm.Create;
begin
  inherited Create(AOwner);
  Assert(not Assigned(FInstance), 'Created multiple main forms.');
  FInstance := Self;
end;

destructor TMainForm.Destroy;
begin
  if FInstance = Self then
    FInstance := nil;

  inherited;
end;

{ TChildForm }

constructor TChildForm.Create;
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
  FMainFormCloseSubscription := TMainForm.OnMainFormClose.Subscribe(Close);
end;

procedure TChildForm.DoShow;
begin
  // Our parent class makes us inherit stay-on-top from the owner
  inherited;

  // If there is no owner, inherit it from the main form
  if not Assigned(Owner) and Assigned(TMainForm.Instance) and
    (TMainForm.Instance.FormStyle = fsStayOnTop) and (FormStyle = fsNormal) then
    FormStyle := fsStayOnTop;
end;

end.
