unit NtUiFrame.Sids.Logon;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  VirtualTrees, NtUtilsUI.Tree,
  NtUiCommon.Interfaces, NtUtilsUI, NtUtilsUI.Base,
  NtUtilsUI.Tree.Search;

type
  TLogonSidsFrame = class(TFrame, IHasDefaultCaption, IDelayedLoad)
    SearchBox: TUiLibTreeSearchBox;
    Tree: TUiLibTree;
  private
    function GetDefaultCaption: String;
  protected
    procedure DelayedLoad;
    procedure CreateWnd; override;
  public
    { Public declarations }
  end;

implementation

uses
  NtUtils, NtUiBackend.Sids.Logon, NtUiLib.Errors;

{$R *.dfm}

{ TLogonSidsFrame }

procedure TLogonSidsFrame.DelayedLoad;
var
  Status: TNtxStatus;
  Nodes: TArray<INodeProvider>;
  i: Integer;
begin
  Status := NtUiLibCollectLogonSidNodes(Nodes);

  Tree.BeginUpdateAuto;
  Tree.Clear;

  if not Status.IsSuccess then
  begin
    Tree.EmptyListMessage := 'Unable to query:'#$D#$A + Status.ToString;
    Exit;
  end;

  for i := 0 to High(Nodes) do
    Tree.AddChild(Nodes[i]);
end;

function TLogonSidsFrame.GetDefaultCaption;
begin
  Result := 'Logon Sessions';
end;

procedure TLogonSidsFrame.CreateWnd;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
end;

end.
