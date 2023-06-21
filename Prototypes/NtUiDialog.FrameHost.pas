unit NtUiDialog.FrameHost;

{
  This module provides a dialog for hosting frames.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, DevirtualizedTree, UI.Prototypes.Forms;

type
  TFrameInitializer = reference to function (AOwner: TForm): TFrame;

  TFrameHostDialog = class(TChildForm)
    btnClose: TButton;
    btnSelect: TButton;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCloseClick(Sender: TObject);
    procedure DefaultActionChosen(const Node: INodeProvider);
  private
    FFrame: TFrame;
    FFrameRef: IUnknown;
    procedure FrameSelectionChanged(Sender: TObject);
  protected
    procedure AddFrame(Frame: TFrame; AllowSelection: Boolean);
  public
    function GetResult: INodeProvider;
    class function Pick(AOwner: TComponent; Initializer: TFrameInitializer): INodeProvider; static;
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
  SelectionObserver: IOnNodeSelection;
  DefaultCaption: IHasDefaultCaption;
  DefaultAction: INodeDefaultAction;
  BottomMargin, OtherMargin: Integer;
begin
  if not Assigned(Frame) then
    Exit;

  FFrame := Frame;
  FFrameRef := IUnknown(FFrame);

  if AllowSelection then
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
  btnClose.Visible := AllowSelection;
  btnSelect.Visible := AllowSelection;

  if FFrameRef.QueryInterface(IHasDefaultCaption, DefaultCaption).IsSuccess then
    Caption := DefaultCaption.DefaultCaption
  else
    Caption := FFrame.ClassName;

  if AllowSelection then
  begin
    // Subscribe to selection changes
    if FFrameRef.QueryInterface(IOnNodeSelection,
      SelectionObserver).IsSuccess then
    begin
      SelectionObserver.OnSelection := FrameSelectionChanged;
      FrameSelectionChanged(Self);
    end;

    // Set selection as default action
    if FFrameRef.QueryInterface(INodeDefaultAction,
      DefaultAction).IsSuccess then
    begin
      DefaultAction.MainActionCaption := 'Select';
      DefaultAction.OnMainAction := DefaultActionChosen;
    end;
  end;
end;

procedure TFrameHostDialog.btnCloseClick;
begin
  Close;
end;

procedure TFrameHostDialog.DefaultActionChosen;
begin
  ModalResult := mrOk;
end;

class procedure TFrameHostDialog.Display;
var
  Form: TFrameHostDialog;
begin
  Form := TFrameHostDialog.CreateChild(nil, cfmDesktop);

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
  Search: IHasSearch;
  Consumer: ICanConsumeEscape;
begin
  if (Shift = [ssCtrl]) and (Key = Ord('F')) and
    Assigned(FFrameRef) and FFrameRef.QueryInterface(IHasSearch,
    Search).IsSuccess then
    Search.SetSearchFocus

  else if (Key = VK_ESCAPE) and (not Assigned(FFrameRef) or not
    FFrameRef.QueryInterface(ICanConsumeEscape, Consumer).IsSuccess or
    not Consumer.ConsumesEscape) then
  begin
    btnClose.Click;
    Key := 0;
  end;
end;

procedure TFrameHostDialog.FrameSelectionChanged;
var
  FocusedNodeInfo: IGetFocusedNode;
begin
  btnSelect.Enabled := Assigned(FFrameRef) and FFrameRef.QueryInterface(
    IGetFocusedNode, FocusedNodeInfo).IsSuccess and
    Assigned(FocusedNodeInfo.FocusedNode);
end;

function TFrameHostDialog.GetResult;
var
  FocusedNodeInfo: IGetFocusedNode;
begin
  if not Assigned(FFrameRef) or not FFrameRef.QueryInterface(
    IGetFocusedNode, FocusedNodeInfo).IsSuccess then
    Exit(nil);

  Result := FocusedNodeInfo.FocusedNode;
end;

class function TFrameHostDialog.Pick;
var
  Form: TFrameHostDialog;
begin
  Form := TFrameHostDialog.CreateChild(AOwner, cfmApplication);

  try
    Form.AddFrame(Initializer(Form), True);
  except
    Form.Free;
    raise;
  end;

  Form.ShowModal;
  Result := Form.GetResult;

  if not Assigned(Result) then
    Abort;
end;

initialization
  NtUiLibHostFrameShow := TFrameHostDialog.Display;
  NtUiLibHostFramePick := TFrameHostDialog.Pick;
end.
