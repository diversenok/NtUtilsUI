unit UI.Prototypes.Forms;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Controls, Vcl.Forms,
  DelphiUtils.Events, VclEx.Form;

type
  TFormEvents = class abstract
    class var OnMainFormClose: TNotifyEventHandler;
  end;

  TChildFormMode = (
    cfmNormal,      // A child of the owner form
    cfmApplication, // A child of the Application form
    cfmDesktop      // A child of the desktop that appers on the taskbar
  );

  TChildForm = class abstract (TFormEx)
  private
    FChildMode: TChildFormMode;
    procedure PerformClose(const Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoClose(var Action: TCloseAction); override;
    procedure DoCreate; override;
  public
    constructor CreateChild(AOwner: TComponent; Mode: TChildFormMode);
    property ChildMode: TChildFormMode read FChildMode;
  end;

implementation

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

procedure TChildForm.DoClose;
begin
  inherited;
  TFormEvents.OnMainFormClose.Unsubscribe(PerformClose);
end;

procedure TChildForm.DoCreate;
begin
  inherited;
  TFormEvents.OnMainFormClose.Subscribe(PerformClose);
end;

procedure TChildForm.PerformClose;
begin
  Close;
end;

end.
