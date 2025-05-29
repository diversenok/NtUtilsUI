unit NtUiBackend.Acl;

{
  This unit provides the logic for viewing and editing Access Control Lists.
}

interface

uses
  Ntapi.WinNt, DevirtualizedTree, NtUtils, NtUtils.Security.Acl;

type
  IAceNode = interface (INodeProvider)
    ['{67AD9995-0881-4561-8CFD-25178E8F5537}']
    function GetAce: TAceData;
    procedure SetAce(const Value: TAceData);
    function GetCategory: TAceCategory;
    property Ace: TAceData read GetAce write SetAce;
    property Category: TAceCategory read GetCategory;
  end;

// Create a tree node for an ACE
function UiLibMakeAceNode(
  const Ace: TAceData;
  AccessMaskType: Pointer
): IAceNode;

// Make sure ACE-specific columns are visible in the tree
procedure UiLibUnhideAceSpecificColumns(
  Tree: TDevirtualizedTree;
  const Ace: TAceData
);

// Add a new ACE node to the ACL tree control preserving canonical order
procedure UiLibInsertAceNode(
  Tree: TDevirtualizedTree;
  const Ace: TAceData;
  AccessMaskType: Pointer
);

// Add a collection of ACE nodes to the ACL tree control
procedure UiLibLoadAceNodes(
  Tree: TDevirtualizedTree;
  const Aces: TArray<TAceData>;
  AccessMaskType: Pointer
);

// Check if an ACL requires canonicalization
function UiLibIsCanonicalAcl(
  Tree: TDevirtualizedTree
): Boolean;

// Reorder ACEs in an ACL control
procedure UiLibCanonicalizeAcl(
  Tree: TDevirtualizedTree
);

// Collect all ACEs from an ACL control
function UiLibCollectAces(
  Tree: TDevirtualizedTree
): TArray<TAceData>;

implementation

uses
  NtUtils.Security.Sid, NtUtils.Security, NtUtils.SysUtils,
  NtUiLib.Errors, VirtualTrees, DevirtualizedTree.Provider,
  DelphiUiLib.Reflection, DelphiUiLib.Strings, DelphiUiLib.Reflection.Strings,
  UI.Colors, UI.Helper, VirtualTrees.Types;

const
  colUse = 0;
  colAceType = 1;
  colSid = 2;
  colSidRaw = 3;
  colServerSid = 4;
  colServerSidRaw = 5;
  colCondition = 6;
  colAceAccessMask = 7;
  colAceAccessMaskNumeric = 8;
  colAceFlags = 9;
  colObjectType = 10;
  colInheritedObjectType = 11;
  colSddl = 12;
  colMax = 13;

type
  TAceNode = class (TNodeProvider, IAceNode)
  private
    FAce: TAceData;
    FAccessMaskType: Pointer;
  public
    function GetAce: TAceData;
    procedure SetAce(const Value: TAceData);
    function GetCategory: TAceCategory;
    procedure Initialize; override;
    constructor Create(const Ace: TAceData; AccessMaskType: Pointer);
  end;

constructor TAceNode.Create;
begin
  inherited Create(colMax);
  FAce := Ace;
  FAccessMaskType := AccessMaskType;
end;

function TAceNode.GetAce;
begin
  Result := FAce;
end;

function TAceNode.GetCategory;
begin
  Result := RtlxGetCategoryAce(FAce.AceType, FAce.AceFlags);
end;

