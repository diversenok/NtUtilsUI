unit UI.Prototypes.Groups2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees, UI.Helper,
  NtUtils, DelphiUtils.Arrays, NtUtils.Lsa.Sid, Vcl.Menus, DelphiUtils.Events;

type
  TFrameGroups = class(TFrame)
    VST: TVirtualStringTree;
    DefaultPopupMenu: TPopupMenu;
    cmCopy: TMenuItem;
    cmCopyColumn: TMenuItem;
    cmSeparator: TMenuItem;
    cmInspect: TMenuItem;
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
    procedure VSTGetPopupMenu(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; const P: TPoint; var AskParent: Boolean;
      var PopupMenu: TPopupMenu);
    procedure cmCopyClick(Sender: TObject);
    procedure VSTKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cmCopyColumnClick(Sender: TObject);
    procedure VSTCompareNodes(Sender: TBaseVirtualTree; Node1,
      Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
    procedure cmInspectClick(Sender: TObject);
  private type
    TColumn = (colFriendly, colSid, colSidType, colFlags, colState);
    TGroupNodeData = record
      Group: TGroup;
      Cell: array [TColumn] of String;
      Hint: String;
      Color: TColor;
      constructor Create(const Src: TGroup; const Lookup: TTranslatedName);
      class function CreateMany(Src: TArray<TGroup>): TArray<TGroupNodeData>; static;
    end;
  private
    FGroups: TArray<TGroupNodeData>;
    FPopupColumn: TColumnIndex;
    FNodePopupMenu: TPopupMenu;
    FOnDefaultAction: TEventListener<TGroup>;
    FShortcuts: TArray<TMenuShortCut>;
    function NodeToGroup(const Node: PVirtualNode): TGroup;
    function NodeToColumnText(const Node: PVirtualNode): String;
    procedure SetNodePopupMenu(const Value: TPopupMenu);
    procedure SetCheckboxes(const Value: Boolean);
    function GetChechboxes: Boolean;
    function GetSelected: TArray<TGroup>;
    function GetChecked: TArray<TGroup>;
    procedure SetChecked(const Value: TArray<TGroup>);
    function GetIsChecked(Group: TGroup): Boolean;
    procedure SetIsChecked(Group: TGroup; const Value: Boolean);
    function GetAllGroups: TArray<TGroup>;
  public
    property Checkboxes: Boolean read GetChechboxes write SetCheckboxes;
    property Selected: TArray<TGroup> read GetSelected;
    property Checked: TArray<TGroup> read GetChecked write SetChecked;
    property Groups: TArray<TGroup> read GetAllGroups;
    property IsChecked[Group: TGroup]: Boolean read GetIsChecked write SetIsChecked;
    procedure Load(Groups: TArray<TGroup>);
    procedure Add(Groups: TArray<TGroup>);
    constructor Create(AOwner: TComponent); override;
  published
    property NodePopupMenu: TPopupMenu read FNodePopupMenu write SetNodePopupMenu;
    property OnDefaultAction: TEventListener<TGroup> read FOnDefaultAction write FOnDefaultAction;
  end;

implementation

uses
  Winapi.WinNt, Winapi.ntlsa, Ntapi.ntrtl, Ntapi.ntseapi, DelphiApi.Reflection,
  NtUtils.Security.Sid, NtUtils.Lsa, NtUtils.SysUtils,
  DelphiUiLib.Reflection.Strings, DelphiUiLib.Reflection.Numeric,
  NtUiLib.Reflection.Types,
  UI.Colors, Vcl.Clipbrd;

{$R *.dfm}

{ TFrameGroups.TGroupNodeData }

constructor TFrameGroups.TGroupNodeData.Create;
var
  HintSections: TArray<THintSection>;
begin
  Group := Src;
  Cell[colSid] := RtlxSidToString(Group.Sid.Data);

  if Lookup.SidType <> SidTypeUndefined then
    Cell[colSidType] := TNumeric.Represent(Lookup.SidType).Text;

  if Lookup.IsValid then
    Cell[colFriendly] := Lookup.FullName
  else
    Cell[colFriendly] := Cell[colSid];

  Cell[colFlags] := TNumeric.Represent<TGroupAttributes>(Group.Attributes and
    not SE_GROUP_STATE_MASK, [Auto.From(IgnoreSubEnumsAttribute.Create).Self]
  ).Text;

  Cell[colState] := TNumeric.Represent<TGroupAttributes>(Group.Attributes and
    SE_GROUP_STATE_MASK).Text;

  // Colors
  if BitTest(Group.Attributes and SE_GROUP_INTEGRITY_ENABLED) then
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

function GroupToSid(const Group: TGroup): PSid;
begin
  Result := Group.Sid.Data;
end;

class function TFrameGroups.TGroupNodeData.CreateMany;
var
  Lookup: TArray<TTranslatedName>;
  i: Integer;
begin
  // Lookup all SIDs at once to speed things up
  if not LsaxLookupSids(TArray.Map<TGroup, PSid>(Src, GroupToSid),
    Lookup).IsSuccess then
    SetLength(Lookup, Length(Src));

  SetLength(Result, Length(Src));
  for i := 0 to High(Src) do
    Result[i] := TGroupNodeData.Create(Src[i], Lookup[i]);
end;

{ TFrameGroups }

procedure TFrameGroups.Add;
begin
  BeginUpdateAuto(VST);
  FGroups := FGroups + TGroupNodeData.CreateMany(Groups);
  VST.RootNodeCount := VST.RootNodeCount + Length(Groups);
end;

procedure TFrameGroups.cmCopyClick(Sender: TObject);
begin
  VST.CopyToClipboard;
end;

procedure TFrameGroups.cmCopyColumnClick(Sender: TObject);
begin
  Clipboard.SetTextBuf(PWideChar(string.Join(#$D#$A,
    TArray.Map<PVirtualNode, String>(CollectNodes(VST.SelectedNodes),
      NodeToColumnText))));
end;

procedure TFrameGroups.cmInspectClick;
var
  Node: PVirtualNode;
begin
  if Assigned(FOnDefaultAction) and (VST.SelectedCount = 1) then
    for Node in VST.Nodes do
      if VST.Selected[Node] then
      begin
        FOnDefaultAction(FGroups[Node.GetData<Integer>].Group);
        Exit;
      end;
end;

constructor TFrameGroups.Create;
begin
  inherited Create(AOwner);

  // Populate the shortcut list with default popup menu
  NodePopupMenu := nil;
end;

function TFrameGroups.GetAllGroups: TArray<TGroup>;
begin
  Result := TArray.Map<TGroupNodeData, TGroup>(FGroups,
    function (const NodeData: TGroupNodeData): TGroup
    begin
      Result := NodeData.Group;
    end
  );
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
    if RtlEqualSid(FGroups[Node.GetData<Integer>].Group.Sid.Data,
      Group.Sid.Data) then
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
  VST.RootNodeCount := 0;
  FGroups := TGroupNodeData.CreateMany(Groups);
  VST.RootNodeCount := Length(Groups);
end;

function TFrameGroups.NodeToColumnText;
begin
  Result := VST.Text[Node, FPopupColumn];
end;

function TFrameGroups.NodeToGroup;
begin
  Result := FGroups[Node.GetData<Integer>].Group;
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
      if RtlEqualSid(FGroups[Node.GetData<Integer>].Group.Sid.Data,
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
    if RtlEqualSid(FGroups[Node.GetData<Integer>].Group.Sid.Data,
      Group.Sid.Data) then
    begin
      VST.CheckState[Node] := CHECKBOX_STATES[Value <> False];
      Break;
    end;
end;
procedure TFrameGroups.SetNodePopupMenu;
var
  NewParent: TPopupMenu;
begin
  FNodePopupMenu := Value;

  if Assigned(FNodePopupMenu) then
    NewParent := FNodePopupMenu
  else
    NewParent := DefaultPopupMenu;

  // Move predefined items
  cmInspect.SetParentComponent(NewParent);
  cmSeparator.SetParentComponent(NewParent);
  cmCopy.SetParentComponent(NewParent);
  cmCopyColumn.SetParentComponent(NewParent);

  // Find all shortcuts
  FShortcuts := TMenuShortCut.Collect(NewParent.Items);
end;

procedure TFrameGroups.VSTBeforeItemErase;
begin
  ItemColor := FGroups[Node.GetData<Integer>].Color;
end;

procedure TFrameGroups.VSTCompareNodes;
begin
  Result := RtlxCompareStrings(VST.Text[Node1, Column], VST.Text[Node2, Column])
end;

procedure TFrameGroups.VSTGetCellText;
begin
  E.CellText := FGroups[E.Node.GetData<Integer>].Cell[TColumn(E.Column)];
end;

procedure TFrameGroups.VSTGetHint;
begin
  HintText := FGroups[Node.GetData<Integer>].Hint;
end;

procedure TFrameGroups.VSTGetPopupMenu;
begin
  if VST.Header.InHeader(P) or (VST.SelectedCount = 0) then
    Exit;

  if Assigned(FNodePopupMenu) then
    PopupMenu := FNodePopupMenu
  else
    PopupMenu := DefaultPopupMenu;

  cmInspect.Visible := Assigned(FOnDefaultAction) and (VST.SelectedCount = 1);
  cmSeparator.Visible := Assigned(FNodePopupMenu) or cmInspect.Visible;

  // Column-specific copying
  FPopupColumn := Column;
  cmCopyColumn.Visible := Column >= 0;
  if cmCopyColumn.Visible then
    cmCopyColumn.Caption := 'Copy "' + VST.Header.Columns[Column].CaptionText +
      '"';
end;

procedure TFrameGroups.VSTInitNode;
begin
  Integer(Node.GetData^) := Node.Index;

  if toCheckSupport in VST.TreeOptions.MiscOptions then
    VST.CheckType[Node] := ctCheckBox;
end;

procedure TFrameGroups.VSTKeyDown;
var
  i: Integer;
begin
  for i := 0 to High(FShortcuts) do
    if (FShortcuts[i].ShiftState = Shift) and (FShortcuts[i].Key = Key) then
      FShortcuts[i].Menu.Click;
end;

end.
