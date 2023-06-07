unit NtUiFrame.AppContainers;

{
  This module provides a frame for showing a list of AppContainer profiles.
}

interface

uses
  Vcl.Controls, System.Classes, Vcl.Forms, VirtualTrees, VirtualTreesEx,
  DevirtualizedTree, NtUiFrame.Search, NtUtils, NtUiCommon.Interfaces,
  NtUiBackend.AppContainers;

type
  IAppContainerNode = NtUiBackend.AppContainers.IAppContainerNode;

  TAppContainersFrame = class (TFrame, IHasSearch, ICanConsumeEscape,
    IGetFocusedNode, IOnNodeSelection, IHasDefaultCaption)
  published
    SearchBox: TSearchFrame;
    Tree: TDevirtualizedTree;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    property BackendImpl: TTreeNodeInterfaceProvider read Backend implements IGetFocusedNode, IOnNodeSelection;
    property SearchImpl: TSearchFrame read SearchBox implements IHasSearch, ICanConsumeEscape;
    function DefaultCaption: String;
  protected
    procedure Loaded; override;
  public
    procedure LoadForUser(const User: ISid);
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$R *.dfm}

{ TAppContainersFrame }

function TAppContainersFrame.DefaultCaption;
begin
  Result := 'Select AppContainer Profile...'
end;

procedure TAppContainersFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree, [teSelectionChange]);
  BackendRef := Backend; // Make an owning reference
end;

procedure TAppContainersFrame.LoadForUser;
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

end.
