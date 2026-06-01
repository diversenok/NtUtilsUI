unit NtUiFrame.AppContainer.List;

{
  This module provides a frame for showing a list of AppContainer profiles.
}

interface

uses
  Vcl.Controls, System.Classes, Vcl.Forms, VirtualTrees,
  NtUtilsUI.Tree, NtUtils,
  NtUiCommon.Interfaces, NtUiBackend.AppContainers, Vcl.Menus,
  NtUtilsUI, NtUtilsUI.Base, NtUtilsUI.Tree.Search;

type
  [DefaultCaption('AppContainer Profiles')]
  TAppContainerListFrame = class (TFrame, IModalResult<IAppContainerNode>,
    IModalResultControl)
    SearchBox: TUiLibTreeSearchBox;
    Tree: TUiLibTree;
    PopupMenu: TPopupMenu;
    cmInspect: TMenuItem;
    procedure cmInspectClick(Sender: TObject);
    procedure TreeMainAction(Node: INodeProvider);
    procedure TreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure PopupMenuPopup(Sender: TObject);
  private
    FOnModalComplete: TNotifyEvent;
    FOnModalResultAvailabilityChange: TOnModalResultAvailabilityChange;
    function GetModalResult: IAppContainerNode;
    function GetModalResultType: Pointer;
    procedure SetOnModalResultAvailabilityChange(Event: TOnModalResultAvailabilityChange);
    procedure SetOnModalComplete(Event: TNotifyEvent);
  protected
    procedure Loaded; override;
  public
    procedure LoadForUser(const User: ISid);
  end;

implementation

uses
  NtUtils.Errors, NtUiCommon.Prototypes, System.SysUtils, Winapi.Windows,
  NtUiLib.Errors, NtUtilsUI.Components;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

{ TAppContainersFrame }

procedure TAppContainerListFrame.cmInspectClick(Sender: TObject);
var
  Node: PVirtualNode;
  AppContainerNode: IAppContainerNode;
begin
  if not Assigned(NtUiLibShowAppContainer) then
    Exit;

  Node := Tree.HighlightedNode;

  if Node.TryGetProvider(IAppContainerNode, AppContainerNode) then
    NtUiLibShowAppContainer(AppContainerNode.Info);
end;

function TAppContainerListFrame.GetModalResult;
begin
  Result := Tree.HighlightedNode.Provider as IAppContainerNode;
end;

function TAppContainerListFrame.GetModalResultType;
begin
  Result := TypeInfo(IAppContainerNode);
end;

procedure TAppContainerListFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);

  if Assigned(NtUiLibShowAppContainer) then
    Tree.OnMainAction := TreeMainAction;
end;

procedure TAppContainerListFrame.LoadForUser;
var
  Parents, Children: TArray<IAppContainerNode>;
  Parent, Child: IAppContainerNode;
  Status: TNtxStatus;
begin
  Tree.BeginUpdateAuto;
  Tree.Clear;

  // Enumerate parent AppContainers
  Status := UiLibEnumerateAppContainers(Parents, User);

  if Status.IsSuccess then
    Tree.EmptyListMessage := 'No items to display'
  else
    Tree.EmptyListMessage := 'Unable to query:'#$D#$A + Status.ToString;

  if not Status.IsSuccess then
    Exit;

  for Parent in Parents do
  begin
    Tree.AddChild(Parent);

    // Enumerate child AppContainers
    if UiLibEnumerateAppContainers(Children, User, Parent.Info.Sid).IsSuccess then
      for Child in Children do
        Tree.AddChild(Child, Parent);
  end;
end;

procedure TAppContainerListFrame.PopupMenuPopup;
begin
  cmInspect.Visible := Assigned(Tree.HighlightedNode);
end;

procedure TAppContainerListFrame.SetOnModalComplete;
begin
  FOnModalComplete := Event;
  Tree.OnMainAction := TreeMainAction;
  Tree.MainActionMenuText := 'Select';

  // Demote the inspect menu to a supplimentary Ctrl+Enter
  if Assigned(NtUiLibShowAppContainer) and Assigned(Event) then
    Tree.PopupMenu := PopupMenu;
end;

procedure TAppContainerListFrame.SetOnModalResultAvailabilityChange;
begin
  FOnModalResultAvailabilityChange := Event;
  TreeChange(nil, nil);
end;

procedure TAppContainerListFrame.TreeChange;
begin
  if Assigned(FOnModalResultAvailabilityChange) then
    FOnModalResultAvailabilityChange(Assigned(Tree.HighlightedNode));
end;

procedure TAppContainerListFrame.TreeMainAction;
begin
  if Assigned(FOnModalComplete) then
    FOnModalComplete(Self)
  else if Assigned(NtUiLibShowAppContainer) then
    cmInspectClick(Self);
end;

{ Integration }

function Initializer(const User: ISid): TWinControlFactory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      Frame: TAppContainerListFrame absolute Result;
    begin
      Frame := TAppContainerListFrame.Create(AOwner);
      try
        Frame.LoadForUser(User);
      except
        Frame.Free;
        raise;
      end;
    end;
end;

procedure NtUiLibShowAppContainers(
  const User: ISid
);
begin
  UiLibHost.Show(Initializer(User));
end;

function NtUiLibSelectAppContainer(
  Owner: TComponent;
  const User: ISid
): TRtlxAppContainerInfo;
var
  ProfileNode: IAppContainerNode;
begin
  Profilenode := UiLibHost.Pick<IAppContainerNode>(Owner, Initializer(User));
  Result := ProfileNode.Info;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowAppContainers := NtUiLibShowAppContainers;
  NtUiCommon.Prototypes.NtUiLibSelectAppContainer := NtUiLibSelectAppContainer;
end.
