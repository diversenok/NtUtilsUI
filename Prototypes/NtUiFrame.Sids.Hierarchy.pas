unit NtUiFrame.Sids.Hierarchy;

{
  This module provides a frame for displaying tree hierarchy of known SIDs.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, NtUiBackend.Sids.Hierarchy, NtUiFrame,
  NtUiFrame.Search, NtUiCommon.Interfaces;

type
  TSidHierarchyFrame = class(TBaseFrame, ICanConsumeEscape, IObservesActivation,
    IHasDefaultCaption, IDelayedLoad)
    Tree: TDevirtualizedTree;
    SearchBox: TSearchFrame;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    property SearchImpl: TSearchFrame read SearchBox implements ICanConsumeEscape, IObservesActivation;
    function GetDefaultCaption: String;
  protected
    procedure LoadedOnce; override;
    procedure DelayedLoad;
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

{ TSidHierarchyFrame }

procedure TSidHierarchyFrame.DelayedLoad;
begin
  NtUiLibAddSidHierarchyNodes(Backend);
end;

function TSidHierarchyFrame.GetDefaultCaption;
begin
  Result := 'SID Hierarchy';
end;

procedure TSidHierarchyFrame.LoadedOnce;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree);
  BackendRef := Backend; // Make an owning reference
end;

end.
