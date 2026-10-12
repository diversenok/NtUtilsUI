unit NtUtilsUI.Forms;

{
  This module contains the full runtime component definitions for the improved
  base form classes.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, NtUtils, DelphiUtils.AutoEvents, NtUtilsUI.Base;

type
  TUiLibForm = class abstract (TForm)
  strict private
    const idStayOnTop = 10001;
    const idPersistStayOnTop = 10002;
    var FCloseOnEscape: Boolean;
    procedure WMSysCommand(var Message: TWMSysCommand); message WM_SYSCOMMAND;
    procedure WMInitMenuPopup(var Message: TWMInitMenuPopup); message WM_INITMENUPOPUP;
    procedure WMWindowPosChanging(var Message: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;
    procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
    function GetFormStyle: TFormStyle;
    procedure SetFormStyle(Value: TFormStyle);
  strict protected
    class var FPersistStayOnTop: Boolean;
    procedure DoClose(var Action: TCloseAction); override;
    procedure DoCreate; override;
    procedure DoShow; override;
  public
    function ShowModal: Integer; override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
  published
    property CloseOnEscape: Boolean read FCloseOnEscape write FCloseOnEscape;
    property FormStyle: TFormStyle read GetFormStyle write SetFormStyle default fsNormal;
  end;

  TUiLibMainForm = class abstract (TUiLibForm)
  strict private
    class var FInstance: TUiLibMainForm;
    class var FOnMainFormCloseQuery: TAutoPoll;
    class var FOnMainFormClose: TAutoEvent;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CloseQuery: Boolean; override;
    class property Instance: TUiLibMainForm read FInstance;
    class function SubscribeCloseQuery(Callback: TPollCallback): IAutoReleasable; static;
    class function SubscribeClose(Callback: TEventCallback): IAutoReleasable; static;
  end;

  TUiLibChildFormMode = (
    cfmNormal,      // No taskbar; overlaps the owner
    cfmApplication, // No taskbar; side-by-side with the owner; use with modal
    cfmDesktop      // Visible on taskbar; side-by-side with the owner
  );

  TUiLibChildForm = class abstract (TUiLibForm)
  strict private
    FChildMode: TUiLibChildFormMode;
    FMainFormCloseQuerySub, FMainFormCloseSub: IAutoReleasable;
  strict protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DoCreate; override;
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent; Mode: TUiLibChildFormMode); reintroduce;
    property ChildMode: TUiLibChildFormMode read FChildMode;
    class procedure CreateAndShow(ShowOnTaskbar: Boolean = True);
  end;

function IsWindowTopmost(Handle: HWND): Boolean;

implementation

uses
  Vcl.Menus;

function IsWindowTopmost;
begin
  Result := BitTest(GetWindowLong(Handle, GWL_EXSTYLE) and WS_EX_TOPMOST);
end;

function DispatchShortCut(const Owner: TComponent; ShortCut: TShortCut): Boolean;
var
  i: Integer;
  Component: TComponent;
begin
  Result := False;

  // Dispatch to children until one marks the event as handled
  for i := 0 to Pred(Owner.ComponentCount) do
  begin
    Component := Owner.Components[i];

    if Component is TUiLibCustomShortCut then
      Result := TUiLibCustomShortCut(Component).Invoke(ShortCut)
    else if not (Component is TCustomForm) and
      (not (Component is TControl) or
      (TControl(Component).Enabled and TControl(Component).Visible)) then
      Result := DispatchShortCut(Component, ShortCut);

    if Result then
      Break;
  end;
end;

{ TUiLibForm }

procedure TUiLibForm.DoClose;
begin
  Action := caFree;
  inherited;
end;

procedure TUiLibForm.DoCreate;
var
  SystemMenu: HMENU;
begin
  inherited;

  // Add an item to toggle stay-on-top from the system menu
  if FormStyle in [fsNormal, fsStayOnTop] then
  begin
    SystemMenu := GetSystemMenu(Handle, False);
    InsertMenu(SystemMenu, 0, MF_STRING, idStayOnTop, 'Stay-On-&Top');
    InsertMenu(SystemMenu, 0, MF_STRING, idPersistStayOnTop,
      '&Persist Stay-On-Top');
  end;
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

function TUiLibForm.GetFormStyle;
begin
  Result := inherited FormStyle;
end;

function TUiLibForm.IsShortCut;
var
  ShortCut: TShortCut;
begin
  Result := inherited;

  if not Vcl.Menus.IsAltGRPressed then
  begin
    ShortCut := Vcl.Menus.ShortCut(Message.CharCode,
      KeyDataToShiftState(Message.KeyData));

    Result := DispatchShortCut(Self, ShortCut) or Result;

    // Support closing on an unhandled escape shortcut
    if (ShortCut = VK_ESCAPE) and FCloseOnEscape and not Result and Active then
    begin
      Result := True;
      Close;
    end;
  end;
end;

procedure TUiLibForm.SetFormStyle;
var
  PreviousPersist: Boolean;
begin
  // Temporarily suppress the logic that prevents stay-on-top from changing
  PreviousPersist := FPersistStayOnTop;
  FPersistStayOnTop := False;
  inherited FormStyle := Value;
  FPersistStayOnTop := PreviousPersist;
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
  begin
    CheckMenuItem(Message.MenuPopup, idStayOnTop, STATE[IsWindowTopmost(Handle)]);
    CheckMenuItem(Message.MenuPopup, idPersistStayOnTop, STATE[FPersistStayOnTop]);
  end;

  inherited;
end;

procedure TUiLibForm.WMSysCommand;
begin
  // Toggle the stay-on-top state from the menu
  if Message.CmdType = idStayOnTop then
    case FormStyle of
      fsNormal:    FormStyle := fsStayOnTop;
      fsStayOnTop: FormStyle := fsNormal;
    end
  else if Message.CmdType = idPersistStayOnTop then
    FPersistStayOnTop := not FPersistStayOnTop
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

procedure TUiLibForm.WMWindowPosChanging;
begin
  // Overwrite requests that change the topmost position if asked to persist it
  if FPersistStayOnTop and not BitTest(Message.WindowPos.flags and
    SWP_NOZORDER) then
  begin
    if IsWindowTopmost(Handle) then
      Message.WindowPos.hwndInsertAfter := HWND_TOPMOST
    else
      Message.WindowPos.hwndInsertAfter := HWND_NOTOPMOST;
  end;

  inherited;
end;

{ TUiLibMainForm }

function TUiLibMainForm.CloseQuery;
begin
  Result := inherited;

  if Result then
  begin
    Result := FOnMainFormCloseQuery.Poll;

    if Result then
      FOnMainFormClose.Invoke;
  end;
end;

constructor TUiLibMainForm.Create;
begin
  inherited Create(AOwner);

  if Assigned(FInstance) then
    raise EInvalidOperation.Create('Attempted to create multiple main forms.');

  FInstance := Self;
end;

destructor TUiLibMainForm.Destroy;
begin
  FInstance := nil;
  inherited;
end;

class function TUiLibMainForm.SubscribeClose;
begin
  Result := FOnMainFormClose.Subscribe(Callback);
end;

class function TUiLibMainForm.SubscribeCloseQuery;
begin
  Result := FOnMainFormCloseQuery.Subscribe(Callback);
end;

{ TUiLibChildForm }

constructor TUiLibChildForm.Create;
begin
  FChildMode := Mode;
  inherited Create(AOwner);

  if FChildMode <> cfmDesktop then
    BorderIcons := BorderIcons - [biMinimize];
end;

class procedure TUiLibChildForm.CreateAndShow;
const
  Mode: array [Boolean] of TUiLibChildFormMode = (cfmApplication, cfmDesktop);
begin
  TUiLibChildForm(NewInstance).Create(nil, Mode[ShowOnTaskbar <> False]).Show;
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
  FMainFormCloseQuerySub := TUiLibMainForm.SubscribeCloseQuery(CloseQuery);
  FMainFormCloseSub := TUiLibMainForm.SubscribeClose(Close);
end;

procedure TUiLibChildForm.DoShow;
begin
  // Our parent class makes us inherit stay-on-top from the owner
  inherited;

  // If there is no owner, inherit the style from the main form
  if not Assigned(Owner) and Assigned(TUiLibMainForm.Instance) and
    (TUiLibMainForm.Instance.FormStyle = fsStayOnTop) and (FormStyle = fsNormal) then
    FormStyle := fsStayOnTop;
end;

end.
