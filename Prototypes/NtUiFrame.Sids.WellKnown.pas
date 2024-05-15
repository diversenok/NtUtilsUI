unit NtUiFrame.Sids.WellKnown;

{
  This module provides a frame for displaying the well-known SID enumeration.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, NtUiFrame, NtUiFrame.Search,
  NtUiCommon.Interfaces, NtUiBackend.Sids.WellKnown;

type
  TWellKnownSidsFrame = class(TFrame, ICanConsumeEscape, IObservesActivation,
    IHasDefaultCaption)
    Tree: TDevirtualizedTree;
    SearchBox: TSearchFrame;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    property SearchImpl: TSearchFrame read SearchBox implements ICanConsumeEscape, IObservesActivation;
    function GetDefaultCaption: String;
  protected
    procedure Loaded; override;
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

{ TWellKnownSidsFrame }

function TWellKnownSidsFrame.GetDefaultCaption;
begin
  Result := 'Well-known SIDs';
end;

procedure TWellKnownSidsFrame.Loaded;
var
  Provider: IWellKnownSidNode;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree);
  BackendRef := Backend; // Make an owning reference

  Backend.BeginUpdateAuto;

  for Provider in NtUiLibMakeWellKnownSidNodes do
    Backend.AddItem(Provider);
end;

end.
