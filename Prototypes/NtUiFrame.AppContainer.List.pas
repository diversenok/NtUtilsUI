unit NtUiFrame.AppContainer.List;

{
  This module provides a frame for showing a list of AppContainer profiles.
}

interface

uses
  Vcl.Controls, System.Classes, Vcl.Forms, VirtualTrees, VirtualTreesEx,
  DevirtualizedTree, NtUiFrame.Search, NtUtils, NtUiCommon.Interfaces,
  NtUiBackend.AppContainers;

type
  TAppContainerListFrame = class (TFrame, IHasSearch, ICanConsumeEscape,
    IGetFocusedNode, IOnNodeSelection, IHasDefaultCaption, INodeDefaultAction)
  published
    SearchBox: TSearchFrame;
    Tree: TDevirtualizedTree;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    property BackendImpl: TTreeNodeInterfaceProvider read Backend implements IGetFocusedNode, IOnNodeSelection, INodeDefaultAction;
    property SearchImpl: TSearchFrame read SearchBox implements IHasSearch, ICanConsumeEscape;
    function DefaultCaption: String;
  protected
    procedure Loaded; override;
  public
    procedure LoadForUser(const User: ISid);
  end;

implementation

uses
  NtUiCommon.Prototypes, System.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

{ TAppContainersFrame }

function TAppContainerListFrame.DefaultCaption;
begin
  Result := 'AppContainer Profiles'
end;

procedure TAppContainerListFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree, [teSelectionChange]);
  BackendRef := Backend; // Make an owning reference
end;

procedure TAppContainerListFrame.LoadForUser;
var
  Parents, Children: TArray<IAppContainerNode>;
  Parent, Child: IAppContainerNode;
  Status: TNtxStatus;
begin
  Backend.BeginUpdateAuto;
  Backend.ClearItems;

  // Enumerate parent AppContainers
  Status := UiLibEnumerateAppContainers(Parents, User);
  Backend.SetStatus(Status);

  if not Status.IsSuccess then
    Exit;

  for Parent in Parents do
  begin
    Backend.AddItem(Parent);

    // Enumerate child AppContainers
    if UiLibEnumerateAppContainers(Children, User, Parent.Info.Sid).IsSuccess then
      for Child in Children do
        Backend.AddItem(Child, Parent);
  end;
end;

{ Integration }

function Initializer(const User: ISid): TFrameInitializer;
begin
  Result := function (AOwner: TForm): TFrame
    var
      UserFrame: TAppContainerListFrame absolute Result;
    begin
      UserFrame := TAppContainerListFrame.Create(AOwner);
      try
        UserFrame.LoadForUser(User);
      except
        UserFrame.Free;
        raise;
      end;
    end;
end;

procedure NtUiLibShowAppContainers(
  const User: ISid
);
begin
  if not Assigned(NtUiLibHostFrameShow) then
    raise ENotSupportedException.Create('Frame host not available');

  NtUiLibHostFrameShow(Initializer(User));
end;

function NtUiLibSelectAppContainer(
  Owner: TComponent;
  const User: ISid
): TAppContainerInfo;
var
  ProfileNode: IAppContainerNode;
begin
  if not Assigned(NtUiLibHostFramePick) then
    raise ENotSupportedException.Create('Frame host not available');

  Profilenode := NtUiLibHostFramePick(Owner, Initializer(User)) as IAppContainerNode;
  Result := ProfileNode.Info;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowAppContainers := NtUiLibShowAppContainers;
  NtUiCommon.Prototypes.NtUiLibSelectAppContainer := NtUiLibSelectAppContainer;
end.
