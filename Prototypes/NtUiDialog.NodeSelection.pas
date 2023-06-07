unit NtUiDialog.NodeSelection;

{
  This module provides a modal dialog for selecting an node item.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, DevirtualizedTree, UI.Prototypes.Forms;

type
  TFrameInitializer = reference to function (AOwner: TForm): TFrame;

  TNodeSelectionDialog = class(TChildForm)
    btnClose: TButton;
    btnSelect: TButton;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCloseClick(Sender: TObject);
  private
    FFrame: TFrame;
    FFrameRef: IUnknown;
    procedure FrameSelectionChanged(Sender: TObject);
  public
    procedure AddFrame(Frame: TFrame);
    function GetResult: INodeProvider;
    class function Pick(AOwner: TComponent; const Initializer: TFrameInitializer): INodeProvider; static;
  end;

implementation

uses
  Winapi.Windows, NtUiCommon.Interfaces, NtUtils.Errors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

procedure TNodeSelectionDialog.AddFrame;
var
  SelectionObserver: IOnNodeSelection;
  DefaultCaption: IHasDefaultCaption;
begin
  if not Assigned(Frame) then
    Exit;

  FFrame := Frame;
  FFrameRef := IUnknown(FFrame);

  ClientWidth := FFrame.Width + 6;
  ClientHeight := FFrame.Height + 36;
  FFrame.Parent := Self;
  FFrame.AlignWithMargins := True;
  FFrame.Margins.SetBounds(3, 3, 3, 33);
  FFrame.Align := alClient;

  if FFrameRef.QueryInterface(IHasDefaultCaption, DefaultCaption).IsSuccess then
    Caption := DefaultCaption.DefaultCaption;

  if FFrameRef.QueryInterface(IOnNodeSelection, SelectionObserver).IsSuccess then
  begin
    SelectionObserver.OnSelection := FrameSelectionChanged;
    FrameSelectionChanged(Self);
  end;
end;

procedure TNodeSelectionDialog.btnCloseClick;
begin
  Close;
end;

procedure TNodeSelectionDialog.FormKeyDown;
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

procedure TNodeSelectionDialog.FrameSelectionChanged;
var
  FocusedNodeInfo: IGetFocusedNode;
begin
  btnSelect.Enabled := Assigned(FFrameRef) and FFrameRef.QueryInterface(
    IGetFocusedNode, FocusedNodeInfo).IsSuccess and
    Assigned(FocusedNodeInfo.FocusedNode);
end;

function TNodeSelectionDialog.GetResult;
var
  FocusedNodeInfo: IGetFocusedNode;
begin
  if not Assigned(FFrameRef) or not FFrameRef.QueryInterface(
    IGetFocusedNode, FocusedNodeInfo).IsSuccess then
    Exit(nil);

  Result := FocusedNodeInfo.FocusedNode;
end;

class function TNodeSelectionDialog.Pick;
var
  Form: TNodeSelectionDialog;
begin
  Form := TNodeSelectionDialog.CreateChild(AOwner, cfmNormal);

  try
    Form.AddFrame(Initializer(Form));
  except
    Form.Free;
    raise;
  end;

  Form.ShowModal;
  Result := Form.GetResult;

  if not Assigned(Result) then
    Abort;
end;

end.