procedure TAceNode.Initialize;
begin
  inherited;

  if FAce.AceType in AccessAllowedAces then
    FColumnText[colUse] := 'Allow'
  else if FAce.AceType in AccessDeniedAces then
    FColumnText[colUse] := 'Deny'
  else if FAce.AceType in SystemAuditAces then
    FColumnText[colUse] := 'Audit'
  else if FAce.AceType in SystemAlarmAces then
    FColumnText[colUse] := 'Alarm'
  else if FAce.AceType = SYSTEM_MANDATORY_LABEL_ACE_TYPE then
    FColumnText[colUse] := 'Mandatory Label'
  else if FAce.AceType = SYSTEM_RESOURCE_ATTRIBUTE_ACE_TYPE then
    FColumnText[colUse] := 'Attribute'
  else if FAce.AceType = SYSTEM_SCOPED_POLICY_ID_ACE_TYPE then
    FColumnText[colUse] := 'Policy ID'
  else if FAce.AceType = SYSTEM_PROCESS_TRUST_LABEL_ACE_TYPE then
    FColumnText[colUse] := 'Trust Label'
  else if FAce.AceType = SYSTEM_ACCESS_FILTER_ACE_TYPE then
    FColumnText[colUse] := 'Access Filter'
  else
    FColumnText[colUse] := '(Unknown)';

  FColumnText[colAceType] := TType.Represent(FAce.AceType).Text;
  FColumnText[colAceFlags] := TType.Represent(FAce.AceFlags).Text;

  if FAce.AceType = SYSTEM_MANDATORY_LABEL_ACE_TYPE then
    FColumnText[colAceAccessMask] := RepresentType(
      TypeInfo(TMandatoryLabelMask), FAce.Mask).Text
  else  
    FColumnText[colAceAccessMask] := RepresentType(FAccessMaskType,
      FAce.Mask).Text;

  FColumnText[colAceAccessMaskNumeric] := IntToHexEx(FAce.Mask, 6);
  FColumnText[colSid] := TType.Represent(FAce.Sid).Text;
  FColumnText[colSidRaw] := RtlxSidToString(FAce.Sid);

  if FAce.AceType = ACCESS_ALLOWED_COMPOUND_ACE_TYPE then
  begin
    FColumnText[colServerSid] := TType.Represent(FAce.ServerSID).Text;
    FColumnText[colServerSidRaw] := RtlxSidToString(FAce.ServerSID);
  end
  else
  begin
    FColumnText[colServerSid] := '';
    FColumnText[colServerSidRaw] := '';
  end;

  if FAce.AceType in CallbackAces then
    if AdvxAceConditionToSddl(FAce.ExtraData,
      FColumnText[colCondition]).IsSuccess then
    FColumnText[colCondition] := RtlxStringOrDefault(
      FColumnText[colCondition], '(empty)')
    else      
      FColumnText[colCondition] := '(invalid)'
  else
    FColumnText[colCondition] := '';

  if (FAce.AceType in ObjectAces) and BitTest(FAce.ObjectFlags and 
    ACE_OBJECT_TYPE_PRESENT) then
    FColumnText[colObjectType] := RtlxGuidToString(FAce.ObjectType)
  else
    FColumnText[colObjectType] := '';

  if (FAce.AceType in ObjectAces) and BitTest(FAce.ObjectFlags and 
    ACE_INHERITED_OBJECT_TYPE_PRESENT) then
    FColumnText[colInheritedObjectType] := RtlxGuidToString(
      FAce.InheritedObjectType)
  else
    FColumnText[colInheritedObjectType] := '';

  if not AdvxAceToSddl(FAce, FColumnText[colSddl]).IsSuccess then
    FColumnText[colSddl] := '(invalid)';

  FHint := BuildHint([
    THintSection.New('Type', FColumnText[colAceType]),
    THintSection.New('Flags', FColumnText[colAceFlags]),
    THintSection.New('Access Mask', FColumnText[colAceAccessMask]),
    THintSection.New('SID', FColumnText[colSid]),
    THintSection.New('Server SID', FColumnText[colServerSid]),
    THintSection.New('Condition', FColumnText[colCondition])
  ]);

  if BitTest(FAce.AceFlags and INHERIT_ONLY_ACE) then
    SetFontColor(ColorSettings.clForegroundInactive);

  if FAce.AceType in AccessAllowedAces then
    if BitTest(FAce.AceFlags and INHERITED_ACE) then
      SetColor(ColorSettings.clBackgroundAllow)
    else
      SetColor(ColorSettings.clBackgroundAllowAccent)
  else if FAce.AceType in AccessDeniedAces then
    if BitTest(FAce.AceFlags and INHERITED_ACE) then
      SetColor(ColorSettings.clBackgroundDeny)
    else
      SetColor(ColorSettings.clBackgroundDeny)
  else
    if BitTest(FAce.AceFlags and INHERITED_ACE) then
      SetColor(ColorSettings.clBackgroundAlter)
    else
      SetColor(ColorSettings.clBackgroundAlterAccent)
end;

procedure TAceNode.SetAce;
begin
  FAce := Value;
  Initialize;
  Invalidate;
end;

function UiLibMakeAceNode;
begin
  Result := TAceNode.Create(Ace, AccessMaskType);
end;

