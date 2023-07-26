unit NtUiBackend.Acl;

{
  This unit provides the logic for viewing and esiting Access Control Lists.
}

interface

uses
  Ntapi.WinNt, DevirtualizedTree, NtUtils, NtUtils.Security.Acl;

const
  colUse = 0;
  colAceType = 1;
  colAceAccessMask = 2;
  colAceAccessMaskNumeric = 3;
  colSid = 4;
  colSidRaw = 5;
  colServerSid = 6;
  colServerSidRaw = 7;
  colCondition = 8;
  colAceFlags = 9;
  colObjectType = 10;
  colInheritedObjectType = 11;
  colSddl = 12;
  colMax = 13;

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
  AceType: TAceType
);

// Add ACE nodes to the ACL tree control
procedure UiLibAddAclNodes(
  Tree: TDevirtualizedTree;
  [opt] const Acl: IAcl;
  AccessMaskType: Pointer
);

// Check if an ACL requires canonicalization
function UiLibIsCanonicalAcl(
  Tree: TDevirtualizedTree
): Boolean;

procedure UiLibCanonicalizeAcl(
  Tree: TDevirtualizedTree
);

implementation

uses
  NtUtils.Security.Sid, NtUtils.Security, NtUtils.SysUtils,
  NtUiLib.Errors, VirtualTrees, DevirtualizedTree.Provider,
  DelphiUiLib.Reflection, DelphiUiLib.Strings, DelphiUiLib.Reflection.Strings,
  UI.Colors, UI.Helper, VirtualTrees.Types, Vcl.Graphics;

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
    FColumnText[colUse] := 'Resource Attribute'
  else if FAce.AceType = SYSTEM_SCOPED_POLICY_ID_ACE_TYPE then
    FColumnText[colUse] := 'Scoped Policy ID'
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
    FColumnText[colServerSid] := 'N/A';
    FColumnText[colServerSidRaw] := 'N/A';
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
    FColumnText[colObjectType] := '(none)';

  if (FAce.AceType in ObjectAces) and BitTest(FAce.ObjectFlags and 
    ACE_INHERITED_OBJECT_TYPE_PRESENT) then
    FColumnText[colInheritedObjectType] := RtlxGuidToString(
      FAce.InheritedObjectType)
  else
    FColumnText[colInheritedObjectType] := '(none)';

  if not AdvxAceToSddl(FAce, FColumnText[colSddl]).IsSuccess then
    FColumnText[colSddl] := '(invalid)';

  FHint := BuildHint([
    THintSection.New('Type', FColumnText[colAceType]),
    THintSection.New('Flags', FColumnText[colAceFlags]),
    THintSection.New('Access Mask', FColumnText[colAceAccessMask]),
    THintSection.New('SID', FColumnText[colSid]),
    THintSection.New('Condition', FColumnText[colCondition])    
  ]);

  FHasFontColor := BitTest(FAce.AceFlags and INHERIT_ONLY_ACE);
  FFontColor := clDkGray;

  FHasColor := True;
  if FAce.AceType in AccessAllowedAces then
    if BitTest(FAce.AceFlags and INHERITED_ACE) then
      FColor := ColorSettings.clEnabled
    else
      FColor := ColorSettings.clEnabledModified
  else if FAce.AceType in AccessDeniedAces then
    if BitTest(FAce.AceFlags and INHERITED_ACE) then
      FColor := ColorSettings.clDisabled
    else
      FColor := ColorSettings.clDisabledModified
  else
    if BitTest(FAce.AceFlags and INHERITED_ACE) then
      FColor := ColorSettings.clIntegrity
    else
      FColor := ColorSettings.clIntegrityModified
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
  if AceType in CallbackAces then
    Tree.Header.Columns[colCondition].Options :=
      Tree.Header.Columns[colCondition].Options + [coVisible]

  // Server SID for compound ACEs
  else if AceType = ACCESS_ALLOWED_COMPOUND_ACE_TYPE then
    Tree.Header.Columns[colServerSid].Options :=
      Tree.Header.Columns[colServerSid].Options + [coVisible];
end;

procedure UiLibAddAclNodes;
var
  i: Integer;
  Status: TNtxStatus;
  Aces: TArray<TAceData>;
begin
  Tree.BeginUpdateAuto;
  Tree.Clear;

  Status := RtlxDumpAcl(Acl, Aces);
  
  if Status.IsSuccess then
    Tree.NoItemsText := 'No items to display'
  else
  begin
    Tree.NoItemsText := Status.ToString;
    Exit;
  end;

  for i := 0 to High(Aces) do
  begin
    Tree.AddChildEx(nil, UiLibMakeAceNode(Aces[i], AccessMaskType));
    UiLibUnhideAceSpecificColumns(Tree, Aces[i].AceType);
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
  // Make rach category empty by default
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

end.
