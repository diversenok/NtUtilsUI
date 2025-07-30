unit NtUiDialog.FrameHost;

{
  This module provides a dialog for hosting frames.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, DevirtualizedTree, NtUiCommon.Forms;

type
  TFrameInitializer = reference to function (AOwner: TComponent): TFrame;

  TFrameHostDialog = class(TChildForm)
    btnClose: TButton;
    btnSelect: TButton;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCloseClick(Sender: TObject);
    procedure DefaultActionChosen(const Node: INodeProvider);
    procedure btnSelectClick(Sender: TObject);
  private
    FFrame: TFrame;
    FFrameRef: IUnknown;
    FFrameModalResult: IInterface;
    procedure FrameModalResultChanged(Sender: TObject);
  protected
    procedure AddFrame(Frame: TFrame; AllowModal: Boolean);
  public
    function PickModal: IInterface;
    class function Pick(AOwner: TComponent; Initializer: TFrameInitializer): IInterface; static;
    class procedure Display(Initializer: TFrameInitializer); static;
  end;

implementation

uses
  Winapi.Windows, NtUiCommon.Prototypes, NtUiCommon.Interfaces, NtUtils.Errors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

procedure TFrameHostDialog.AddFrame;
const
  SMALL_MARGIN = 3;
  BIG_MARGIN = 31;
var
  ModalResultObservation: IHasModalResultObservation;
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

  if AllowModal then
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
  btnClose.Visible := AllowModal;
  btnSelect.Visible := AllowModal;

  if FFrameRef.QueryInterface(IHasDefaultCaption, DefaultCaption).IsSuccess then
    Caption := DefaultCaption.GetDefaultCaption
  else
    Caption := FFrame.ClassName;

  if AllowModal then
  begin
    // Subscribe to modal result changes
    if FFrameRef.QueryInterface(IHasModalResultObservation,
      ModalResultObservation).IsSuccess then
    begin
      ModalResultObservation.OnModalResultChanged := FrameModalResultChanged;
      FrameModalResultChanged(Self);
    end;

    // Adjust button captions
    if FFrameRef.QueryInterface(IHasModalButtonCaptions,
      ButtonCaptions).IsSuccess then
    begin
      btnSelect.Caption := ButtonCaptions.ConfirmationCaption;
      btnClose.Caption := ButtonCaptions.CancellationCaption;
    end;

    // Set the default action on the frame
    if FFrameRef.QueryInterface(IAllowsDefaultNodeAction,
      DefaultAction).IsSuccess then
    begin
      DefaultAction.MainActionCaption := btnSelect.Caption;
      DefaultAction.OnMainAction := DefaultActionChosen;
    end;
  end;

  // Delay-initialize the frame
  if FFrameRef.QueryInterface(IDelayedLoad, DelayedLoad).IsSuccess then
    DelayedLoad.DelayedLoad;
end;

procedure TFrameHostDialog.btnCloseClick;
begin
  Close;
end;

procedure TFrameHostDialog.btnSelectClick;
var
  ModalResultImpl: IHasModalResult;
begin
  // Retrieve the modal result from the frame
  if FFrameRef.QueryInterface(IHasModalResult, ModalResultImpl).IsSuccess then
    FFrameModalResult := ModalResultImpl.ModalResult
  else
    FFrameModalResult := nil;

  // Initiate closing if no exceptions occured
  ModalResult := mrOk;
end;

procedure TFrameHostDialog.DefaultActionChosen;
begin
  FFrameModalResult := Node;
  ModalResult := mrOk;
end;

class procedure TFrameHostDialog.Display;
var
  Form: TFrameHostDialog;
begin
  Form := TFrameHostDialog.Create(nil, cfmDesktop);

  try
    Form.AddFrame(Initializer(Form), False);
  except
    Form.Free;
    raise;
  end;

  Form.Show;
end;

procedure TFrameHostDialog.FormKeyDown;
var
  Consumer: ICanConsumeEscape;
begin
  if (Key = VK_ESCAPE) and (not Assigned(FFrameRef) or not
    FFrameRef.QueryInterface(ICanConsumeEscape, Consumer).IsSuccess or
    not Consumer.ConsumesEscape) then
  begin
    btnClose.Click;
    Key := 0;
  end;
end;

procedure TFrameHostDialog.FrameModalResultChanged;
var
  ModalResultImpl: IHasModalResultObservation;
begin
  if Assigned(FFrameRef) and FFrameRef.QueryInterface(
    IHasModalResultObservation, ModalResultImpl).IsSuccess then
    btnSelect.Enabled := ModalResultImpl.HasModalResult;
end;

class function TFrameHostDialog.Pick;
var
  Form: TFrameHostDialog;
begin
  Form := TFrameHostDialog.Create(AOwner, cfmApplication);

  try
    Form.AddFrame(Initializer(Form), True);
  except
    Form.Free;
    raise;
  end;

  // Show the dialog and free on close
  Result := Form.PickModal;

  if not Assigned(Result) then
    Abort;
end;

function TFrameHostDialog.PickModal;
begin
  ShowModal;

  // Note: the form will be destroyed when it processes the next message.
  // until then, we can access the field.
  Result := FFrameModalResult;
end;

initialization
  NtUiLibHostFrameShow := TFrameHostDialog.Display;
  NtUiLibHostFramePick := TFrameHostDialog.Pick;
end.
