unit NtUiFrame.Sids.WellKnown;

{
  This module provides a frame for displaying the well-known SID enumeration.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.DevirtualizedTree,
  NtUiCommon.Interfaces, NtUiBackend.Sids.WellKnown, NtUtilsUI, NtUtilsUI.Base,
  NtUtilsUI.DevirtualizedTree.Search;

type
  TWellKnownSidsFrame = class(TFrame, IHasDefaultCaption, IDelayedLoad)
    Tree: TDevirtualizedTree;
    SearchBox: TUiLibTreeSearchBox;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
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
  Backend.BeginUpdateAuto;
  Backend.ClearItems;

  for Provider in NtUiLibMakeWellKnownSidNodes do
    Backend.AddItem(Provider);
end;

function TWellKnownSidsFrame.GetDefaultCaption;
begin
  Result := 'Well-known SIDs';
end;

procedure TWellKnownSidsFrame.CreateWnd;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree);
  BackendRef := Backend; // Make an owning reference
end;

end.
