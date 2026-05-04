unit NtUiFrame.Sids.Abbreviations;

{
  This module provides a frame for displaying the SDDL SID abbreviations.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.Tree,
  NtUiCommon.Interfaces, NtUtilsUI, NtUtilsUI.Base,
  NtUtilsUI.Tree.Search;

type
  [DefaultCaption('SDDL Abbreviations')]
  TSidAbbreviationFrame = class(TFrame, IDelayedLoad)
    Tree: TUiLibTree;
    SearchBox: TUiLibTreeSearchBox;
  protected
    procedure Loaded; override;
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
  Tree.BeginUpdateAuto;
  Tree.Clear;

  for Provider in NtUiLibCollectSidAbbreviations do
    Tree.AddChild(Provider);
end;

procedure TSidAbbreviationFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
end;

end.
