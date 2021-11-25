unit UI.Prototypes.Groups;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTrees.Types, UI.Helper, NtUtils, NtUtils.Lsa.Sid, Vcl.Menus,
  DelphiUtils.Events, DelphiUtils.Arrays, Ntapi.ntseapi, VirtualTreesEx;

type
  TEditGroupCallback = reference to procedure (var Group: TGroup);

  TEditAttributesCallback = reference to procedure (
    const Groups: TArray<TGroup>;
    var AttributesToClear: TGroupAttributes;
    var AttributesToSet: TGroupAttributes
  );

  TGroupColumn = (colFriendly, colSid, colSidType, colState, colFlags);

  TGroupNodeData = record
    Group: TGroup;
    Lookup: TTranslatedName;
    Cell: array [TGroupColumn] of String;
    Hint: String;
    Color: TColor;
    constructor Create(const Src: TGroup; const LookupSrc: TTranslatedName);
    class function CreateMany(Src: TArray<TGroup>): TArray<TGroupNodeData>; static;
  end;

  TFrameGroups = class(TFrame)
    VST: TVirtualStringTreeEx;
    procedure VSTGetHint(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; var LineBreakStyle: TVTTooltipLineBreakStyle;
      var HintText: string);
    procedure VSTGetCellText(Sender: TCustomVirtualStringTree;
      var E: TVSTGetCellTextEventArgs);
    procedure VSTInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure VSTBeforeItemErase(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; ItemRect: TRect;
      var ItemColor: TColor; var EraseAction: TItemEraseAction);
    procedure VSTCompareNodes(Sender: TBaseVirtualTree; Node1,
      Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
    procedure VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
 private
    FDefaultAction: TEventListener<TGroup>;
    function GetAllGroups: TArray<TGroup>;
    function GetChechboxes: Boolean;
    function GetChecked: TArray<TGroup>;
    function GetIsChecked(const Group: TGroup): Boolean;
    function GetSelected: TArray<TGroup>;
    function NodeComparer(const Node: PVirtualNode): TCondition<PVirtualNode>;
    function NodeToGroup(const Node: PVirtualNode): TGroup;
    procedure SetCheckboxes(const Value: Boolean);
    procedure SetChecked(const Value: TArray<TGroup>);
    procedure SetIsChecked(const Group: TGroup; const Value: Boolean);
    function GetNodePopup: TPopupMenu;
    procedure SetNodePopupMenu(const Value: TPopupMenu);
    procedure DoDefaultAction(Node: PVirtualNode);
  public
    procedure Load(Groups: TArray<TGroup>);
    procedure Add(Groups: TArray<TGroup>);
    procedure EditSelectedGroup(Callback: TEditGroupCallback);
    procedure EditSelectedGroups(Callback: TEditAttributesCallback);
    procedure RemoveSelected;
    property All: TArray<TGroup> read GetAllGroups;
    property Selected: TArray<TGroup> read GetSelected;
    property Checked: TArray<TGroup> read GetChecked write SetChecked;
    property IsChecked[const Group: TGroup]: Boolean read GetIsChecked write SetIsChecked;
    constructor Create(AOwner: TComponent); override;
  published
    property Checkboxes: Boolean read GetChechboxes write SetCheckboxes;
    property NodePopupMenu: TPopupMenu read GetNodePopup write SetNodePopupMenu;
    property OnDefaultAction: TEventListener<TGroup> read FDefaultAction write FDefaultAction;
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
  Group := Src;
  Lookup := LookupSrc;
  Cell[colSid] := RtlxSidToString(Group.Sid);

  if Lookup.SidType <> SidTypeUndefined then
    Cell[colSidType] := TNumeric.Represent(Lookup.SidType).Text;

  if Lookup.IsValid then
    Cell[colFriendly] := Lookup.FullName
  else
    Cell[colFriendly] := Cell[colSid];

  Cell[colFlags] := TNumeric.Represent<TGroupAttributes>(Group.Attributes and
    not SE_GROUP_STATE_MASK, [Auto.From(IgnoreSubEnumsAttribute.Create).Data]
  ).Text;

  Cell[colState] := TNumeric.Represent<TGroupAttributes>(Group.Attributes and
    SE_GROUP_STATE_MASK).Text;

  // Colors
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
    THintSection.New('Friendly Name', Cell[colFriendly]),
    THintSection.New('SID', Cell[colSid]),
    THintSection.New('Type', Cell[colSidType]),
    THintSection.New('State', Cell[colState]),
    THintSection.New('Flags', Cell[colFlags])
  ];

  // Show SID type only for successful lookups
  if Lookup.SidType = SidTypeUndefined then
    Delete(HintSections, 2, 1);

  // Do not include the friendly name if we don't have one
  if not Lookup.IsValid then
    Delete(HintSections, 0, 1);

  Hint := BuildHint(HintSections);
