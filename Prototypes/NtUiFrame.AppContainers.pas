unit NtUiFrame.AppContainers;

{
  This module provides a frame for showing a list of AppContainer profiles.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, DevirtualizedTree.Provider,
  NtUiFrame.Search, NtUtils, NtUiCommon.Interfaces, NtUiBackend.AppContainers;

type
  IAppContainerCollection = INodeCollection<IAppContainerNode>;
  IEditableAppContainerCollection = IEditableNodeCollection<IAppContainerNode>;

  TAppContainersFrame = class(TFrame, IHasSearch, ICanConsumeEscape,
    ICanShowStatus, IAppContainerCollection, IEditableAppContainerCollection,
    IOnNodeSelection)
  published
    SearchBox: TSearchFrame;
    Tree: TDevirtualizedTree;
  private
    FNoItemsTextImpl: ICanShowStatus;
    FSelectionImpl: IOnNodeSelection;
    FCollectionImpl: IAppContainerCollection;
    FEditableCollectionImpl: IEditableAppContainerCollection;
    property SearchImpl: TSearchFrame read SearchBox implements IHasSearch, ICanConsumeEscape;
    property SelectionImpl: IOnNodeSelection read FSelectionImpl implements IOnNodeSelection;
    property NoItemsTextImpl: ICanShowStatus read FNoItemsTextImpl implements ICanShowStatus;
    property CollectionImpl: IAppContainerCollection read FCollectionImpl implements IAppContainerCollection;
    property EditableCollectionImpl: IEditableAppContainerCollection read FEditableCollectionImpl implements IEditableAppContainerCollection;
  protected
    procedure Loaded; override;
  end;

implementation

{$R *.dfm}

{ TAppContainersFrame }

procedure TAppContainersFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);

  FSelectionImpl := NtUiLibDelegateINodeSelectionCallback(Tree);
  FNoItemsTextImpl := NtUiLibDelegateNoItemsStatus(Tree);

  INodeCollection(FCollectionImpl) :=
    NtUiLibDelegateINodeCollection(Tree, IAppContainerNode);

  IEditableNodeCollection(FEditableCollectionImpl) :=
    NtUiLibDelegateIEditableNodeCollection(Tree, IAppContainerNode);
end;


end.
