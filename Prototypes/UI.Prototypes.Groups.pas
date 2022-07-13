unit UI.Prototypes.Groups;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTrees.Types, UI.Helper, NtUtils, NtUtils.Lsa.Sid, Vcl.Menus,
  DelphiUtils.Arrays, Ntapi.ntseapi, DevirtualizedTree,
  DevirtualizedTree.Provider, VirtualTreesEx;

const
  colFriendly = 0;
  colSid = 1;
  colSidType = 2;
  colState = 3;
  colFlags = 4;
  colMax = 5;

type
  TEditGroupCallback = reference to procedure (var Group: TGroup);

  TEditAttributesCallback = reference to procedure (
    const Groups: TArray<TGroup>;
    var AttributesToClear: TGroupAttributes;
    var AttributesToSet: TGroupAttributes
  );

  IGroup = interface (INodeProvider)
    ['{1D70B85E-99E9-4F21-B298-8928AD2DBDAE}']
    function GetGroup: TGroup;
    function GetLookup: TTranslatedName;
    function Matches(const Sid: ISid): Boolean;
  end;

  TGroupNodeData = class (TCustomNodeProvider, IGroup, INodeProvider)
    Group: TGroup;
    Lookup: TTranslatedName;
    constructor Create(const Src: TGroup; const LookupSrc: TTranslatedName);
    class function CreateMany(const Src: TArray<TGroup>): TArray<INodeProvider>; static;
    function GetGroup: TGroup;
    function GetLookup: TTranslatedName;
    function Matches(const Sid: ISid): Boolean;
  end;

  TDefaultAction = procedure(const Group: TGroup) of object;

  TFrameGroups = class(TFrame)
    VST: TDevirtualizedTree;
  private
    FDefaultAction: TDefaultAction;
    function GetAllGroups: TArray<TGroup>;
    function GetChecked: TArray<TGroup>;
    function GetIsChecked(const Group: TGroup): Boolean;
    function GetSelected: TArray<TGroup>;
    function NodeComparer(const Node: PVirtualNode): TCondition<PVirtualNode>;
    function NodeToGroup(const Node: PVirtualNode; out Group: TGroup): Boolean;
    procedure SetChecked(const Value: TArray<TGroup>);
    procedure SetIsChecked(const Group: TGroup; const Value: Boolean);
    procedure DoDefaultAction(Node: PVirtualNode);
  public
    procedure Load(Groups: TArray<TGroup>);
    procedure Add(Groups: TArray<TGroup>);
    procedure EditSelectedGroup(Callback: TEditGroupCallback);
    procedure EditSelectedGroups(Callback: TEditAttributesCallback);
    property All: TArray<TGroup> read GetAllGroups;
    property Selected: TArray<TGroup> read GetSelected;
    property Checked: TArray<TGroup> read GetChecked write SetChecked;
    property IsChecked[const Group: TGroup]: Boolean read GetIsChecked write SetIsChecked;
    constructor Create(AOwner: TComponent); override;
  published
    property OnDefaultAction: TDefaultAction read FDefaultAction write FDefaultAction;
  end;

// Helper converter
function GroupsToSids(
  const Groups: TArray<TGroup>
): TArray<ISid>;

implementation

uses
  Ntapi.WinNt, Ntapi.ntlsa, Ntapi.ntrtl, DelphiApi.Reflection,
  NtUtils.Security.Sid, NtUtils.Lsa, NtUtils.SysUtils,
  DelphiUiLib.Reflection.Strings, DelphiUiLib.Reflection.Numeric,
  NtUiLib.Reflection.Types, UI.Colors;

{$R *.dfm}

function GroupsToSids;
var
  i: Integer;
begin
  SetLength(Result, Length(Groups));

  for i := 0 to High(Groups) do
    Result[i] := Groups[i].Sid;
end;

{ TGroupNodeData }

constructor TGroupNodeData.Create;
var
  HintSections: TArray<THintSection>;