end;

function GroupToSid(const Group: TGroup): ISid;
begin
  Result := Group.Sid;
end;

class function TGroupNodeData.CreateMany;
var
  Lookup: TArray<TTranslatedName>;
  i: Integer;
begin
  // Lookup all SIDs at once to speed things up
  if not LsaxLookupSids(TArray.Map<TGroup, ISid>(Src, GroupToSid),
    Lookup).IsSuccess then
    SetLength(Lookup, Length(Src));

  SetLength(Result, Length(Src));
  for i := 0 to High(Src) do
    Result[i] := TGroupNodeData.Create(Src[i], Lookup[i]);
end;

{ TFrameGroups }

procedure TFrameGroups.Add;
var
  i: Integer;
  NewData: TArray<TGroupNodeData>;
begin
  NewData := TGroupNodeData.CreateMany(Groups);
  BeginUpdateAuto(VST);

  for i := 0 to High(NewData) do
    TGroupNodeData(VST.AddChild(VST.RootNode).GetData^) := NewData[i];
end;

constructor TFrameGroups.Create;
begin
  inherited Create(AOwner);
  VST.NodeDataSize := SizeOf(TGroupNodeData);
  VST.RootNodeCount := 0;
  VST.OnInspectNode := DoDefaultAction;
end;

procedure TFrameGroups.DoDefaultAction;
begin
  if Assigned(FDefaultAction) then
    FDefaultAction(TGroupNodeData(Node.GetData^).Group);
end;

procedure TFrameGroups.EditSelectedGroup;
var
  Node: PVirtualNode;
  NewGroup: TGroup;
  Lookup: TTranslatedName;
begin
  if VST.SelectedCount <> 1 then
    Exit;

  for Node in VST.SelectedNodes do
  begin
    NewGroup := TGroupNodeData(Node.GetData^).Group;
    Callback(NewGroup);

    if not RtlEqualSid(TGroupNodeData(Node.GetData^).Group.Sid.Data,
      NewGroup.Sid.Data) then
    begin
      // We got a new SID, look it up
      if not LsaxLookupSid(NewGroup.Sid, Lookup).IsSuccess then
        Lookup := Default(TTranslatedName);

      TGroupNodeData(Node.GetData^) := TGroupNodeData.Create(NewGroup, Lookup);
    end
    else
    begin
      // We can reuse lookup since we only need to update attributes
      TGroupNodeData(Node.GetData^).Group.Attributes := NewGroup.Attributes;
      TGroupNodeData(Node.GetData^) := TGroupNodeData.Create(NewGroup,
        TGroupNodeData(Node.GetData^).Lookup);
    end;

    VST.InvalidateNode(Node);
    Break;
  end;
end;

procedure TFrameGroups.EditSelectedGroups;
var
  Node: PVirtualNode;
  AttributesToClear: TGroupAttributes;
  AttributesToSet: TGroupAttributes;
