unit NtUiFrame.Acl;

{
  The module provides a frame for viewing/modifying Access Control Lists.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, NtUtils, Vcl.StdCtrls, NtUiFrame,
  Ntapi.WinNt, Vcl.Menus, System.Actions, Vcl.ActnList, Vcl.ExtCtrls,
  NtUiFrame.Search, NtUiCommon.Interfaces, NtUtils.Security.Acl;

type
  TAclFrame = class(TBaseFrame, ICanConsumeEscape, ICanShowEmptyMessage,
    IObservesActivation)
    Tree: TDevirtualizedTree;
    btnUp: TButton;
    btnDown: TButton;
    btnCanonicalize: TButton;
    btnAdd: TButton;
    btnDelete: TButton;
    PopupMenu: TPopupMenu;
    cmEdit: TMenuItem;
    cmDelete: TMenuItem;
    cmUp: TMenuItem;
    cmDown: TMenuItem;
    ActionList: TActionList;
    alxNew: TAction;
    alxCanonicalize: TAction;
    alxEdit: TAction;
    RightPanel: TPanel;
    Search: TSearchFrame;
    procedure btnCanonicalizeClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure SelectionChanged(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure cmEditClick(Sender: TObject);
    procedure TreeGetPopupMenu(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; const P: TPoint; var AskParent: Boolean;
      var PopupMenu: TPopupMenu);
  private
    FMaskType: Pointer;
    FGenericMapping: TGenericMapping;
    FOnAceChange: TNotifyEvent;
    FDefaultAceType: TAceType;
    procedure AclChanged;
    procedure btnUpIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure btnAddIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure btnCanonicalizeIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure btnDeleteIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure btnDownIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure SetActive(Active: Boolean);
    function GetAces: TArray<TAceData>;
    property SearchImpl: TSearchFrame read Search implements ICanConsumeEscape;
  protected
    procedure LoadedOnce; override;
  public
    procedure SetEmptyMessage(const Value: String);
    procedure LoadAces(
      const Aces: TArray<TAceData>;
      MaskType: Pointer;
      const GenericMapping: TGenericMapping;
      DefaultAceType: TAceType = ACCESS_ALLOWED_ACE_TYPE
    );
    property Aces: TArray<TAceData> read GetAces;
    property OnAceChange: TNotifyEvent read FOnAceChange write FOnAceChange;
  end;

implementation

uses
  NtUiBackend.Acl, UI.Helper, Resources.Icon.Add, Resources.Icon.Delete,
  Resources.Icon.Down, Resources.Icon.Up, Resources.Icon.Verify,
  NtUiCommon.Prototypes;

{$R *.dfm}

{ TAclFrame }

procedure TAclFrame.AclChanged;
begin
  btnCanonicalize.Enabled := not UiLibIsCanonicalAcl(Tree);
  SelectionChanged(Tree, nil);

  if Assigned(FOnAceChange) then
    FOnAceChange(Self);
end;

procedure TAclFrame.btnAddClick;
begin
  if not Assigned(NtUiLibCreateAce) then
    Exit;

  UiLibInsertAceNode(Tree, NtUiLibCreateAce(Self, FMaskType, FGenericMapping,
    FDefaultAceType), FMaskType);
  AclChanged;
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
  Tree.DeleteSelectedNodesEx(True);
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

procedure TAclFrame.cmEditClick;
var
  Node: IAceNode;
begin
  if not Assigned(NtUiLibEditAce) or (Tree.SelectedCount <> 1) or not
    Tree.FocusedNode.TryGetProvider(IAceNode, Node) then
    Exit;

  // Invoke the editor dialog and save the result
  Node.Ace := NtUiLibEditAce(Self, FMaskType, FGenericMapping, Node.Ace);
  UiLibUnhideAceSpecificColumns(Tree, Node.Ace);
  AclChanged;
end;

function TAclFrame.GetAces;
begin
  Result := UiLibCollectAces(Tree);
end;

procedure TAclFrame.LoadAces;
begin
  UiLibLoadAceNodes(Tree, Aces, MaskType);
  FMaskType := MaskType;
  FGenericMapping := GenericMapping;
  FDefaultAceType := DefaultAceType;
  AclChanged;
end;

procedure TAclFrame.LoadedOnce;
begin
  inherited;
  RegisterResourceIcon(RESOURSES_ICON_UP, btnUpIconChanged);
  RegisterResourceIcon(RESOURSES_ICON_ADD, btnAddIconChanged);
  RegisterResourceIcon(RESOURSES_ICON_VERIFY, btnCanonicalizeIconChanged);
  RegisterResourceIcon(RESOURSES_ICON_DELETE, btnDeleteIconChanged);
  RegisterResourceIcon(RESOURSES_ICON_DOWN, btnDownIconChanged);
  btnAdd.Enabled := Assigned(NtUiLibCreateAce);
  Search.AttachToTree(Tree);
end;

procedure TAclFrame.SelectionChanged;
begin
  btnUp.Enabled := Tree.SelectedCount > 0;
  btnDelete.Enabled := Tree.SelectedCount > 0;
  btnDown.Enabled := Tree.SelectedCount > 0;
end;

procedure TAclFrame.SetActive;
begin
  if Active then
    ActionList.State := asNormal
  else
    ActionList.State := asSuspended;

  (Search as IObservesActivation).SetActive(Active);
end;

procedure TAclFrame.SetEmptyMessage;
begin
  Tree.NoItemsText := Value;
end;

procedure TAclFrame.TreeGetPopupMenu;
begin
  cmEdit.Visible := Assigned(NtUiLibEditAce) and (Tree.SelectedCount = 1);
end;

end.
