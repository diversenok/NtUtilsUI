unit NtUiFrame.Acl;

{
  The module provides a frame for viewing/modifying Access Control Lists.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.VirtualTreeEx, NtUtilsUI.DevirtualizedTree, NtUtils, Vcl.StdCtrls,
  NtUiFrame, Ntapi.WinNt, Vcl.Menus, Vcl.ExtCtrls, NtUiFrame.Search,
  NtUiCommon.Interfaces, NtUtils.Security.Acl, NtUtilsUI, NtUtilsUI.StdCtrls;

type
  TAclFrame = class(TBaseFrame, ICanConsumeEscape, ICanShowEmptyMessage)
    Tree: TDevirtualizedTree;
    btnUp: TUiLibButton;
    btnDown: TUiLibButton;
    btnCanonicalize: TUiLibButton;
    btnAdd: TUiLibButton;
    btnDelete: TUiLibButton;
    PopupMenu: TPopupMenu;
    cmEdit: TMenuItem;
    cmDelete: TMenuItem;
    cmUp: TMenuItem;
    cmDown: TMenuItem;
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
    FAddShortCut: TUiLibShortCut;
    FEditShortCut: TUiLibShortCut;
    procedure AclChanged;
    function GetAces: TArray<TAceData>;
    property SearchImpl: TSearchFrame read Search implements ICanConsumeEscape;
    procedure OnAddShortCut(Sender: TUiLibShortCut; var Handled: Boolean);
    procedure OnEditShortCut(Sender: TUiLibShortCut; var Handled: Boolean);
  protected
    procedure LoadedOnce; override;
  public
    constructor Create(AOwner: TComponent); override;
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
  NtUiBackend.Acl, NtUiCommon.Helpers, Resources.Icon.Add,
  Resources.Icon.Delete, Resources.Icon.Down, Resources.Icon.Up,
  Resources.Icon.Verify, NtUiCommon.Prototypes;

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

procedure TAclFrame.btnCanonicalizeClick;
begin
  UiLibCanonicalizeAcl(Tree);
  AclChanged;
end;

procedure TAclFrame.btnDeleteClick;
begin
  Tree.BeginUpdateAuto;
  Tree.DeleteSelectedNodesEx(True);
  AclChanged;
end;

procedure TAclFrame.btnDownClick;
begin
  Tree.MoveSelectedNodesDown;
  AclChanged;
end;

procedure TAclFrame.btnUpClick;
begin
  Tree.MoveSelectedNodesUp;
  AclChanged;
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

constructor TAclFrame.Create;
begin
  inherited;

  FAddShortCut := TUiLibShortCut.Create(Self);
  FAddShortCut.ShortCut := scCtrl or Ord('N');
  FAddShortCut.OnExecute := OnAddShortCut;

  FEditShortCut := TUiLibShortCut.Create(Self);
  FEditShortCut.ShortCut := scCtrl or Ord('E');
  FEditShortCut.OnExecute := OnEditShortCut;
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
  btnAdd.Enabled := Assigned(NtUiLibCreateAce);
  Search.AttachToTree(Tree);
end;

procedure TAclFrame.OnAddShortCut;
begin
  if CanFocus then
  begin
    btnAddClick(Sender);
    Handled := True;
  end;
end;

procedure TAclFrame.OnEditShortCut;
begin
  if CanFocus then
  begin
    cmEditClick(Sender);
    Handled := True;
  end;
end;

procedure TAclFrame.SelectionChanged;
begin
  btnUp.Enabled := Tree.CanMoveSelectedNodesUp;
  btnDelete.Enabled := Tree.SelectedCount > 0;
  btnDown.Enabled := Tree.CanMoveSelectedNodesDown;
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
