unit NtUiFrame.Sids.Sam;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, NtUiFrame, NtUiFrame.Search,
  NtUiCommon.Interfaces;

type
  TSamSidsFrame = class(TBaseFrame, ICanConsumeEscape, IObservesActivation,
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
  NtUtils, NtUiBackend.Sids.Sam;

{$R *.dfm}

{ TSamSidFrame }

procedure TSamSidsFrame.DelayedLoad;
var
  Status: TNtxStatus;
  Nodes: TArray<TSamDomainNodes>;
  i, j: Integer;
begin
  Status := NtUiLibCollectSamNodes(Nodes);

  Backend.BeginUpdateAuto;
  Backend.ClearItems;

  if not Status.IsSuccess then
  begin
    Backend.SetStatus(Status);
    Exit;
  end;

  for i := 0 to High(Nodes) do
  begin
    // Domain
    Backend.AddItem(Nodes[i].Domain);

    // Groups
    for j := 0 to High(Nodes[i].Groups) do
      Backend.AddItem(Nodes[i].Groups[j], Nodes[i].Domain);

    // Aliases
    for j := 0 to High(Nodes[i].Aliases) do
      Backend.AddItem(Nodes[i].Aliases[j], Nodes[i].Domain);

    // Users
    for j := 0 to High(Nodes[i].Users) do
      Backend.AddItem(Nodes[i].Users[j], Nodes[i].Domain);
  end;
end;

function TSamSidsFrame.GetDefaultCaption;
begin
  Result := 'SAM Accounts';
end;

procedure TSamSidsFrame.LoadedOnce;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree);
  BackendRef := Backend; // Make an owning reference
end;

end.
