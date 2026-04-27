unit NtUiFrame.Sids.Hierarchy;

{
  This module provides a frame for displaying tree hierarchy of known SIDs.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.Tree,
  NtUiBackend.Sids.Hierarchy, NtUiCommon.Interfaces, NtUtilsUI, NtUtilsUI.Base,
  NtUtilsUI.Tree.Search;

type
  TSidHierarchyFrame = class(TFrame, IHasDefaultCaption, IDelayedLoad)
    Tree: TUiLibTree;
    SearchBox: TUiLibTreeSearchBox;
  private
    function GetDefaultCaption: String;
  protected
    procedure CreateWnd; override;
    procedure DelayedLoad;
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

{ TSidHierarchyFrame }

procedure TSidHierarchyFrame.DelayedLoad;
begin
  NtUiLibAddSidHierarchyNodes(Tree);
end;

function TSidHierarchyFrame.GetDefaultCaption;
begin
  Result := 'SID Hierarchy';
end;

procedure TSidHierarchyFrame.CreateWnd;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
end;

end.
