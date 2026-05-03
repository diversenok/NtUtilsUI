unit NtUiDialog.FrameHost;

{
  This module provides a dialog for hosting frames.
}

interface

uses
  System.Classes, Vcl.Controls, Vcl.StdCtrls, NtUtilsUI.Tree, NtUtilsUI.Base,
  NtUtilsUI.Forms, NtUtilsUI.Components.Factories;

type
  TFrameHostDialog = class(TUiLibChildForm)
    btnClose: TButton;
    btnSelect: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure DefaultActionChosen(Node: INodeProvider);
    procedure btnSelectClick(Sender: TObject);
  private
    FFrame: TWinControl;
    [Unsafe] FFrameRef: IUnknown;
    FModalResultCache: IModalResultCache;
    procedure FrameHasModalResultChanged(Sender: TObject);
    procedure AddFrame(Frame: TWinControl; ModalResultCache: IModalResultCache);
  public
    constructor Create(
      AOwner: TComponent;
      ChildMode: TUiLibChildFormMode;
      Factory: TWinControlFactory;
      ModalResultCache: IModalResultCache
    );
    class procedure HostPick(AOwner: TComponent; Factory: TWinControlFactory; ModalResultCache: IModalResultCache); static;
    class procedure HostShow(Factory: TWinControlFactory); static;
  end;

implementation

uses
  NtUiCommon.Interfaces;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

procedure TFrameHostDialog.AddFrame;
const
  SMALL_MARGIN = 3;
  BIG_MARGIN = 31;
var
  ModalResultAvailability: IModalResultAvailability;
  ButtonCaptions: IHasModalButtonCaptions;
  DefaultCaption: IHasDefaultCaption;
  DefaultAction: IAllowsDefaultNodeAction;
  DelayedLoad: IDelayedLoad;
  BottomMargin, OtherMargin: Integer;
begin
  if not Assigned(Frame) then
    Exit;

  FFrame := Frame;
  FFrameRef := IUnknown(FFrame);
  FModalResultCache := ModalResultCache;

  if Assigned(FModalResultCache) then
    BottomMargin := BIG_MARGIN * CurrentPPI div 96
  else
    BottomMargin := SMALL_MARGIN * CurrentPPI div 96;

  OtherMargin := SMALL_MARGIN * CurrentPPI div 96;
  ClientWidth := FFrame.Width + OtherMargin * 2;
  ClientHeight := FFrame.Height + OtherMargin + BottomMargin;
  FFrame.Parent := Self;
  FFrame.AlignWithMargins := True;
  FFrame.Margins.SetBounds(OtherMargin, OtherMargin, OtherMargin, BottomMargin);
  FFrame.Align := alClient;
  FFrame.TabOrder := 0;
  btnClose.Visible := Assigned(FModalResultCache);
  btnSelect.Visible := Assigned(FModalResultCache);

  if FFrameRef.QueryInterface(IHasDefaultCaption, DefaultCaption) = S_OK then
    Caption := DefaultCaption.GetDefaultCaption
  else
    Caption := FFrame.ClassName;

  if Assigned(FModalResultCache) then
  begin
    // Subscribe to modal result availability changes
    if FFrameRef.QueryInterface(IModalResultAvailability,
      ModalResultAvailability) = S_OK then
    begin
      ModalResultAvailability.OnHasModalResultChanged :=
        FrameHasModalResultChanged;
      FrameHasModalResultChanged(Self);
    end;

    // Adjust button captions
    if FFrameRef.QueryInterface(IHasModalButtonCaptions,
      ButtonCaptions) = S_OK then
    begin
      btnSelect.Caption := ButtonCaptions.ConfirmationCaption;
      btnClose.Caption := ButtonCaptions.CancellationCaption;
    end;

    // Set the default action on the frame
    if FFrameRef.QueryInterface(IAllowsDefaultNodeAction,
      DefaultAction) = S_OK then
    begin
      DefaultAction.MainActionCaption := btnSelect.Caption;
      DefaultAction.OnMainAction := DefaultActionChosen;
    end;
  end;

  // Delay-initialize the frame
  if FFrameRef.QueryInterface(IDelayedLoad, DelayedLoad) = S_OK then
    DelayedLoad.DelayedLoad;
end;

procedure TFrameHostDialog.btnCloseClick;
begin
  Close;
end;

procedure TFrameHostDialog.btnSelectClick;
begin
  FModalResultCache.Save(FFrameRef);

  // Initiate closing if no exceptions occured
  ModalResult := mrOk;
end;

constructor TFrameHostDialog.Create;
begin
  inherited Create(AOwner, ChildMode);
  AddFrame(Factory(Self), ModalResultCache);
end;

procedure TFrameHostDialog.DefaultActionChosen;
begin
  FModalResultCache.Save(FFrameRef);
  ModalResult := mrOk;
end;

procedure TFrameHostDialog.FrameHasModalResultChanged;
var
  ModalResultAvailability: IModalResultAvailability;
begin
  if FFrameRef.QueryInterface(IModalResultAvailability,
    ModalResultAvailability) = S_OK then
    btnSelect.Enabled := ModalResultAvailability.HasModalResult;
end;

class procedure TFrameHostDialog.HostPick;
var
  Form: TFrameHostDialog;
begin
  Form := TFrameHostDialog.Create(AOwner, cfmApplication, Factory,
    ModalResultCache);
  Form.ShowModal;
end;

class procedure TFrameHostDialog.HostShow;
var
  Form: TFrameHostDialog;
begin
  Form := TFrameHostDialog.Create(nil, cfmDesktop, Factory, nil);
  Form.Show;
end;

initialization
  UiLibHostShow := TFrameHostDialog.HostShow;
  UiLibHostPick := TFrameHostDialog.HostPick;
end.
