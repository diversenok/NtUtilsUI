unit UI.Prototypes.Privileges;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.Tree, Ntapi.WinNt, Ntapi.ntseapi, NtUtils,
  NtUtils.Lsa, DelphiUtils.Arrays;

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

  IPrivilege = interface (INodeProvider)
    ['{660DF981-AC29-46FA-8E32-E88A60622CC6}']
    function GetPrivilege: TPrivilege;
    procedure SetColoringMode(Mode: TPrivilegeColoring);
    property Privilege: TPrivilege read GetPrivilege;
    procedure Adjust(NewAttributes: TPrivilegeAttributes);
  end;

  TFramePrivileges = class(TFrame)
    VST: TUiLibTree;
    procedure VSTChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
  private
    FColoringUnChecked, FCheckedColoring: TPrivilegeColoring;
    function NodeToPrivilege(
      const Node: PVirtualNode;
      out Privilege: TPrivilege
    ): Boolean;
    function ListSelected: TArray<TPrivilege>;
    function ListChecked: TArray<TPrivilege>;
    procedure SetChecked(const NewChecked: TArray<TPrivilege>);
  public
    procedure Load(const New: TArray<TPrivilege>);
    procedure LoadEvery;
    procedure AdjustSelected(NewAttributes: TPrivilegeAttributes);
    property Selected: TArray<TPrivilege> read ListSelected;
    property Checked: TArray<TPrivilege> read ListChecked write SetChecked;
  published
    property ColoringUnChecked: TPrivilegeColoring read FColoringUnChecked write FColoringUnChecked default pcStateBased;
    property ColoringChecked: TPrivilegeColoring read FCheckedColoring write FCheckedColoring default pcStateBased;
  end;

// Helper converter
function PrivilegesToIDs(
  const Privileges: TArray<TPrivilege>
): TArray<TPrivilegeId>;

implementation

uses
  Ntapi.ntlsa, DelphiUiLib.Strings, DelphiUiLib.LiteReflection,
  NtUtilsUI, VirtualTrees.Types, NtUtils.SysUtils;

{$R *.dfm}

function PrivilegesToIDs;
var
  i: Integer;
begin
  SetLength(Result, Length(Privileges));

  for i := 0 to High(Privileges) do
    Result[i] := Privileges[i].Luid;
end;

{ TPrivilegeNodeData }

type
  TPrivilegeNodeData = class (TNodeProvider, IPrivilege, INodeProvider)
    Privilege: TPrivilege;
    ColoringMode: TPrivilegeColoring;
    function GetPrivilege: TPrivilege;
    procedure SetColoringMode(Mode: TPrivilegeColoring);
    procedure Adjust(NewAttributes: TPrivilegeAttributes);
  protected
    function SameEntity(Node: INodeProvider): Boolean; override;
  public
    constructor Create(Privilege: TPrivilege; const hxPolicy: ILsaHandle = nil);
    class function CreateMany(const Privileges: TArray<TPrivilege>): TArray<IPrivilege>;
  end;

procedure TPrivilegeNodeData.Adjust;
begin
  Privilege.Attributes := NewAttributes;
  FColumnText[colState] := Rttix.Format<TPrivilegeAttributesState>(
    Privilege.Attributes);

  SetColoringMode(ColoringMode);
  Invalidate;
end;

constructor TPrivilegeNodeData.Create;
begin
  inherited Create(colMax);

  Self.Privilege := Privilege;
  FColumnText[colValue] := IntToStr(Privilege.Luid);
  FColumnText[colState] := Rttix.Format<TPrivilegeAttributesState>(
    Privilege.Attributes);
  FColumnText[colIntegrity] := Rttix.Format(
    LsaxQueryIntegrityPrivilege(Privilege.Luid));

  // Try to query the name and the description from the system
  if LsaxQueryPrivilege(Privilege.Luid, FColumnText[colName],
    FColumnText[colDescription], hxPolicy).IsSuccess then
  begin
    FColumnText[colFriendly] := FColumnText[colName];
    RtlxPrefixStripString('Se', FColumnText[colFriendly], True);
    FColumnText[colFriendly] := RtlxPrettifyIdentifier(FColumnText[colFriendly]);

    FHint := BuildHint([
      THintSection.New('Friendly Name', FColumnText[colFriendly]),
      THintSection.New('Description', FColumnText[colDescription]),
      THintSection.New('Required Integrity', FColumnText[colIntegrity]),
      THintSection.New('Value', FColumnText[colValue])
    ]);
  end
  else
  begin
    // Otherwise, prepare names based on well-known privileges
    FColumnText[colFriendly] := Rttix.Format(Privilege.Luid);
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

