unit NtUiFrame.Sids.WellKnown;

{
  This module provides a frame for displaying the well-known SID enumeration.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.Tree,
  NtUiCommon.Interfaces, NtUiBackend.Sids.WellKnown, NtUtilsUI, NtUtilsUI.Base,
  NtUtilsUI.Tree.Search;

type
  TWellKnownSidsFrame = class(TFrame, IHasDefaultCaption, IDelayedLoad)
    Tree: TUiLibTree;
    SearchBox: TUiLibTreeSearchBox;
  private
    function GetDefaultCaption: String;
  protected
    procedure CreateWnd; override;
    procedure DelayedLoad;
  end;

implementation

{$R *.dfm}

{ TWellKnownSidsFrame }

procedure TWellKnownSidsFrame.DelayedLoad;
var
  Provider: IWellKnownSidNode;
begin
  Tree.BeginUpdateAuto;
  Tree.Clear;

  for Provider in NtUiLibMakeWellKnownSidNodes do
    Tree.AddChild(Provider);
end;

function TWellKnownSidsFrame.GetDefaultCaption;
begin
  Result := 'Well-known SIDs';
end;

procedure TWellKnownSidsFrame.CreateWnd;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
end;

end.
