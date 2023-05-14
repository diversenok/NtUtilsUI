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
    ['{660DF981-AC29-46FA-8E32-E88A60622CC6}']
    function GetInfo: TAppContainerInfo;
    property Info: TAppContainerInfo read GetInfo;
  end;

  TInspectAppContainer = procedure (const Node: IAppContainerNode) of object;

  TAppContainersFrame = class(TFrame)
    SearchBox: TSearchFrame;
    Tree: TDevirtualizedTree;
  private
    FOnInspect: TInspectAppContainer;
    procedure InspectNode(Node: PVirtualNode);
    procedure SetOnInspect(const Value: TInspectAppContainer);
    function GetSelectedCount: Integer;
    function GetSelected: TArray<IAppContainerNode>;
    function GetFocusedItem: IAppContainerNode;
  protected
    procedure Loaded; override;
  public
    procedure ClearItems;
    function AddItem(const Info: TAppContainerInfo; const Parent: IAppContainerNode = nil): IAppContainerNode;
    property OnInspect: TInspectAppContainer read FOnInspect write SetOnInspect;
    property Selected: TArray<IAppContainerNode> read GetSelected;
    property SelectedCount: Integer read GetSelectedCount;
    property FocusedItem: IAppContainerNode read GetFocusedItem;
  end;

implementation

uses
  NtUtils.Security.Sid, NtUtils.SysUtils, NtUtils.Packages, DelphiUtils.Arrays,
  DelphiUiLib.Reflection.Strings;

{$R *.dfm}

{ TAppContainerNode }

type
  TAppContainerNode = class (TNodeProvider, IAppContainerNode)
  private
    FInfo: TAppContainerInfo;
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

  FColumnText[colSID] := RtlxSidToString(Info.Sid);
  FColumnText[colMoniker] := Info.Moniker;
  FColumnText[colDisplayName] := Info.DisplayName;
  FColumnText[colFriendlyName] := Info.DisplayName;
  FColumnText[colIsPackage] := YesNoToString(PkgxIsValidFamilyName(Info.Moniker));

  if RtlxPrefixString('@{', Info.DisplayName, True) then
    PkgxExpandResourceStringVar(FColumnText[colFriendlyName]);
end;

function TAppContainerNode.GetInfo;
begin
  Result := FInfo;
end;

{ TAppContainersFrame }

function TAppContainersFrame.AddItem;
begin
  Result := TAppContainerNode.Create(Info);
  Tree.AddChildEx(Parent.Node, Result);
end;

procedure TAppContainersFrame.ClearItems;
begin
  Tree.Clear;
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

procedure TAppContainersFrame.SetOnInspect;
begin
  FOnInspect := Value;

  if Assigned(Value) then
    Tree.OnInspectNode := InspectNode
  else
    Tree.OnInspectNode := nil;
end;

end.
