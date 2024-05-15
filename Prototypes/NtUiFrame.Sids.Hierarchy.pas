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
  TSidHierarchyFrame = class(TFrame, ICanConsumeEscape, IObservesActivation,
    IHasDefaultCaption)
    Tree: TDevirtualizedTree;
    SearchBox: TSearchFrame;
  private
    property SearchImpl: TSearchFrame read SearchBox implements ICanConsumeEscape, IObservesActivation;
    function GetDefaultCaption: String;
  protected
    procedure Loaded; override;
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

{ TSidHierarchyFrame }

function TSidHierarchyFrame.GetDefaultCaption;
begin
  Result := 'SID Hierarchy';
end;

procedure TSidHierarchyFrame.Loaded;
begin
  inherited;
  NtUiLibAddSidHierarchyNodes(Tree);
  SearchBox.AttachToTree(Tree);
end;

end.
