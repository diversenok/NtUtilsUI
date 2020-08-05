unit UI.Prototypes.Forms;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Controls, Vcl.Forms,
  DelphiUtils.Events, VclEx.Form;

type
  TFormEvents = class abstract
    class var OnMainFormClose: TNotifyEventHandler;
  end;

  TChildForm = class abstract (TFormEx)
  private
    FShowOnTaskbar: Boolean;
    procedure PerformClose(const Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoClose(var Action: TCloseAction); override;
    procedure DoCreate; override;
  public
    constructor CreateChild(AOwner: TComponent; ShowOnTaskbar: Boolean);
  end;

implementation

{ TChildForm }

constructor TChildForm.CreateChild(AOwner: TComponent; ShowOnTaskbar: Boolean);
begin
  FShowOnTaskbar := ShowOnTaskbar;
  inherited Create(AOwner);

  if not FShowOnTaskbar then
    BorderIcons := BorderIcons - [biMinimize];
end;

procedure TChildForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  if FShowOnTaskbar then
    Params.WndParent := HWND_DESKTOP;
end;

procedure TChildForm.DoClose(var Action: TCloseAction);
begin
  inherited;
  TFormEvents.OnMainFormClose.Unsubscribe(PerformClose);
end;

procedure TChildForm.DoCreate;
begin
  inherited;
  TFormEvents.OnMainFormClose.Subscribe(PerformClose);
end;

procedure TChildForm.PerformClose(const Sender: TObject);
begin
  Close;
end;

end.
