unit UI.Prototypes.Privileges;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, Ntapi.WinNt, Ntapi.ntseapi, NtUtils, NtUtils.Lsa,
  DelphiUtils.Arrays;

const
  colFriendly = 0;
  colName = 1;
  colValue = 2;
  colState = 3;
  colDescription = 4;
  colIntegrity = 5;
  colMax = 6;

type
  TPrivilegeColoring = (pcStateBased, pcRemoved, pcNone);

  IPrivilege = interface (INodeData)
    ['{DC6BDFAD-2601-4402-933F-093C87406ED1}']
    function GetPrivilege: TPrivilege;
    procedure SetColoringMode(Mode: TPrivilegeColoring);
    property Privilege: TPrivilege read GetPrivilege;
    procedure Adjust(NewAttributes: TPrivilegeAttributes);
  end;

  TPrivilegeNodeData = class (TCustomNodeData, IPrivilege, INodeData)
    Privilege: TPrivilege;
    ColoringMode: TPrivilegeColoring;
    function GetPrivilege: TPrivilege;
    procedure SetColoringMode(Mode: TPrivilegeColoring);
    procedure Adjust(NewAttributes: TPrivilegeAttributes);
  public
    constructor Create(Privilege: TPrivilege; const hxPolicy: ILsaHandle = nil);
    class function CreateMany(const Privileges: TArray<TPrivilege>): TArray<IPrivilege>;
  end;

  TFramePrivileges = class(TFrame)
    VST: TVirtualStringTreeEx;
    procedure VSTChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
  private
    FColoringUnChecked, FCheckedColoring: TPrivilegeColoring;
    function NodeToPrivilege(const Node: PVirtualNode): TPrivilege;
    function NodeComparer(const Node: PVirtualNode): TCondition<PVirtualNode>;
    function ListSelected: TArray<TPrivilege>;
    function ListChecked: TArray<TPrivilege>;
    procedure SetChecked(const NewChecked: TArray<TPrivilege>);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Load(const New: TArray<TPrivilege>);
    procedure LoadEvery;
    procedure AdjustSelected(NewAttributes: TPrivilegeAttributes);
    property Selected: TArray<TPrivilege> read ListSelected;
    property Checked: TArray<TPrivilege> read ListChecked write SetChecked;
  published
    property ColoringUnChecked: TPrivilegeColoring read FColoringUnChecked write FColoringUnChecked default pcStateBased;
    property ColoringChecked: TPrivilegeColoring read FCheckedColoring write FCheckedColoring default pcStateBased;
  end;

implementation

uses
  Ntapi.ntlsa, DelphiUiLib.Strings, DelphiUiLib.Reflection.Strings,
  DelphiUiLib.Reflection.Numeric, UI.Colors, UI.Helper, VirtualTrees.Types;

{$R *.dfm}

function GetAllPrivileges: TArray<TPrivilege>;
const
  SE_MIN_WELL_KNOWN_PRIVILEGE = Integer(SE_CREATE_TOKEN_PRIVILEGE);
  SE_MAX_WELL_KNOWN_PRIVILEGE = Integer(High(TSeWellKnownPrivilege));
var
  New: TArray<TPrivilegeDefinition>;
  i: Integer;
begin
  if LsaxEnumeratePrivileges(New).IsSuccess then
  begin
    SetLength(Result, Length(New));

    // Copy LUIDs
    for i := 0 to High(New) do
      Result[i].Luid := New[i].LocalValue;
  end
  else
  begin
    // If privilege enumeration does not work, use the whole well-known range
    SetLength(Result, SE_MAX_WELL_KNOWN_PRIVILEGE -
      SE_MIN_WELL_KNOWN_PRIVILEGE + 1);

    for i := 0 to High(Result) do
      Result[i].Luid := SE_MIN_WELL_KNOWN_PRIVILEGE + i;
  end;

  // Only enable SeChangeNotifyPrivilege by default
  for i := 0 to High(Result) do
    with Result[i] do
      if Luid = TPrivilegeId(SE_CHANGE_NOTIFY_PRIVILEGE) then
        Attributes := SE_PRIVILEGE_ENABLED_BY_DEFAULT or SE_PRIVILEGE_ENABLED;
end;

{ TPrivilegeNodeData }

procedure TPrivilegeNodeData.Adjust;
begin
  Privilege.Attributes := NewAttributes;
  Cell[colState] := TNumeric.Represent(Privilege.Attributes).Text;

  SetColoringMode(ColoringMode);

  if Assigned(TreeView) and Assigned(Node) then
    TreeView.InvalidateNode(Node);
end;

