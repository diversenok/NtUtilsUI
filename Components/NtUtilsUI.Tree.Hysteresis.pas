unit NtUtilsUI.Tree.Hysteresis;

{
  This unit provides support for using TUiLibTree to display nodes managed by a
  hysteresis tree data structure, which stores a (flat or tree-like) collection
  of elements and has a short memory of its previous state (used to identify
  recently added/removed entries).
}

interface

uses
  Vcl.Graphics, VirtualTrees, NtUtilsUI.Tree, DelphiUtils.Arrays,
  DelphiUiLib.HysteresisTree, DelphiApi.Reflection;

type
  // A non-generic base interface for a node in a tree control with hysteresis
  IHysteresisNodeProvider = interface (INodeProvider)
    ['{25E9A690-2D58-4DB0-AA48-0B0B6FB8C50E}']
    function GetHysteresisNode: THysteresisNode;
    property HysteresisNode: THysteresisNode read GetHysteresisNode;
  end;

  // A generic interface for a node in a tree control with hysteresis
  IHysteresisNodeProvider<T> = interface (IHysteresisNodeProvider)
    ['{714B66A6-1E23-4E84-BCB7-1F0D741A1100}']
    function GetHysteresisNode: THysteresisNode<T>;
    property HysteresisNode: THysteresisNode<T> read GetHysteresisNode;
  end;

  // A non-generic base class for a node in a tree control with hysteresis
  THysteresisNodeProvider = class abstract (TNodeProvider,
    IHysteresisNodeProvider)
  private
    FHysteresisNode: THysteresisNode;
  protected
    function GetHysteresisNode: THysteresisNode;
    procedure PreUpdate; virtual;
    procedure PostUpdate; virtual;
    function GetColor(out Value: TColor): Boolean; override;
    function SortCompare(Node: INodeProvider; Column: TColumnIndex): Integer; override;
  public
    constructor Create(AHysteresisNode: THysteresisNode); virtual;
  end;

  THysteresisNodeProviderClass = class of THysteresisNodeProvider;

  // A generic class for a node in a tree control with hysteresis
  THysteresisNodeProvider<T> = class (THysteresisNodeProvider,
    IHysteresisNodeProvider<T>)
  private
    function GetHysteresisNode: THysteresisNode<T>;
  protected
    property HysteresisNode: THysteresisNode<T> read GetHysteresisNode;
  end;

  // A non-generic base interface for the hysteresis tree container
  IUiLibHysteresisContainer = interface
    ['{5EF6A6C9-937E-4D1D-A2A7-013B5EE2F068}']
    function GetControl: TUiLibTree;
    function GetCore: IHysteresisTree;

    // Notify nodes that an update is about to begin
    procedure PreUpdate;

    // Refresh the tree with the new data snapshot
    procedure Update(const Data: TArray<Pointer>);

    // Retrieve the UI tree control reference
    property Control: TUiLibTree read GetControl;

    // Retrieve the hysteresis tree data structure reference
    property Core: IHysteresisTree read GetCore;
  end;

  TUiLibHysteresisContainer = class abstract (TInterfacedObject,
    IUiLibHysteresisContainer)
  protected
    FControl: TUiLibTree;
    FCore: IHysteresisTree;
    FProviderClass: THysteresisNodeProviderClass;
    function GetControl: TUiLibTree;
    function GetCore: IHysteresisTree;
    procedure IssueNodeEvents;
    procedure PreUpdate;
    procedure Update(const Data: TArray<Pointer>);
  end;

  // A generic interface for the hysteresis tree container
  IUiLibHysteresisContainer<T> = interface (IUiLibHysteresisContainer)
    ['{C4AC2D6C-3B5A-42E6-B31A-EFA0452375D4}']
    function GetCore: IHysteresisTree<T>;

    // Refresh the tree with the new data snapshot
    procedure Update(const Entries: TArray<T>);

    // Retrieve the hysteresis tree data structure reference
    property Core: IHysteresisTree<T> read GetCore;
  end;

  TUiLibHysteresisContainer<T> = class sealed (TUiLibHysteresisContainer,
    IUiLibHysteresisContainer<T>)
  private
    function GetCore: IHysteresisTree<T>;
    procedure Update(const Entries: TArray<T>);
    constructor Create(
      TreeControl: TUiLibTree;
      ProviderClass: THysteresisNodeProviderClass;
      EquivalencyCheck: TEqualityCheck<T>
    );
  public
    class function Initialize(
      TreeControl: TUiLibTree;
      ProviderClass: THysteresisNodeProviderClass;
      EquivalencyCheck: TEqualityCheck<T>
    ): IUiLibHysteresisContainer<T>;
  end;

implementation

uses
  NtUtilsUI;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NodeToProvider(Node: THysteresisNode): THysteresisNodeProvider;
begin
  if Assigned(Node) then
    Result := Node.Context
  else
    Result := nil;
end;

{ THysteresisNodeProvider }

constructor THysteresisNodeProvider.Create;
begin
  inherited Create(0);
  FHysteresisNode := AHysteresisNode;
end;

function THysteresisNodeProvider.GetColor;
begin
  case FHysteresisNode.TransitionState of
    hntRecentlyAdded:
    begin
      Result := True;
      Value := ColorSettings.clBackgroundRecentlyAdded;
    end;

    hntRecentlyRemoved:
    begin
      Result := True;
      Value := ColorSettings.clBackgroundRecentlyRemoved;
    end;
  else
    Result := False;
  end;
