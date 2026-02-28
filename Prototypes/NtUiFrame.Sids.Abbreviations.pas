unit NtUiFrame.Sids.Abbreviations;

{
  This module provides a frame for displaying the SDDL SID abbreviations.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.VirtualTreeEx, NtUtilsUI.DevirtualizedTree, NtUiFrame,
  NtUiFrame.Search, NtUiCommon.Interfaces;

type
  TSidAbbreviationFrame = class(TBaseFrame, ICanConsumeEscape, IObservesActivation,
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

uses
  NtUiBackend.Sids.Abbreviations;

{$R *.dfm}

{ TSidAbbreviationFrame }

procedure TSidAbbreviationFrame.DelayedLoad;
var
  Provider: ISidAbbreviationNode;
begin
  Backend.BeginUpdateAuto;
  Backend.ClearItems;

  for Provider in NtUiLibCollectSidAbbreviations do
    Backend.AddItem(Provider);
end;

function TSidAbbreviationFrame.GetDefaultCaption;
begin
  Result := 'SDDL Abbreviations';
end;

procedure TSidAbbreviationFrame.LoadedOnce;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree);
  BackendRef := Backend; // Make an owning reference
end;

end.
