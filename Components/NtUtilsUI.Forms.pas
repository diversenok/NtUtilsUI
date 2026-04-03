unit NtUtilsUI.Forms;

{
  This module introduces improved base classes for forms.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, NtUtils, DelphiUtils.AutoEvents;

type
  TFormEx = class abstract (TForm)
  private
    const idOnTop = 10001;
    procedure WMSysCommand(var Message: TWMSysCommand); message WM_SYSCOMMAND;
    procedure WMInitMenuPopup(var Message: TWMInitMenuPopup); message WM_INITMENUPOPUP;
    procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
  protected
    procedure DoClose(var Action: TCloseAction); override;
    procedure DoCreate; override;
    procedure DoShow; override;
  public
    function ShowModal: Integer; override;
  end;

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

function IsWindowTopmost(Handle: HWND): Boolean;

implementation

function IsWindowTopmost;
begin
  Result := GetWindowLongPtrW(Handle, GWL_EXSTYLE) and WS_EX_TOPMOST <> 0
end;

{ TFormEx }

procedure TFormEx.DoClose;
begin
  Action := caFree;
  inherited;
end;

procedure TFormEx.DoCreate;
begin
  inherited;

  // Add an item to toggle stay-on-top from the system menu
  if FormStyle in [fsNormal, fsStayOnTop] then
    InsertMenu(GetSystemMenu(Handle, False), 0, MF_STRING, idOnTop,
      'Stay On &Top');
end;

procedure TFormEx.DoShow;
var
  Control: TWinControl;
begin
  inherited;

  // Inherit stay-on-top from the owning form
  if (FormStyle = fsNormal) and (Owner is TWinControl) then
  begin
    Control := TWinControl(Owner);

    while Assigned(Control) and not (Control is TForm) do
      Control := Control.Parent;

    if (Control is TForm) and IsWindowTopmost(Control.Handle) then
      FormStyle := fsStayOnTop;
  end;
end;

function TFormEx.ShowModal;
begin
  Result := inherited;

  if ModalResult in [mrAbort, mrCancel] then
    Abort;
end;

procedure TFormEx.WMInitMenuPopup;
const
  STATE: array [Boolean] of Cardinal = (MF_UNCHECKED, MF_CHECKED);
begin
  // Update the check state of our stay-on-top menu item
  if Message.SystemMenu then
    CheckMenuItem(Message.MenuPopup, idOnTop, STATE[IsWindowTopmost(Handle)]);

  inherited;
end;

procedure TFormEx.WMSysCommand;
begin
  // Toggle the stay-on-top state from the menu
  if Message.CmdType = idOnTop then
    case FormStyle of
      fsNormal:    FormStyle := fsStayOnTop;
      fsStayOnTop: FormStyle := fsNormal;
    end
  else
    inherited;
end;

procedure TFormEx.WMWindowPosChanged;
begin
  inherited;

  if Message.WindowPos.flags and SWP_NOZORDER = 0 then
  begin
    // FormStyle can desync from the actual state if an external caller changes
    // it. Detect and fix it here.
    case FormStyle of
      fsNormal:
        if IsWindowTopmost(Handle) then
          FormStyle := fsStayOnTop;

      fsStayOnTop:
        if not IsWindowTopmost(Handle) then
          FormStyle := fsNormal;
    end;

    // Also, if any window becomes topmost, make sure the application
    // window does as well, so that dialogs can inherit the style from it.
    if FormStyle = fsStayOnTop then
      SetWindowPos(Application.Handle, HWND_TOPMOST, 0, 0, 0, 0,
        SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
  end;
end;

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
