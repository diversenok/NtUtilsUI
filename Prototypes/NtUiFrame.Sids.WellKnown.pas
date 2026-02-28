unit NtUiFrame.Sids.WellKnown;

{
  This module provides a frame for displaying the well-known SID enumeration.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.VirtualTreeEx, NtUtilsUI.DevirtualizedTree, NtUiFrame,
  NtUiFrame.Search, NtUiCommon.Interfaces, NtUiBackend.Sids.WellKnown;

type
  TWellKnownSidsFrame = class(TBaseFrame, ICanConsumeEscape, IObservesActivation,
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

procedure TWellKnownSidsFrame.LoadedOnce;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree);
  BackendRef := Backend; // Make an owning reference
end;

end.
