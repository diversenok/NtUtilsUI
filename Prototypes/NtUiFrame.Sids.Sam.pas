unit NtUiFrame.Sids.Sam;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.Tree,
  NtUiCommon.Interfaces, NtUtilsUI, NtUtilsUI.Base,
  NtUtilsUI.Tree.Search;

type
  TSamSidsFrame = class(TFrame, IHasDefaultCaption, IDelayedLoad)
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

uses
  NtUtils, NtUiBackend.Sids.Sam, NtUiLib.Errors;

{$R *.dfm}

{ TSamSidFrame }

procedure TSamSidsFrame.DelayedLoad;
var
  Status: TNtxStatus;
  Nodes: TArray<TSamDomainNodes>;
  i, j: Integer;
begin
  Status := NtUiLibCollectSamNodes(Nodes);

  Tree.BeginUpdateAuto;
  Tree.Clear;

  if not Status.IsSuccess then
  begin
    Tree.EmptyListMessage := 'Unable to query:'#$D#$A + Status.ToString;
    Exit;
  end;

  for i := 0 to High(Nodes) do
  begin
    // Domain
    Tree.AddChild(Nodes[i].Domain);

    // Groups
    for j := 0 to High(Nodes[i].Groups) do
      Tree.AddChild(Nodes[i].Groups[j], Nodes[i].Domain);

    // Aliases
    for j := 0 to High(Nodes[i].Aliases) do
      Tree.AddChild(Nodes[i].Aliases[j], Nodes[i].Domain);

    // Users
    for j := 0 to High(Nodes[i].Users) do
      Tree.AddChild(Nodes[i].Users[j], Nodes[i].Domain);
  end;
end;

function TSamSidsFrame.GetDefaultCaption;
begin
  Result := 'SAM Accounts';
end;

procedure TSamSidsFrame.CreateWnd;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
end;

end.
