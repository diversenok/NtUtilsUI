unit NtUiFrame.Sids.Abbreviations;

{
  This module provides a frame for displaying the SDDL SID abbreviations.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, NtUiFrame, NtUiFrame.Search,
  NtUiCommon.Interfaces;

type
  TSidAbbreviationFrame = class(TFrame, ICanConsumeEscape, IObservesActivation,
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

uses
  NtUiBackend.Sids.Abbreviations;

{$R *.dfm}

{ TSidAbbreviationFrame }

function TSidAbbreviationFrame.GetDefaultCaption;
begin
  Result := 'SDDL Abbreviations';
end;

procedure TSidAbbreviationFrame.Loaded;
var
  Provider: ISidAbbreviationNode;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree);
  BackendRef := Backend; // Make an owning reference

  Backend.BeginUpdateAuto;

  for Provider in NtUiLibCollectSidAbbreviations do
    Backend.AddItem(Provider);
end;

end.
