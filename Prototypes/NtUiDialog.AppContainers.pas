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
  NtUtils.Lsa.Sid, UI.Helper, DelphiUiLib.Reflection;

{$R *.dfm}

{ TForm2 }

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
    AppContainersFrame.SearchBox.SetSeacrchFocus

  else if (Key = VK_ESCAPE) and
    not AppContainersFrame.SearchBox.ShouldIgnoreEscape then
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
  Info: TAppContainerInfo;
  ParentSids, ChildSids: TArray<ISid>;
  ParentSid, ChildSid: ISid;
  ParentNode: IAppContainerNode;
begin
  FUser := User;
  UserRepresentation := TType.Represent(User);
  tbxUser.Text := UserRepresentation.Text;
  tbxUser.Hint := UserRepresentation.Hint;

  AppContainersFrame.BeginUpdateAuto;
  AppContainersFrame.ClearItems;

  // Enumerate parent AppContainers
  Status := RtlxEnumerateAppContainerSIDs(ParentSids, nil, User);
  AppContainersFrame.SetNoItemsStatus(Status);

  if not Status.IsSuccess then
    Exit;

  for ParentSid in ParentSids do
  begin
    // Query parent AppContainer
    if not RtlxQueryAppContainer(Info, ParentSid, User).IsSuccess then
    begin
      Info := Default(TAppContainerInfo);
      Info.Sid := ParentSid;
    end;

    // Add parent
    ParentNode := AppContainersFrame.AddItem(Info);

    // Enumerate children
    if RtlxEnumerateAppContainerSIDs(ChildSids, ParentSid, User).IsSuccess then
      for ChildSid in ChildSids do
      begin
        // Query child AppContainer
        if not RtlxQueryAppContainer(Info, ChildSid, User).IsSuccess then
        begin
          Info := Default(TAppContainerInfo);
          Info.Sid := ChildSid;
        end;

        // Add child
        AppContainersFrame.AddItem(Info, ParentNode);
      end;
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