begin
  if VST.SelectedCount = 0 then
    Exit;

  AttributesToClear := 0;
  AttributesToSet := 0;
  Callback(Selected, AttributesToClear, AttributesToSet);

  BeginUpdateAuto(VST);

  for Node in VST.SelectedNodes do
  begin
    // Adjust atrributes and reuse SID lookup
    TGroupNodeData(Node.GetData^).Group.Attributes :=
      (TGroupNodeData(Node.GetData^).Group.Attributes and not AttributesToClear)
      or AttributesToSet;

    TGroupNodeData(Node.GetData^) := TGroupNodeData.Create(
      TGroupNodeData(Node.GetData^).Group,
      TGroupNodeData(Node.GetData^).Lookup
    );

    VST.InvalidateNode(Node);
  end;
end;

function TFrameGroups.GetAllGroups: TArray<TGroup>;
begin
  Result := TArray.Map<PVirtualNode, TGroup>(CollectNodes(VST.Nodes),
    NodeToGroup);
end;

function TFrameGroups.GetChechboxes;
begin
  Result := toCheckSupport in VST.TreeOptions.MiscOptions;
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
    if RtlEqualSid(TGroupNodeData(Node.GetData^).Group.Sid.Data,
      Group.Sid.Data) then
      Exit(VST.CheckState[Node] = csCheckedNormal);

  Result := False;
end;

function TFrameGroups.GetNodePopup;
begin
  Result := VST.NodePopupMenu;
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
  Sid := TGroupNodeData(Node.GetData^).Group.Sid;

  Result := function (const Node: PVirtualNode): Boolean
    begin
      Result := RtlEqualSid(Sid.Data,
        TGroupNodeData(Node.GetData^).Group.Sid.Data);
    end;
end;

function TFrameGroups.NodeToGroup;
begin
  Result := TGroupNodeData(Node.GetData^).Group;
end;

procedure TFrameGroups.RemoveSelected;
begin
  BeginUpdateAuto(VST);
  VST.DeleteSelectedNodes;
end;

procedure TFrameGroups.SetCheckboxes;
const
  CHECKBOX_TYPE: array [Boolean] of TCheckType = (ctNone, ctCheckBox);
var
  Node: PVirtualNode;
begin
  if Value then
    VST.TreeOptions.MiscOptions := VST.TreeOptions.MiscOptions + [toCheckSupport]
  else
    VST.TreeOptions.MiscOptions := VST.TreeOptions.MiscOptions - [toCheckSupport];

  for Node in VST.Nodes do
    VST.CheckType[Node] := CHECKBOX_TYPE[Value <> False];
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
      if RtlEqualSid(TGroupNodeData(Node.GetData^).Group.Sid.Data,
        Value[i].Sid.Data) then
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
const
  CHECKBOX_STATES: array [Boolean] of TCheckState = (
    csUncheckedNormal, csCheckedNormal
  );
var
  Node: PVirtualNode;
begin
  for Node in VST.Nodes do
    if RtlEqualSid(TGroupNodeData(Node.GetData^).Group.Sid.Data,
      Group.Sid.Data) then
    begin
      VST.CheckState[Node] := CHECKBOX_STATES[Value <> False];
      Break;
    end;
end;

procedure TFrameGroups.SetNodePopupMenu;
begin
  VST.NodePopupMenu := Value;
end;

procedure TFrameGroups.VSTBeforeItemErase;
begin
  ItemColor := TGroupNodeData(Node.GetData^).Color;
end;

procedure TFrameGroups.VSTCompareNodes;
begin
  Result := RtlxCompareStrings(VST.Text[Node1, Column], VST.Text[Node2, Column])
end;

procedure TFrameGroups.VSTFreeNode;
begin
  Finalize(TGroupNodeData(Node.GetData^));
end;

procedure TFrameGroups.VSTGetCellText;
begin
  E.CellText := TGroupNodeData(E.Node.GetData^).Cell[TGroupColumn(E.Column)];
end;

procedure TFrameGroups.VSTGetHint;
begin
  HintText := TGroupNodeData(Node.GetData^).Hint;
end;

procedure TFrameGroups.VSTInitNode;
begin
  if toCheckSupport in VST.TreeOptions.MiscOptions then
    VST.CheckType[Node] := ctCheckBox;
end;

end.