begin
  inherited Create(colMax);

  Group := Src;
  Lookup := LookupSrc;
  Cells[colSid] := RtlxSidToString(Group.Sid);

  if Lookup.SidType <> SidTypeUndefined then
    Cells[colSidType] := TNumeric.Represent(Lookup.SidType).Text;

  if Lookup.IsValid then
    Cells[colFriendly] := Lookup.FullName
  else
    Cells[colFriendly] := Cells[colSid];

  Cells[colFlags] := TNumeric.Represent<TGroupAttributes>(Group.Attributes and
    not SE_GROUP_STATE_MASK, [Auto.From(IgnoreSubEnumsAttribute.Create).Self]
  ).Text;

  Cells[colState] := TNumeric.Represent<TGroupAttributes>(Group.Attributes and
    SE_GROUP_STATE_MASK).Text;

  // Colors
  HasColor := True;
  if BitTest(Group.Attributes and SE_GROUP_INTEGRITY_ENABLED) then
    if BitTest(Group.Attributes and SE_GROUP_ENABLED) xor
      BitTest(Group.Attributes and SE_GROUP_ENABLED_BY_DEFAULT) then
      Color := ColorSettings.clIntegrityModified
    else
      Color := ColorSettings.clIntegrity
  else
    if BitTest(Group.Attributes and SE_GROUP_ENABLED) then
      if BitTest(Group.Attributes and SE_GROUP_ENABLED_BY_DEFAULT) then
        Color := ColorSettings.clEnabled
      else
        Color := ColorSettings.clEnabledModified
    else
      if BitTest(Group.Attributes and SE_GROUP_ENABLED_BY_DEFAULT) then
        Color := ColorSettings.clDisabledModified
      else
        Color := ColorSettings.clDisabled;

  // Hint
  HintSections := [
    THintSection.New('Friendly Name', Cells[colFriendly]),
    THintSection.New('SID', Cells[colSid]),
    THintSection.New('Type', Cells[colSidType]),
    THintSection.New('State', Cells[colState]),
    THintSection.New('Flags', Cells[colFlags])
  ];

  // Show SID type only for successful lookups
  if Lookup.SidType = SidTypeUndefined then
    Delete(HintSections, 2, 1);

  // Do not include the friendly name if we don't have one
  if not Lookup.IsValid then
    Delete(HintSections, 0, 1);

  Hint := BuildHint(HintSections);
end;

class function TGroupNodeData.CreateMany;
var
  Sids: TArray<ISid>;
  Lookup: TArray<TTranslatedName>;
  i: Integer;
begin
  SetLength(Sids, Length(Src));
  for i := 0 to High(Sids) do
    Sids[i] := Src[i].Sid;

  // Lookup all SIDs at once to speed things up
  if not LsaxLookupSids(Sids, Lookup).IsSuccess then
    SetLength(Lookup, Length(Src));

  SetLength(Result, Length(Src));
  for i := 0 to High(Src) do
    Result[i] := TGroupNodeData.Create(Src[i], Lookup[i]);
end;

function TGroupNodeData.GetGroup;
begin
  Result := Group;
end;

function TGroupNodeData.GetLookup;
begin
  Result := Lookup;
end;

function TGroupNodeData.Matches;
begin
  Result := RtlEqualSid(Group.Sid.Data, Sid.Data);
end;

{ TFrameGroups }

procedure TFrameGroups.Add;
var
  NewData: INodeProvider;
begin
  VST.BeginUpdateAuto;

  for NewData in TGroupNodeData.CreateMany(Groups) do
    VST.AddChild(VST.RootNode, NewData);
end;

constructor TFrameGroups.Create;
begin
  inherited Create(AOwner);
  VST.OnInspectNode := DoDefaultAction;
end;

procedure TFrameGroups.DoDefaultAction;
var
  GroupProvider: IGroup;
begin
  if Assigned(FDefaultAction) and Node.TryGetProvider(IGroup,
    GroupProvider) then
    FDefaultAction(GroupProvider.GetGroup);
end;

procedure TFrameGroups.EditSelectedGroup;
var
  Node: PVirtualNode;
  Provider: IGroup;
  NewGroup: TGroup;
  Lookup: TTranslatedName;
