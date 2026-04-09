unit NtUiFrame.Sids.Logon;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  VirtualTrees, NtUtilsUI.VirtualTreeEx, NtUtilsUI.DevirtualizedTree,
  NtUiCommon.Interfaces, NtUtilsUI, NtUtilsUI.Base,
  NtUtilsUI.DevirtualizedTree.Search;

type
  TLogonSidsFrame = class(TFrame, IHasDefaultCaption, IDelayedLoad)
    SearchBox: TUiLibTreeSearchBox;
    Tree: TDevirtualizedTree;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    function GetDefaultCaption: String;
  protected
    procedure DelayedLoad;
    procedure CreateWnd; override;
  public
    { Public declarations }
  end;

implementation

uses
  NtUtils, NtUiBackend.Sids.Logon;

{$R *.dfm}

{ TLogonSidsFrame }

procedure TLogonSidsFrame.DelayedLoad;
var
  Status: TNtxStatus;
  Nodes: TArray<INodeProvider>;
  i: Integer;
begin
  Status := NtUiLibCollectLogonSidNodes(Nodes);

  Backend.BeginUpdateAuto;
  Backend.ClearItems;

  if not Status.IsSuccess then
  begin
    Backend.SetStatus(Status);
    Exit;
  end;

  for i := 0 to High(Nodes) do
    Backend.AddItem(Nodes[i]);
end;

function TLogonSidsFrame.GetDefaultCaption;
begin
  Result := 'Logon Sessions';
end;

procedure TLogonSidsFrame.CreateWnd;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree);
  BackendRef := Backend; // Make an owning reference
end;

end.
