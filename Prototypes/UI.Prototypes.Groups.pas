unit UI.Prototypes.Groups;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTrees.Types, UI.Helper, NtUtils, NtUtils.Lsa.Sid, Vcl.Menus,
  DelphiUtils.Arrays, Ntapi.ntseapi, VirtualTreesEx, VirtualTreesEx.NodeProvider;

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
    class function CreateMany(Src: TArray<TGroup>): TArray<INodeProvider>; static;
    function GetGroup: TGroup;
    function GetLookup: TTranslatedName;
    function Matches(const Sid: ISid): Boolean;
  end;

  TDefaultAction = procedure(const Group: TGroup) of object;

  TFrameGroups = class(TFrame)
    VST: TVirtualStringTreeEx;
  private
    FDefaultAction: TDefaultAction;
    function GetAllGroups: TArray<TGroup>;
    function GetChecked: TArray<TGroup>;
    function GetIsChecked(const Group: TGroup): Boolean;
    function GetSelected: TArray<TGroup>;
    function NodeComparer(const Node: PVirtualNode): TCondition<PVirtualNode>;
    function NodeToGroup(const Node: PVirtualNode): TGroup;
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

implementation

uses
  Ntapi.WinNt, Ntapi.ntlsa, Ntapi.ntrtl, DelphiApi.Reflection,
  NtUtils.Security.Sid, NtUtils.Lsa, NtUtils.SysUtils,
  DelphiUiLib.Reflection.Strings, DelphiUiLib.Reflection.Numeric,
  NtUiLib.Reflection.Types, UI.Colors;

{$R *.dfm}

{ TGroupNodeData }

constructor TGroupNodeData.Create;
var
  HintSections: TArray<THintSection>;
begin
  inherited Create(colMax);

  Group := Src;
  Lookup := LookupSrc;
  FColumns[colSid] := RtlxSidToString(Group.Sid);

  if Lookup.SidType <> SidTypeUndefined then
    FColumns[colSidType] := TNumeric.Represent(Lookup.SidType).Text;

  if Lookup.IsValid then
    FColumns[colFriendly] := Lookup.FullName
  else
    FColumns[colFriendly] := FColumns[colSid];

  FColumns[colFlags] := TNumeric.Represent<TGroupAttributes>(Group.Attributes and
    not SE_GROUP_STATE_MASK, [Auto.From(IgnoreSubEnumsAttribute.Create).Data]
  ).Text;

  FColumns[colState] := TNumeric.Represent<TGroupAttributes>(Group.Attributes and
    SE_GROUP_STATE_MASK).Text;

  // Colors
  FHasColor := True;
  if BitTest(Group.Attributes and SE_GROUP_INTEGRITY_ENABLED) then
    if BitTest(Group.Attributes and SE_GROUP_ENABLED) xor
      BitTest(Group.Attributes and SE_GROUP_ENABLED_BY_DEFAULT) then
      FColor := ColorSettings.clIntegrityModified
    else
      FColor := ColorSettings.clIntegrity
  else
    if BitTest(Group.Attributes and SE_GROUP_ENABLED) then
      if BitTest(Group.Attributes and SE_GROUP_ENABLED_BY_DEFAULT) then
        FColor := ColorSettings.clEnabled
      else
        FColor := ColorSettings.clEnabledModified
    else
      if BitTest(Group.Attributes and SE_GROUP_ENABLED_BY_DEFAULT) then
        FColor := ColorSettings.clDisabledModified
      else
        FColor := ColorSettings.clDisabled;

  // Hint
  HintSections := [
    THintSection.New('Friendly Name', FColumns[colFriendly]),
    THintSection.New('SID', FColumns[colSid]),
    THintSection.New('Type', FColumns[colSidType]),
    THintSection.New('State', FColumns[colState]),
    THintSection.New('Flags', FColumns[colFlags])
  ];

  // Show SID type only for successful lookups
  if Lookup.SidType = SidTypeUndefined then
    Delete(HintSections, 2, 1);

  // Do not include the friendly name if we don't have one
  if not Lookup.IsValid then
    Delete(HintSections, 0, 1);

  FHint := BuildHint(HintSections);
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
  BeginUpdateAuto(VST);

  for NewData in TGroupNodeData.CreateMany(Groups) do
    VST.AddChild(VST.RootNode).SetProvider(NewData);
end;

