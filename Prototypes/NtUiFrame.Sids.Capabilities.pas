unit NtUiFrame.Sids.Capabilities;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.Tree, NtUiCommon.Interfaces, NtUiCommon.Prototypes,
  NtUtilsUI, NtUtilsUI.Base, NtUtilsUI.Tree.Search;

type
  TCapabilityListFrame = class(TFrame, IHasDefaultCaption,
    IModalResult<TArray<TNtUiLibCapability>>, IDelayedLoad)
    SearchBox: TUiLibTreeSearchBox;
    Tree: TUiLibTree;
  private
    UseCheckboxes: Boolean;
    function GetDefaultCaption: String;
    function GetModalResult: TArray<TNtUiLibCapability>;
  protected
    procedure Loaded; override;
  public
    procedure DelayedLoad;
  end;

implementation

uses
  NtUiBackend.Sids.Capabilities, NtUtils, VirtualTrees.Types,
  NtUtilsUI.Components;

{$R *.dfm}

{ TCapabilityListFrame }

procedure TCapabilityListFrame.DelayedLoad;
var
  NodeInfo: TCapabilityNodes;
  Category: TCapabilityCategory;
  i: Integer;
begin
  NodeInfo := UiLibMakeCapabilityNodes;
  Tree.BeginUpdateAuto;
  Tree.Clear;
  Tree.EmptyListMessage := 'No items to display';

  for Category := Low(TCapabilityCategory) to High(TCapabilityCategory) do
  begin
    Tree.AddChild(NodeInfo[Category].Group);

    for i := 0 to High(NodeInfo[Category].Items) do
    begin
      Tree.AddChild(NodeInfo[Category].Items[i], NodeInfo[Category].Group);

      if UseCheckboxes then
        Tree.CheckType[NodeInfo[Category].Items[i].Node] := ctCheckBox;
    end;
  end;
end;

function TCapabilityListFrame.GetDefaultCaption;
begin
  Result := 'Capabilities';
end;

function TCapabilityListFrame.GetModalResult;
var
  Nodes: TArray<PVirtualNode>;
  Provider: ICapabilityNode;
  i, j: Integer;
begin
  Nodes := Tree.CheckedNodes.Nodes;
  SetLength(Result, Length(Nodes));

  j := 0;
  for i := 0 to High(Nodes) do
    if Nodes[i].TryGetProvider(ICapabilityNode, Provider) then
    begin
      Result[j].Name := Provider.Name;
      Result[j].AppSid := Provider.AppSid;
      Result[j].GroupSid := Provider.GroupSid;
      Inc(j);
    end;

  if j <> Length(Result) then
    SetLength(Result, j);
end;

procedure TCapabilityListFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
end;

function Initializer(ShowCheckboxes: Boolean): TWinControlFactory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      Frame: TCapabilityListFrame absolute Result;
    begin
      Frame := TCapabilityListFrame.Create(AOwner);
      Frame.UseCheckboxes := ShowCheckboxes;
    end;
end;

function NtUiLibSelectCapabilities(
  Owner: TComponent
): TArray<TNtUiLibCapability>;
begin
  Result := UiLibHost.Pick<TArray<TNtUiLibCapability>>(Owner, Initializer(True));
end;

initialization
  NtUiCommon.Prototypes.NtUiLibSelectCapabilities := NtUiLibSelectCapabilities;
end.