end;

function THysteresisNodeProvider.GetHysteresisNode;
begin
  Result := FHysteresisNode;
end;

procedure THysteresisNodeProvider.PostUpdate;
begin
  Invalidate;
end;

procedure THysteresisNodeProvider.PreUpdate;
begin
  ; // for overrides
end;

function THysteresisNodeProvider.SortCompare;
begin
  if Column < 0 then
    {$R-}{$Q-}
    // Use the original order when resetting sorting
    Result := (Node as IHysteresisNodeProvider).HysteresisNode.Index -
      FHysteresisNode.Index
    {$IFDEF Q+}{$Q+}{$ENDIF}{$IFDEF R+}{$R+}{$ENDIF}
  else
    Result := inherited;
end;

{ THysteresisNodeProvider<T> }

function THysteresisNodeProvider<T>.GetHysteresisNode;
begin
  Result := THysteresisNode<T>(inherited GetHysteresisNode);
end;

{ TUiLibHysteresisContainer }

function TUiLibHysteresisContainer.GetControl;
begin
  Result := FControl;
end;

function TUiLibHysteresisContainer.GetCore;
begin
  Result := FCore;
end;

procedure TUiLibHysteresisContainer.IssueNodeEvents;
var
  Node, Sibling: THysteresisNode;
  Provider: THysteresisNodeProvider;
begin
  // Create and insert new nodes (with no parent for now)
  for Node in FCore.Nodes do
    if Node.NewlyAdded then
    begin
      Provider := FProviderClass.Create(Node);
      Node.Context := Provider;
      FControl.InsertNode(Provider, amAddChildLast, nil);
    end;

  if Assigned(FCore.FirstNode) then
  begin
    // Find the first root node
    Node := FCore.FirstNode;

    while Assigned(Node.Parent) do
      Node := Node.Parent;

    while Assigned(Node.PreviousSibling) do
      Node := Node.PreviousSibling;

    // Move the first root node to its position
    FControl.MoveTo(NodeToProvider(Node), amAddChildFirst, nil);

    // Move other root nodes
    while Assigned(Node.NextSibling) do
    begin
      FControl.MoveTo(NodeToProvider(Node.NextSibling), amInsertAfter,
        NodeToProvider(Node));
      Node := Node.NextSibling;
    end;
  end;

  // Move all parented new nodes to their correct positions
  for Node in FCore.Nodes do
    if Assigned(Node.FirstChild) then
    begin
      FControl.MoveTo(NodeToProvider(Node.FirstChild), amAddChildFirst,
        NodeToProvider(Node));

      Sibling := Node.FirstChild.NextSibling;
      while Assigned(Sibling) do
      begin
        FControl.MoveTo(NodeToProvider(Sibling), amInsertAfter,
          NodeToProvider(Sibling.PreviousSibling));
        Sibling := Sibling.NextSibling;
      end;
    end;

  // Move all deleted nodes to the root to flatten them (as we don't want to
  // issue deletes on nodes that might have children)
  for Node in FCore.DeletedNodes do
    FControl.MoveTo(NodeToProvider(Node), amAddChildLast, nil);

  // And then delete them
  for Node in FCore.DeletedNodes do
  begin
    Assert(FControl.ChildCount[NodeToProvider(Node).FNode] = 0,
      'Deleting while there are children');
    FControl.DeleteNode(NodeToProvider(Node).FNode);
  end;

  // Finally, issue post-update events
  for Node in FCore.Nodes do
    NodeToProvider(Node).PostUpdate;
end;

procedure TUiLibHysteresisContainer.PreUpdate;
var
  Node: THysteresisNode;
begin
  for Node in FCore.Nodes do
    NodeToProvider(Node).PreUpdate;
end;

procedure TUiLibHysteresisContainer.Update;
var
  ScrollToBottom: Boolean;
  LastVisible: PVirtualNode;
begin
  // If the control is already scrolled all the way to the bottom, we want to
  // automatically scroll to the new nodes that appear lower
  LastVisible := FControl.GetLastVisible;
  ScrollToBottom := Assigned(LastVisible) and
    (LastVisible = FControl.BottomNode);

  // Merge new data
  FCore.Update(Data);

  // Sync the UI tree with the hysteresis tree state
  FControl.BeginUpdateAuto;
  IssueNodeEvents;

  // Scroll
  if ScrollToBottom then
  begin
    LastVisible := FControl.GetLastVisible;

    if Assigned(LastVisible) then
      FControl.ScrollIntoView(LastVisible, False);
  end;
end;

{ TUiLibHysteresisContainer<T> }

constructor TUiLibHysteresisContainer<T>.Create;
begin
  inherited Create;
  FControl := TreeControl;
  FProviderClass := ProviderClass;
  FCore := THysteresisTree<T>.Initialize(EquivalencyCheck);
end;

function TUiLibHysteresisContainer<T>.GetCore;
begin
  Result := IHysteresisTree<T>(FCore);
end;

class function TUiLibHysteresisContainer<T>.Initialize;
begin
  Result := TUiLibHysteresisContainer<T>.Create(TreeControl, ProviderClass,
    EquivalencyCheck);
end;

procedure TUiLibHysteresisContainer<T>.Update;
var
  Data: TArray<Pointer>;
  i: Integer;
begin
  SetLength(Data, Length(Entries));

  for i := 0 to High(Data) do
    Data[i] := @Entries[i];

  inherited Update(Data);
end;

end.