constructor TPrivilegeNodeData.Create;
begin
  inherited Create(colMax);

  Self.Privilege := Privilege;
  Cell[colValue] := IntToStr(Privilege.Luid);
  Cell[colState] := TNumeric.Represent(Privilege.Attributes).Text;
  Cell[colIntegrity] := TNumeric.Represent(
    LsaxQueryIntegrityPrivilege(Privilege.Luid)).Text;

  // Try to query the name and the description from the system
  if LsaxQueryPrivilege(Privilege.Luid, Cell[colName], Cell[colDescription],
    hxPolicy).IsSuccess then
  begin
    Cell[colFriendly] := PrettifyCamelCase(Cell[colName], 'Se');

    Hint := BuildHint([
      THintSection.New('Friendly Name', Cell[colFriendly]),
      THintSection.New('Description', Cell[colDescription]),
      THintSection.New('Required Integrity', Cell[colIntegrity]),
      THintSection.New('Value', Cell[colValue])
    ]);
  end
  else
  begin
    // Otherwise, prepare names based on well-known privileges
    Cell[colFriendly] := TNumeric.Represent(TSeWellKnownPrivilege(
      Privilege.Luid)).Text;
  end;

  SetColoringMode(pcStateBased);
end;

class function TPrivilegeNodeData.CreateMany;
var
  hxPolicy: ILsaHandle;
  i: Integer;
begin
  LsaxOpenPolicy(hxPolicy, POLICY_LOOKUP_NAMES);
  SetLength(Result, Length(Privileges));

  for i := 0 to High(Privileges) do
    Result[i] := Create(Privileges[i], hxPolicy);
end;

function TPrivilegeNodeData.GetPrivilege;
begin
  Result := Privilege;
end;

procedure TPrivilegeNodeData.SetColoringMode;
begin
  ColoringMode := Mode;
  HasColor := Mode <> pcNone;

  case Mode of
    pcRemoved: Color := ColorSettings.clRemoved;
    pcStateBased:
      if BitTest(Privilege.Attributes and SE_PRIVILEGE_ENABLED) then
        if BitTest(Privilege.Attributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT) then
          Color := ColorSettings.clEnabled
        else
          Color := ColorSettings.clEnabledModified
      else
        if BitTest(Privilege.Attributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT) then
          Color := ColorSettings.clDisabledModified
        else
          Color := ColorSettings.clDisabled;
  end;

  if Assigned(TreeView) and Assigned(Node) then
    TreeView.InvalidateNode(Node);
end;

{ TFramePrivileges }

procedure TFramePrivileges.AdjustSelected;
var
  Node: PVirtualNode;
begin
  BeginUpdateAuto(VST);

  for Node in VST.SelectedNodes do
    IPrivilege(Node.GetINodeData).Adjust(NewAttributes);
end;

constructor TFramePrivileges.Create;
begin
  inherited;
  VST.UseINodeDataMode;
end;

function TFramePrivileges.ListChecked;
begin
  Result := TArray.Map<PVirtualNode, TPrivilege>(CollectNodes(VST.CheckedNodes),
    NodeToPrivilege);
end;

function TFramePrivileges.ListSelected;
begin
  Result := TArray.Map<PVirtualNode, TPrivilege>(
    CollectNodes(VST.SelectedNodes), NodeToPrivilege);
end;

procedure TFramePrivileges.Load;
var
  NodeData: IPrivilege;
begin
  BeginUpdateAuto(VST);
  BackupSelectionAuto(VST, NodeComparer);

  VST.RootNodeCount := 0;
  for NodeData in TPrivilegeNodeData.CreateMany(New) do
  begin
    if toCheckSupport in VST.TreeOptions.MiscOptions then
      NodeData.SetColoringMode(FColoringUnChecked);

    VST.AddChild(VST.RootNode).SetINodeData(NodeData);
  end;
end;

procedure TFramePrivileges.LoadEvery;
begin
  Load(GetAllPrivileges);
end;

function TFramePrivileges.NodeComparer;
var
  Luid: TPrivilegeId;
begin
  // We compare nodes via their LUIDs
  Luid := IPrivilege(Node.GetINodeData).Privilege.Luid;

  Result := function (const Node: PVirtualNode): Boolean
    begin
      Result := IPrivilege(Node.GetINodeData).Privilege.Luid = Luid;
    end;
end;

function TFramePrivileges.NodeToPrivilege;
begin
  Result := IPrivilege(Node.GetINodeData).Privilege;
end;

procedure TFramePrivileges.SetChecked;
var
  Node: PVirtualNode;
  Privilege: TPrivilege;
begin
  BeginUpdateAuto(VST);
  VST.ClearChecked;

  for Privilege in NewChecked do
    for Node in VST.Nodes do
      if IPrivilege(Node.GetINodeData).Privilege.Luid = Privilege.Luid then
      begin
        VST.CheckState[Node] := csCheckedNormal;
        Break;
      end;
end;

procedure TFramePrivileges.VSTChecked;
var
  Mode: TPrivilegeColoring;
begin
  if VST.CheckState[Node] = csCheckedNormal then
    Mode := FCheckedColoring
  else
    Mode := FColoringUnChecked;

  IPrivilege(Node.GetINodeData).SetColoringMode(Mode);
end;

end.