constructor TFrameGroups.Create;
begin
  inherited Create(AOwner);
  VST.UseINodeDataMode;
  VST.OnInspectNode := DoDefaultAction;
end;

procedure TFrameGroups.DoDefaultAction;
begin
  if Assigned(FDefaultAction) then
    FDefaultAction(IGroup(Node.GetProvider).GetGroup);
end;

procedure TFrameGroups.EditSelectedGroup;
var
  Node: PVirtualNode;
  NewGroup: TGroup;
  Lookup: TTranslatedName;
begin
  if VST.SelectedCount <> 1 then
    Exit;

  BeginUpdateAuto(VST);

  for Node in VST.SelectedNodes do
  begin
    NewGroup := IGroup(Node.GetProvider).GetGroup;
    Callback(NewGroup);

    // Reuse previous lookup if the SID haven't changed
    if IGroup(Node.GetProvider).Matches(NewGroup.Sid) then
      Lookup := IGroup(Node.GetProvider).GetLookup
    else if not LsaxLookupSid(NewGroup.Sid, Lookup).IsSuccess then
      Lookup := Default(TTranslatedName);

    Node.SetProvider(TGroupNodeData.Create(NewGroup, Lookup));
    VST.InvalidateNode(Node);
    Break;
  end;
end;

procedure TFrameGroups.EditSelectedGroups;
var
  Node: PVirtualNode;
  AttributesToClear: TGroupAttributes;
  AttributesToSet: TGroupAttributes;
  NewGroup: TGroup;
begin
  if VST.SelectedCount = 0 then
    Exit;

  AttributesToClear := 0;
  AttributesToSet := 0;
  Callback(Selected, AttributesToClear, AttributesToSet);

  BeginUpdateAuto(VST);

  for Node in VST.SelectedNodes do
  begin
    NewGroup := IGroup(Node.GetProvider).GetGroup;
    NewGroup.Attributes := (NewGroup.Attributes and not AttributesToClear)
      or AttributesToSet;

    // Reuse SID lookup
    Node.SetProvider(TGroupNodeData.Create(NewGroup,
      IGroup(Node.GetProvider).GetLookup));

    VST.InvalidateNode(Node);
  end;
end;

function TFrameGroups.GetAllGroups: TArray<TGroup>;
begin
  Result := TArray.Map<PVirtualNode, TGroup>(CollectNodes(VST.Nodes),
    NodeToGroup);
end;

function TFrameGroups.GetChecked;
begin
  Result := TArray.Map<PVirtualNode, TGroup>(CollectNodes(VST.CheckedNodes),
    NodeToGroup);
end;

function TFrameGroups.GetIsChecked;
var
  Node: PVirtualNode;
begin
  for Node in VST.Nodes do
    if IGroup(Node.GetProvider).Matches(Group.Sid) then
      Exit(VST.CheckState[Node] = csCheckedNormal);

  Result := False;
end;

function TFrameGroups.GetSelected;
begin
  Result := TArray.Map<PVirtualNode, TGroup>(CollectNodes(VST.SelectedNodes),
    NodeToGroup);
end;

procedure TFrameGroups.Load;
begin
  BeginUpdateAuto(VST);
  BackupSelectionAuto(VST, NodeComparer);
  VST.RootNodeCount := 0;
  Add(Groups);
end;

function TFrameGroups.NodeComparer;
var
  Sid: ISid;
begin
  // We compare nodes via their SIDs
  Sid := IGroup(Node.GetProvider).GetGroup.Sid;

  Result := function (const Node: PVirtualNode): Boolean
    begin
      Result := IGroup(Node.GetProvider).Matches(Sid);
    end;
end;

function TFrameGroups.NodeToGroup;
begin
  Result := IGroup(Node.GetProvider).GetGroup;
end;

procedure TFrameGroups.SetChecked;
var
  Node: PVirtualNode;
  NeedToCheck: Boolean;
  i: Integer;
begin
  for Node in VST.Nodes do
  begin
    NeedToCheck := False;

    for i := 0 to High(Value) do
      if IGroup(Node.GetProvider).Matches(Value[i].Sid) then
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
begin
  for Node in VST.Nodes do
    if IGroup(Node.GetProvider).Matches(Group.Sid) then
    begin
      if Value then
        VST.CheckState[Node] := csCheckedNormal
      else
        VST.CheckState[Node] := csUncheckedNormal;
    end;
end;

end.
