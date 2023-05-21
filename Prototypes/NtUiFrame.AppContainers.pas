unit NtUiFrame.AppContainers;

{
  This module provides a frame for showing a list of AppContainer profiles.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, DevirtualizedTree.Provider,
  NtUiFrame.Search, NtUtils, NtUtils.Security.AppContainer;

const
  colFriendlyName = 0;
  colDisplayName = 1;
  colMoniker = 2;
  colIsPackage = 3;
  colSID = 4;
  colMax = 5;

type
  IAppContainerNode = interface (INodeProvider)
    ['{AF1E4CBD-1752-4655-8C13-D6B0D18AFE3D}']
    function GetInfo: TAppContainerInfo;
    property Info: TAppContainerInfo read GetInfo;
  end;

  TInspectAppContainer = procedure (const Node: IAppContainerNode) of object;

  TAppContainersFrame = class(TFrame)
    SearchBox: TSearchFrame;
    Tree: TDevirtualizedTree;
    procedure TreeAddToSelection(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeRemoveFromSelection(Sender: TBaseVirtualTree;
      Node: PVirtualNode);
  private
    FOnInspect: TInspectAppContainer;
    FOnSelectionChanged: TNotifyEvent;
    procedure InspectNode(Node: PVirtualNode);
    procedure SetOnInspect(const Value: TInspectAppContainer);
    function GetSelectedCount: Integer;
    function GetSelected: TArray<IAppContainerNode>;
    function GetFocusedItem: IAppContainerNode;
  protected
    procedure Loaded; override;
  public
    procedure ClearItems;
    function BeginUpdateAuto: IAutoReleasable;
    function AddItem(const Info: TAppContainerInfo; const Parent: IAppContainerNode = nil): IAppContainerNode;
    property OnInspect: TInspectAppContainer read FOnInspect write SetOnInspect;
    property OnSelectionChanged: TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
    property Selected: TArray<IAppContainerNode> read GetSelected;
    property SelectedCount: Integer read GetSelectedCount;
    property FocusedItem: IAppContainerNode read GetFocusedItem;
    procedure SetNoItemsStatus(const Status: TNtxStatus);
  end;

implementation

uses
  NtUtils.Security.Sid, NtUtils.SysUtils, NtUtils.Packages, DelphiUtils.Arrays,
  NtUiLib.Errors, DelphiUiLib.Reflection.Strings, UI.Helper, VirtualTrees.Types,
  UI.Colors;

{$R *.dfm}

{ TAppContainerNode }

type
  TAppContainerNode = class (TNodeProvider, IAppContainerNode)
  private
    FInfo: TAppContainerInfo;
  protected
    procedure Initialize; override;
  public
    function GetInfo: TAppContainerInfo;
    constructor Create(
      const Info: TAppContainerInfo
    );
  end;

constructor TAppContainerNode.Create;
begin
  inherited Create(colMax);
  FInfo := Info;
end;

function TAppContainerNode.GetInfo;
begin
  Result := FInfo;
end;

procedure TAppContainerNode.Initialize;
var
  IsPackage: Boolean;
begin
  inherited;

  FColumnText[colSID] := RtlxSidToString(FInfo.Sid);
  FColumnText[colMoniker] := RtlxStringOrDefault(FInfo.Moniker, 'Unknown');

  if FInfo.Moniker <> '' then
  begin
    IsPackage := PkgxIsValidFamilyName(FInfo.Moniker);
    FColumnText[colIsPackage] := YesNoToString(IsPackage);
    FColumnText[colDisplayName] := RtlxStringOrDefault(FInfo.DisplayName, '(None)');
    FColumnText[colFriendlyName] := FInfo.DisplayName;

    if RtlxPrefixString('@{', FInfo.DisplayName, True) then
      PkgxExpandResourceStringVar(FColumnText[colFriendlyName]);

    FColumnText[colFriendlyName] := RtlxStringOrDefault(
      FColumnText[colFriendlyName], '(None)');

     FHasColor := True;

    if IsPackage then
      FColor := ColorSettings.clSystem
    else
      FColor := ColorSettings.clUser;

    FHint := BuildHint([
      THintSection.New('Friendly Name', FColumnText[colFriendlyName]),
      THintSection.New('Monker', FColumnText[colMoniker]),
      THintSection.New('SID', FColumnText[colSID])
    ]);
  end
  else
  begin
    FColumnText[colFriendlyName] := 'Unknown';
    FColumnText[colDisplayName] := 'Unknown';
    FColumnText[colIsPackage] := 'Unknown';
  end;
end;

{ TAppContainersFrame }

function TAppContainersFrame.AddItem;
var
  ParentNode: PVirtualNode;
begin
  Result := TAppContainerNode.Create(Info);

  if Assigned(Parent) then
  begin
    ParentNode := Parent.Node;
    Tree.TreeOptions.PaintOptions := Tree.TreeOptions.PaintOptions + [toShowRoot];
  end
  else
    ParentNode := Tree.RootNode;

  Tree.AddChildEx(ParentNode, Result);

  if Assigned(Parent) then
    Tree.Expanded[Parent.Node] := True;
end;

function TAppContainersFrame.BeginUpdateAuto;
begin
  Result := Tree.BeginUpdateAuto;
end;

procedure TAppContainersFrame.ClearItems;
begin
  Tree.Clear;
  Tree.TreeOptions.PaintOptions := Tree.TreeOptions.PaintOptions - [toShowRoot];
end;

function TAppContainersFrame.GetFocusedItem;
begin
  if not Tree.FocusedNode.TryGetProvider(IAppContainerNode, Result) then
    Result := nil;
end;

function TAppContainersFrame.GetSelected;
begin
  Result := TArray.Convert<PVirtualNode, IAppContainerNode>(
    Tree.SelectedNodes.ToArray,
    function (
      const Node: PVirtualNode;
      out Provider: IAppContainerNode
    ): Boolean
    begin
      Result := Node.TryGetProvider(IAppContainerNode, Provider);
    end
  );
end;

function TAppContainersFrame.GetSelectedCount;
begin
  Result := Tree.SelectedCount;
end;

procedure TAppContainersFrame.InspectNode;
var
  AppContainerNode: IAppContainerNode;
begin
  if Node.TryGetProvider(IAppContainerNode, AppContainerNode) then
    FOnInspect(AppContainerNode);
end;

procedure TAppContainersFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
end;

procedure TAppContainersFrame.SetNoItemsStatus;
begin
  if Status.IsSuccess then
    Tree.NoItemsText := 'No items to display'
  else
    Tree.NoItemsText := 'Unable to query:'#$D#$A + Status.ToString;
end;

procedure TAppContainersFrame.SetOnInspect;
begin
  FOnInspect := Value;

  if Assigned(Value) then
    Tree.OnInspectNode := InspectNode
  else
    Tree.OnInspectNode := nil;
end;

procedure TAppContainersFrame.TreeAddToSelection;
begin
  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

procedure TAppContainersFrame.TreeRemoveFromSelection;
begin
  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

end.
