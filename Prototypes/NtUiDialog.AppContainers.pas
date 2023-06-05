unit NtUiDialog.AppContainers;

{
  This module provides a dialog for viewing and selecting AppContainer profiles.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, NtUtils,
  NtUiFrame.AppContainers, UI.Prototypes.Forms, NtUtils.Security.AppContainer;

type
  TAppContainersForm = class(TChildForm)
    btnSelect: TButton;
    btnClose: TButton;
    lblUsers: TLabel;
    tbxUser: TEdit;
    AppContainersFrame: TAppContainersFrame;
    procedure FrameSelectionChanged(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
  private
    FUser: ISid;
  public
    procedure LoadForUser(const User: ISid);
    class function Pick(AOwner: TComponent; const User: ISid): TAppContainerInfo; static;
  end;

implementation

uses
  DelphiUiLib.Reflection, NtUiCommon.Interfaces, NtUiBackend.AppContainers;

{$R *.dfm}

{ TAppContainersForm }

procedure TAppContainersForm.btnCloseClick;
begin
  Close;
end;

procedure TAppContainersForm.FormCreate;
begin
  AppContainersFrame.OnSelectionChanged := FrameSelectionChanged;
end;

procedure TAppContainersForm.FormKeyDown;
begin
  if (Shift = [ssCtrl]) and (Key = Ord('F')) then
    IHasSearch(AppContainersFrame).SetSearchFocus

  else if (Key = VK_ESCAPE) and
    not ICanConsumeEscape(AppContainersFrame).ConsumesEscape then
  begin
    btnClose.Click;
    Key := 0;
  end;
end;

procedure TAppContainersForm.FrameSelectionChanged;
begin
  btnSelect.Enabled := (AppContainersFrame.SelectedCount = 1) and
    Assigned(AppContainersFrame.FocusedItem);
end;

procedure TAppContainersForm.LoadForUser;
var
  UserRepresentation: TRepresentation;
  Status: TNtxStatus;
  Parents, Children: TArray<IAppContainerNode>;
  Parent, Child: IAppContainerNode;
begin
  FUser := User;
  UserRepresentation := TType.Represent(User);
  tbxUser.Text := UserRepresentation.Text;
  tbxUser.Hint := UserRepresentation.Hint;

  AppContainersFrame.BeginUpdateAuto;
  AppContainersFrame.ClearItems;

  // Enumerate parent AppContainers
  Status := UiLibEnumerateAppContainers(Parents, User);
  AppContainersFrame.SetNoItemsStatus(Status);

  if not Status.IsSuccess then
    Exit;

  for Parent in Parents do
  begin
    AppContainersFrame.AddItem(Parent);

    // Enumerate child AppContainers
    if UiLibEnumerateAppContainers(Children, User, Parent.Info.Sid).IsSuccess then
      for Child in Children do
        AppContainersFrame.AddItem(Child, Parent);
  end;
end;

class function TAppContainersForm.Pick;
var
  Node: IAppContainerNode;
begin
  with TAppContainersForm.CreateChild(AOwner, cfmNormal) do
  begin
    LoadForUser(User);
    ShowModal;

    Node := AppContainersFrame.FocusedItem;

    if not Assigned(Node) then
      Abort;

    Result := Node.Info;
  end;
end;

end.