procedure UiLibUnhideAceSpecificColumns;
begin
  // Condition for callback ACEs
  if Ace.AceType in CallbackAces then
    Tree.Header.Columns[colCondition].Options :=
      Tree.Header.Columns[colCondition].Options + [coVisible]

  // Server SID for compound ACEs
  else if Ace.AceType = ACCESS_ALLOWED_COMPOUND_ACE_TYPE then
    Tree.Header.Columns[colServerSid].Options :=
      Tree.Header.Columns[colServerSid].Options + [coVisible];

  // Flags
  if HasAny(Ace.AceFlags) then
    Tree.Header.Columns[colAceFlags].Options :=
      Tree.Header.Columns[colAceFlags].Options + [coVisible];
end;

function UiLibChooseAceIndex(
  Tree: TDevirtualizedTree;
  Category: TAceCategory
): PVirtualNode;
var
  CurrentCategory: TAceCategory;
  Node: PVirtualNode;
  NodeProvider: IAceNode;
begin
  // Insert as the last by default
  Result := nil;

  for Node in Tree.Nodes do
    if Node.TryGetProvider(IAceNode, NodeProvider) then
    begin
      // Determine which category the ACE belongs to
      CurrentCategory := RtlxGetCategoryAce(NodeProvider.Ace.AceType,
        NodeProvider.Ace.AceFlags);

      // Insert right before the next category
      if CurrentCategory > Category then
        Exit(Node);
    end;
end;

procedure UiLibInsertAceNode;
var
  NewNode: IAceNode;
  InsertBefore: PVirtualNode;
begin
  Tree.BeginUpdateAuto;

  // Determine where to insert the new ACE
  InsertBefore := UiLibChooseAceIndex(Tree, RtlxGetCategoryAce(Ace.AceType,
    Ace.AceFlags));

  // Create its provider
  NewNode := UiLibMakeAceNode(Ace, AccessMaskType);

  // Add it to the tree
  if Assigned(InsertBefore) then
    Tree.InsertNodeEx(InsertBefore, amInsertBefore, NewNode)
  else
    Tree.AddChildEx(nil, NewNode);

  // Update column visibility
  UiLibUnhideAceSpecificColumns(Tree, Ace);
end;

procedure UiLibLoadAceNodes;
var
  i: Integer;
begin
  Tree.BeginUpdateAuto;
  Tree.Clear;

  for i := 0 to High(Aces) do
  begin
    Tree.AddChildEx(nil, UiLibMakeAceNode(Aces[i], AccessMaskType));
    UiLibUnhideAceSpecificColumns(Tree, Aces[i]);
  end;
end;

function UiLibIsCanonicalAcl;
var
  LastCategory, CurrentCategory: TAceCategory;
  Node: PVirtualNode;
  AceNode: IAceNode;
begin
  // The elements of the enumeration follow the required order
  LastCategory := Low(TAceCategory);
  Result := False;

  for Node in Tree.Nodes do
    if Node.TryGetProvider(IAceNode, AceNode) then
    begin
      // Determine which category the ACE belongs to
      CurrentCategory := AceNode.Category;

      // Categories should always grow
      if not (CurrentCategory >= LastCategory) then
        Exit;

      LastCategory := CurrentCategory;
    end;

  Result := True;
end;

procedure UiLibCanonicalizeAcl;
var
  Aces: array [TAceCategory] of TArray<IAceNode>;
  Category: TAceCategory;
  Node: PVirtualNode;
  AceNode: IAceNode;
begin
  // Make each category empty by default
  for Category := Low(TAceCategory) to High(TAceCategory) do
    Aces[Category] := nil;

  // Group ACEs per category
  for Node in Tree.Nodes do
    if Node.TryGetProvider(IAceNode, AceNode) then
    begin
      Category := AceNode.Category;
      SetLength(Aces[Category], Length(Aces[Category]) + 1);
      Aces[Category][High(Aces[Category])] := AceNode;
    end;

  Tree.BeginUpdateAuto;

  // Reorder ACEs category-by-category preserving their order within each
  for Category := Low(TAceCategory) to High(TAceCategory) do
    for AceNode in Aces[Category] do
      Tree.MoveTo(AceNode.Node, Tree.RootNode, amAddChildLast, False);
end;

function UiLibCollectAces;
var
  Count: Integer;
  Node: PVirtualNode;
  AceNode: IAceNode;
begin
  Count := 0;

  for Node in Tree.Nodes do
    if Node.HasProvider(IAceNode) then
      Inc(Count);

  SetLength(Result, Count);
  Count := 0;

  for Node in Tree.Nodes do
    if Node.TryGetProvider(IAceNode, AceNode) then
    begin
      Result[Count] := AceNode.Ace;
      Inc(Count);
    end;
end;

end.