function TPrivilegeNodeData.SameEntity;
var
  AnotherPrivilege: IPrivilege;
begin
  Result := (Node.QueryInterface(IPrivilege, AnotherPrivilege) = S_OK)
   and (AnotherPrivilege.Privilege.Luid = Privilege.Luid);
end;

procedure TPrivilegeNodeData.SetColoringMode;
begin
  ColoringMode := Mode;

  if BitTest(Privilege.Attributes and SE_PRIVILEGE_ENABLED) then
    if BitTest(Privilege.Attributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT) then
      SetColor(ColorSettings.clBackgroundAllow)
    else
      SetColor(ColorSettings.clBackgroundAllowAccent)
  else
    if BitTest(Privilege.Attributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT) then
      SetColor(ColorSettings.clBackgroundDenyAccent)
    else
      SetColor(ColorSettings.clBackgroundDeny);

  if Mode = pcRemoved then
  begin
    SetFontColor(ColorSettings.clForegroundInactive);
    SetFontStyle([fsStrikeOut]);
  end
  else
  begin
    ResetFontColor;
    ResetFontStyle;
  end;

  Invalidate;
end;

{ TFramePrivileges }

procedure TFramePrivileges.AdjustSelected;
var
  Node: PVirtualNode;
  Provider: IPrivilege;
begin
  VST.BeginUpdateAuto;

  for Node in VST.SelectedNodes do
    if Node.TryGetProvider(IPrivilege, Provider) then
      Provider.Adjust(NewAttributes);
end;

function TFramePrivileges.ListChecked;
begin
  Result := TArray.Convert<PVirtualNode, TPrivilege>(VST.CheckedNodes.Nodes,
    NodeToPrivilege);
end;

function TFramePrivileges.ListSelected;
begin
  Result := TArray.Convert<PVirtualNode, TPrivilege>(VST.SelectedNodes.Nodes,
    NodeToPrivilege);
end;

procedure TFramePrivileges.Load;
var
  NodeData: IPrivilege;
begin
  VST.BeginUpdateAuto;
  VST.BackupSelectionAuto;

  VST.RootNodeCount := 0;
  for NodeData in TPrivilegeNodeData.CreateMany(New) do
  begin
    VST.AddChild(NodeData);

    if toCheckSupport in VST.TreeOptions.MiscOptions then
    begin
      NodeData.SetColoringMode(FColoringUnChecked);
      VST.CheckType[NodeData.Node] := ctCheckBox;
    end;
  end;
end;

procedure TFramePrivileges.LoadEvery;
var
  AllPrivileges: TArray<TPrivilege>;
  SeChangeNotify: TPrivilege;
begin
  AllPrivileges := TArray.Map<TLuid, TPrivilege>(
    LsaxEnumeratePrivilegesWithFallback,
    function (const Luid: TLuid): TPrivilege
    begin
      Result.Luid := Luid;
      Result.Attributes := SE_PRIVILEGE_ENABLED or
        SE_PRIVILEGE_ENABLED_BY_DEFAULT
    end
  );

  Load(AllPrivileges);

  // Check only SeChangeNotify by default
  SeChangeNotify.Luid := TLuid(SE_CHANGE_NOTIFY_PRIVILEGE);
  SeChangeNotify.Attributes := SE_PRIVILEGE_ENABLED or
    SE_PRIVILEGE_ENABLED_BY_DEFAULT;
  Checked := [SeChangeNotify];
end;

function TFramePrivileges.NodeToPrivilege;
var
  Provider: IPrivilege;
begin
  Result := Node.TryGetProvider(IPrivilege, Provider);

  if Result then
    Privilege := Provider.Privilege;
end;

procedure TFramePrivileges.SetChecked;
var
  Node: PVirtualNode;
  Provider: IPrivilege;
  Privilege: TPrivilege;
begin
  VST.BeginUpdateAuto;
  VST.ClearChecked;

  for Privilege in NewChecked do
    for Node in VST.Nodes do
      if Node.TryGetProvider(IPrivilege, Provider) and
        (Provider.Privilege.Luid = Privilege.Luid) then
      begin
        VST.CheckState[Node] := csCheckedNormal;
        Break;
      end;
end;

procedure TFramePrivileges.VSTChecked;
var
  Provider: IPrivilege;
  Mode: TPrivilegeColoring;
begin
  if VST.CheckState[Node] = csCheckedNormal then
    Mode := FCheckedColoring
  else
    Mode := FColoringUnChecked;

  if Node.TryGetProvider(IPrivilege, Provider) then
    Provider.SetColoringMode(Mode);
end;

end.
