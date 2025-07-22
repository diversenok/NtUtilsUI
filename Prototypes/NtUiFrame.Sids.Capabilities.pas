unit NtUiFrame.Sids.Capabilities;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, NtUiFrame, NtUiFrame.Search,
  NtUiCommon.Interfaces;

type
  TCapabilityListFrame = class(TFrame, ICanConsumeEscape, IObservesActivation,
    IHasDefaultCaption, IHasModalResult, IDelayedLoad)
    SearchBox: TSearchFrame;
    Tree: TDevirtualizedTree;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    UseCheckboxes: Boolean;
    property SearchImpl: TSearchFrame read SearchBox implements ICanConsumeEscape, IObservesActivation;
    function GetDefaultCaption: String;
    function GetModalResult: IInterface;
  protected
    procedure Loaded; override;
  public
    procedure DelayedLoad;
  end;

implementation

uses
  NtUiBackend.Sids.Capabilities, UI.Helper, NtUiCommon.Prototypes, NtUtils,
  VirtualTrees.Types;

{$R *.dfm}

{ TCapabilityListFrame }

procedure TCapabilityListFrame.DelayedLoad;
var
  NodeInfo: TCapabilityNodes;
  Category: TCapabilityCategory;
  i: Integer;
begin
  NodeInfo := UiLibMakeCapabilityNodes;
  Backend.BeginUpdateAuto;
  Backend.ClearItems;
  Tree.NoItemsText := 'No items to display';

  for Category := Low(TCapabilityCategory) to High(TCapabilityCategory) do
  begin
    Backend.AddItem(NodeInfo[Category].Group);

    for i := 0 to High(NodeInfo[Category].Items) do
    begin
      Backend.AddItem(NodeInfo[Category].Items[i], NodeInfo[Category].Group);

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
  Output: TArray<TNtUiLibCapability>;
  i, j: Integer;
begin
  Nodes := Tree.CheckedNodes.ToArray;
  SetLength(Output, Length(Nodes));

  j := 0;
  for i := 0 to High(Nodes) do
    if Nodes[i].TryGetProvider(ICapabilityNode, Provider) then
    begin
      Output[j].Name := Provider.Name;
      Output[j].AppSid := Provider.AppSid;
      Output[j].GroupSid := Provider.GroupSid;
      Inc(j);
    end;

  if j <> Length(Output) then
    SetLength(Output, j);

  Result := Auto.Copy(Output);
end;

procedure TCapabilityListFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree, [teSelectionChange]);
  BackendRef := Backend; // Make an owning reference
end;

function Initializer(ShowCheckboxes: Boolean): TFrameInitializer;
begin
  Result := function (AOwner: TComponent): TFrame
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
  if not Assigned(NtUiLibHostFramePick) then
    raise ENotSupportedException.Create('Frame host not available');

  Result := TArray<TNtUiLibCapability>((NtUiLibHostFramePick(Owner,
    Initializer(True)) as IMemory).Data^);
end;

initialization
  NtUiCommon.Prototypes.NtUiLibSelectCapabilities := NtUiLibSelectCapabilities;
end.