begin
  if VST.SelectedCount <> 1 then
    Exit;

  VST.BeginUpdateAuto;
  Node := VST.FocusedNode;

  if not Node.TryGetProvider(IGroup, Provider) then
    Exit;

  NewGroup := Provider.GetGroup;
  Callback(NewGroup);

  // Reuse previous lookup if the SID haven't changed
  if Provider.Matches(NewGroup.Sid) then
    Lookup := Provider.GetLookup
  else if not LsaxLookupSid(NewGroup.Sid, Lookup).IsSuccess then
    Lookup := Default(TTranslatedName);

  Node.Provider := TGroupNodeData.Create(NewGroup, Lookup);
  VST.InvalidateNode(Node);
end;

procedure TFrameGroups.EditSelectedGroups;
var
  Node: PVirtualNode;
  Provider: IGroup;
  AttributesToClear: TGroupAttributes;
  AttributesToSet: TGroupAttributes;
  NewGroup: TGroup;
begin
  if VST.SelectedCount = 0 then
    Exit;

  AttributesToClear := 0;
  AttributesToSet := 0;
  Callback(Selected, AttributesToClear, AttributesToSet);

  VST.BeginUpdateAuto;

  for Node in VST.SelectedNodes do
  begin
    if not Node.TryGetProvider(IGroup, Provider) then
      Continue;

    NewGroup := Provider.GetGroup;
    NewGroup.Attributes := (NewGroup.Attributes and not AttributesToClear) or
      AttributesToSet;

    // Reuse SID lookup
    Node.Provider := TGroupNodeData.Create(NewGroup, Provider.GetLookup);

    VST.InvalidateNode(Node);
  end;
end;

function TFrameGroups.GetAllGroups;
begin
  Result := TArray.Convert<PVirtualNode, TGroup>(VST.Nodes.ToArray,
    NodeToGroup);
end;

function TFrameGroups.GetChecked;
begin
  Result := TArray.Convert<PVirtualNode, TGroup>(VST.CheckedNodes.ToArray,
    NodeToGroup);
end;

function TFrameGroups.GetIsChecked;
var
  Node: PVirtualNode;
  Provider: IGroup;
begin
  for Node in VST.Nodes do
    if Node.TryGetProvider(IGroup, Provider) and Provider.Matches(Group.Sid) then
      Exit(VST.CheckState[Node] = csCheckedNormal);

  Result := False;
end;

function TFrameGroups.GetSelected;
begin
  Result := TArray.Convert<PVirtualNode, TGroup>(VST.SelectedNodes.ToArray,
    NodeToGroup);
end;

procedure TFrameGroups.Load;
begin
  VST.BeginUpdateAuto;
  VST.BackupSelectionAuto(NodeComparer);
  VST.RootNodeCount := 0;
  Add(Groups);
end;

function TFrameGroups.NodeComparer;
var
  Provider: IGroup;
  Sid: ISid;
begin
  if Node.TryGetProvider(IGroup, Provider) then
  begin
    // We compare nodes via their SIDs
    Sid := Provider.GetGroup.Sid;

    Result := function (const Node: PVirtualNode): Boolean
    var
      Provider: IGroup;
    begin
      Result := Node.TryGetProvider(IGroup, Provider) and Provider.Matches(Sid);
    end;
  end
  else
    Result := nil;
end;

function TFrameGroups.NodeToGroup;
var
  Provider: IGroup;
begin
  Result := Node.TryGetProvider(IGroup, Provider);

  if Result then
    Group := Provider.GetGroup;
end;

procedure TFrameGroups.SetChecked;
var
  Node: PVirtualNode;
  Provider: IGroup;
  NeedToCheck: Boolean;
  i: Integer;
begin
  for Node in VST.Nodes do
  begin
    NeedToCheck := False;

    for i := 0 to High(Value) do
      if Node.TryGetProvider(IGroup, Provider) and
        Provider.Matches(Value[i].Sid) then
      begin
        NeedToCheck := True;
        Break;
      end;

    if NeedToCheck then
      VST.CheckState[Node] := csCheckedNormal
    else
      VST.CheckState[Node] := csUncheckedNormal;
  end;
end;

procedure TFrameGroups.SetIsChecked;
var
  Node: PVirtualNode;
  Provider: IGroup;
begin
  for Node in VST.Nodes do
    if Node.TryGetProvider(IGroup, Provider) and
      Provider.Matches(Group.Sid) then
    begin
      if Value then
        VST.CheckState[Node] := csCheckedNormal
      else
        VST.CheckState[Node] := csUncheckedNormal;
    end;
end;

end.
