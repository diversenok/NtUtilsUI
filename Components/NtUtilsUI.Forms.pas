unit NtUtilsUI.Forms;

{
  This module introduces improved base classes for forms.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, NtUtils, DelphiUtils.AutoEvents;

type
  TUiLibShortCut = class (TComponent)
  private
    FShortCut: TShortCut;
    FOnExecute: TNotifyEvent;
  public
    property ShortCut: TShortCut read FShortCut write FShortCut;
    property OnExecute: TNotifyEvent read FOnExecute write FOnExecute;
    procedure Invoke;
  end;

  TUiLibForm = class abstract (TForm)
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
    function IsShortCut(var Message: TWMKey): Boolean; override;
  end;

  TUiLibMainForm = class abstract (TUiLibForm)
  private
    class var FInstance: TUiLibMainForm;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class property Instance: TUiLibMainForm read FInstance;
    class var OnMainFormClose: TAutoEvent;
  end;

  TUiLibChildFormMode = (
    cfmNormal,      // No taskbar; overlaps the owner
    cfmApplication, // No taskbar; side-by-side with the owner; use with modal
    cfmDesktop      // Visible on taskbar; side-by-side with the owner
  );

  TUiLibChildForm = class abstract (TUiLibForm)
  private
    FChildMode: TUiLibChildFormMode;
    FMainFormCloseSubscription: IAutoReleasable;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoCreate; override;
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent; Mode: TUiLibChildFormMode); reintroduce;
    property ChildMode: TUiLibChildFormMode read FChildMode;
  end;

function IsWindowTopmost(Handle: HWND): Boolean;

implementation

uses
  Vcl.Menus;

function IsWindowTopmost;
begin
  Result := GetWindowLongPtrW(Handle, GWL_EXSTYLE) and WS_EX_TOPMOST <> 0
end;

procedure DispatchShortCut(const Owner: TComponent; ShortCut: TShortCut);
var
  i: Integer;
  Component: TComponent;
begin
  // Always dispatch to all children
  for i := 0 to Pred(Owner.ComponentCount) do
  begin
    Component := Owner.Components[i];

    if Component is TUiLibShortCut then
    begin
      if TUiLibShortCut(Component).ShortCut = ShortCut then
        TUiLibShortCut(Component).Invoke;
    end
    else
      DispatchShortCut(Component, ShortCut);
  end;
end;

{ TUiLibShortCut }

procedure TUiLibShortCut.Invoke;
begin
  if Assigned(FOnExecute) then
    FOnExecute(Self);
end;

{ TUiLibForm }

procedure TUiLibForm.DoClose;
begin
  Action := caFree;
  inherited;
end;

procedure TUiLibForm.DoCreate;
begin
  inherited;

  // Add an item to toggle stay-on-top from the system menu
  if FormStyle in [fsNormal, fsStayOnTop] then
    InsertMenu(GetSystemMenu(Handle, False), 0, MF_STRING, idOnTop,
      'Stay On &Top');
end;

procedure TUiLibForm.DoShow;
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

function TUiLibForm.IsShortCut;
begin
  Result := inherited;

  if not Vcl.Menus.IsAltGRPressed then
    DispatchShortCut(Self, Vcl.Menus.ShortCut(Message.CharCode,
      KeyDataToShiftState(Message.KeyData)));
end;

function TUiLibForm.ShowModal;
begin
  Result := inherited;

  if ModalResult in [mrAbort, mrCancel] then
    Abort;
end;

procedure TUiLibForm.WMInitMenuPopup;
const
  STATE: array [Boolean] of Cardinal = (MF_UNCHECKED, MF_CHECKED);
begin
  // Update the check state of our stay-on-top menu item
  if Message.SystemMenu then
    CheckMenuItem(Message.MenuPopup, idOnTop, STATE[IsWindowTopmost(Handle)]);

  inherited;
end;

procedure TUiLibForm.WMSysCommand;
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

procedure TUiLibForm.WMWindowPosChanged;
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

{ TUiLibMainForm }

constructor TUiLibMainForm.Create;
begin
  inherited Create(AOwner);
  Assert(not Assigned(FInstance), 'Created multiple main forms.');
  FInstance := Self;
end;

destructor TUiLibMainForm.Destroy;
begin
  if FInstance = Self then
    FInstance := nil;

  inherited;
end;

{ TUiLibChildForm }

constructor TUiLibChildForm.Create;
begin
  FChildMode := Mode;
  inherited Create(AOwner);

  if FChildMode <> cfmDesktop then
    BorderIcons := BorderIcons - [biMinimize];
end;

procedure TUiLibChildForm.CreateParams;
begin
  inherited;

  case FChildMode of
    cfmApplication: Params.WndParent := Application.Handle;
    cfmDesktop:     Params.WndParent := HWND_DESKTOP
  end;
end;

procedure TUiLibChildForm.DoCreate;
begin
  inherited;
  FMainFormCloseSubscription := TUiLibMainForm.OnMainFormClose.Subscribe(Close);
end;

procedure TUiLibChildForm.DoShow;
begin
  // Our parent class makes us inherit stay-on-top from the owner
  inherited;

  // If there is no owner, inherit it from the main form
  if not Assigned(Owner) and Assigned(TUiLibMainForm.Instance) and
    (TUiLibMainForm.Instance.FormStyle = fsStayOnTop) and (FormStyle = fsNormal) then
    FormStyle := fsStayOnTop;
end;

end.
