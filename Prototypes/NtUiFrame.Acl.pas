unit NtUiFrame.Acl;

{
  The module provides a frame for viewing/modifying Access Control Lists.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, NtUtils, Vcl.StdCtrls, NtUiFrame;

type
  TAclFrame = class(TBaseFrame)
    Tree: TDevirtualizedTree;
    btnUp: TButton;
    btnDown: TButton;
    btnCanonicalize: TButton;
    btnAdd: TButton;
    btnDelete: TButton;
    procedure btnCanonicalizeClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure SelectionChanged(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
  private
    FMaskType: Pointer;
    procedure AclChanged;
    procedure btnUpIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure btnAddIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure btnCanonicalizeIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure btnDeleteIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure btnDownIconChanged(ImageList: TImageList; ImageIndex: Integer);
  protected
    procedure LoadedOnce; override;
  public
    procedure LoadAcl([opt] const Acl: IAcl; MaskType: Pointer);
  end;

implementation

uses
  NtUiBackend.Acl, UI.Helper, Resources.Icon.Add, Resources.Icon.Delete,
  Resources.Icon.Down, Resources.Icon.Up, Resources.Icon.Verify;

{$R *.dfm}

{ TAclFrame }

procedure TAclFrame.AclChanged;
begin
  btnCanonicalize.Enabled := not UiLibIsCanonicalAcl(Tree);
  SelectionChanged(Tree, nil);
end;

procedure TAclFrame.btnAddIconChanged;
begin
  btnAdd.Images := ImageList;
  btnAdd.ImageIndex := ImageIndex;
end;

procedure TAclFrame.btnCanonicalizeClick;
begin
  UiLibCanonicalizeAcl(Tree);
  AclChanged;
end;

procedure TAclFrame.btnCanonicalizeIconChanged;
begin
  btnCanonicalize.Images := ImageList;
  btnCanonicalize.ImageIndex := ImageIndex;
end;

procedure TAclFrame.btnDeleteClick;
begin
  Tree.BeginUpdateAuto;
  Tree.DeleteSelectedNodes;
  AclChanged;
end;

procedure TAclFrame.btnDeleteIconChanged;
begin
  btnDelete.Images := ImageList;
  btnDelete.ImageIndex := ImageIndex;
end;

procedure TAclFrame.btnDownClick;
begin
  Tree.MoveSelectedNodesDown;
  AclChanged;
end;

procedure TAclFrame.btnDownIconChanged;
begin
  btnDown.Images := ImageList;
  btnDown.ImageIndex := ImageIndex;
end;

procedure TAclFrame.btnUpClick;
begin
  Tree.MoveSelectedNodesUp;
  AclChanged;
end;

procedure TAclFrame.btnUpIconChanged;
begin
  btnUp.Images := ImageList;
  btnUp.ImageIndex := ImageIndex;
end;

procedure TAclFrame.LoadAcl;
begin
  UiLibAddAclNodes(Tree, Acl, MaskType);
  FMaskType := MaskType;
end;

procedure TAclFrame.LoadedOnce;
begin
  inherited;
  RegisterResourceIcon(RESOURSES_ICON_UP, btnUpIconChanged);
  RegisterResourceIcon(RESOURSES_ICON_ADD, btnAddIconChanged);
  RegisterResourceIcon(RESOURSES_ICON_VERIFY, btnCanonicalizeIconChanged);
  RegisterResourceIcon(RESOURSES_ICON_DELETE, btnDeleteIconChanged);
  RegisterResourceIcon(RESOURSES_ICON_DOWN, btnDownIconChanged);
end;

procedure TAclFrame.SelectionChanged;
begin

  btnUp.Enabled := Tree.SelectedCount > 0;
  btnDelete.Enabled := Tree.SelectedCount > 0;
  btnDown.Enabled := Tree.SelectedCount > 0;
end;

end.
