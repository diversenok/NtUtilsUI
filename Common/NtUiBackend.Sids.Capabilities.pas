unit NtUiBackend.Sids.Capabilities;

{
  This module provides logic for the capability list dialog
}

interface

uses
  DevirtualizedTree, NtUtils;

const
  colName = 0;
  colAppSid = 1;
  colGroupSid = 2;
  colMax = 3;

type
  TCapabilityCategory = (
    ccBuiltin,
    ccLpac,
    ccAppSilo,
    ccNormal,
    ccVendor,
    ccLegacy
  );

  ICapabilityGroupNode = interface (INodeProvider)
    ['{A3D7BD74-E834-4D49-98F6-862EEAAE6F7D}']
    function GetCategory: TCapabilityCategory;
    property Category: TCapabilityCategory read GetCategory;
  end;

  ICapabilityNode = interface (INodeProvider)
    ['{B518F216-9BEE-4E21-8508-AC79FB88973A}']
    function GetName: String;
    function GetAppSid: ISid;
    function GetGroupSid: ISid;
    function GetCategory: TCapabilityCategory;

    property Name: String read GetName;
    property AppSid: ISid read GetAppSid;
    property GroupSid: ISid read GetGroupSid;
    property Category: TCapabilityCategory read GetCategory;
  end;

  TCapabilityGroup = record
    Group: ICapabilityGroupNode;
    Items: TArray<ICapabilityNode>;
  end;

  TCapabilityNodes = array [TCapabilityCategory] of TCapabilityGroup;

function UiLibMakeCapabilityNodes(
): TCapabilityNodes;

implementation

uses
  NtUtils.SysUtils, NtUtils.Packages, DevirtualizedTree.Provider,
  NtUtils.Security.Sid, NtUtils.Security.AppContainer, DelphiUtils.Arrays,
  DelphiUiLib.Reflection.Strings, NtUiLib.AutoCompletion.Sid.Capabilities,
  Vcl.Graphics, UI.Colors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function ColorForState(
  Category: TCapabilityCategory
): TColor;
begin
  case Category of
    ccBuiltin: Result := ColorSettings.clBackgroundSystem;
    ccLpac:    Result := ColorSettings.clBackgroundAllowAccent;
    ccAppSilo: Result := ColorSettings.clBackgroundAllow;
    ccNormal:  Result := ColorSettings.clBackgroundUser;
    ccVendor:  Result := ColorSettings.clBackgroundAlter;
    ccLegacy:  Result := ColorSettings.clBackgroundInactive;
  else
    Result := clWindow;
  end;
end;

type
  TCapabilityBaseNode = class (TNodeProvider, ICapabilityGroupNode)
    FCategory: TCapabilityCategory;
    function GetCategory: TCapabilityCategory;
    procedure Initialize; override;
    constructor Create(Category: TCapabilityCategory);
  end;

{ TCapabilityBaseNode }

constructor TCapabilityBaseNode.Create;
begin
  inherited Create(colMax);
  FCategory := Category;
end;

function TCapabilityBaseNode.GetCategory;
begin
  Result := FCategory;;
end;

procedure TCapabilityBaseNode.Initialize;
const
  NAMES: array [TCapabilityCategory] of String = (
    'Built-in Capabilities', 'LPAC Capabilities', 'AppSilo Capabilities',
    'Other Capabilities', 'Vendor Capabilities', 'Legacy Capabilities'
  );
begin
  inherited;
  FColumnText[colName] := NAMES[FCategory];
  SetFontStyle([TFontStyle.fsBold]);
  SetColor(ColorForState(FCategory));
end;

type
  TCapabilityNode = class (TNodeProvider, ICapabilityNode)
    FCapabilityName: String;
    FAppSid, FGroupSid: ISid;
    FCategory: TCapabilityCategory;
    function GetName: String;
    function GetAppSid: ISid;
    function GetGroupSid: ISid;
    function GetCategory: TCapabilityCategory;
    procedure Initialize; override;
    constructor Create(const Name: String; const AppSid: ISid; const GroupSid: ISid);
  end;

{ TCapabilityNode }

constructor TCapabilityNode.Create;
begin
  inherited Create(colMax);

  FCapabilityName := Name;
  FAppSid := AppSid;
  FGroupSid := GroupSid;

  if RtlxSubAuthorityCountSid(FAppSid) = 2 then
    FCategory := ccBuiltin
  else if RtlxPrefixString('lpac', FCapabilityName) then
    FCategory := ccLpac
  else if RtlxPrefixString('isolatedWin32-', FCapabilityName) then
    FCategory := ccAppSilo
  else if RtlxPrefixString('ID_CAP_', FCapabilityName) then
    FCategory := ccLegacy
  else if PkgxIsValidFamilyName(FCapabilityName) then
    FCategory := ccVendor
  else
    FCategory := ccNormal;
end;

function TCapabilityNode.GetAppSid;
begin
  Result := FAppSid;
end;

function TCapabilityNode.GetCategory;
begin
  Result := FCategory;
end;

function TCapabilityNode.GetGroupSid;
begin
  Result := FGroupSid;
end;

function TCapabilityNode.GetName;
begin
  Result := FCapabilityName;
end;

procedure TCapabilityNode.Initialize;
begin
  inherited;

  FColumnText[colName] := FCapabilityName;
  FColumnText[colAppSid] := RtlxSidToString(FAppSid);
  FColumnText[colGroupSid] := RtlxSidToString(FGroupSid);
  FHint := BuildHint([
    THintSection.New('Name', FColumnText[colName]),
    THintSection.New('App Capability SID', FColumnText[colAppSid]),
    THintSection.New('Group Capability SID', FColumnText[colGroupSid])
  ]);
  SetColor(ColorForState(FCategory));
end;

function CompareBySid(const A, B: ICapabilityNode): Integer;
begin
  Result := RtlxCompareSids(A.AppSid, B.AppSid);
end;

function CompareByName(const A, B: ICapabilityNode): Integer;
begin
  Result := RtlxCompareStrings(A.Name, b.Name);
end;

{ Functions }

[Result: MayReturnNil]
function UiLibMakeCapabilityNode(
  const Name: String
): ICapabilityNode;
var
  AppSid, GroupSid: ISid;
begin
  if RtlxDeriveCapabilitySids(Name, GroupSid, AppSid).IsSuccess then
    Result := TCapabilityNode.Create(Name, AppSid, GroupSid)
  else
    Result := nil;
end;

function UiLibMakeCapabilityNodes;
var
  Names: TArray<String>;
  Nodes: TArray<ICapabilityNode>;
  Category: TCapabilityCategory;
  i, j: Integer;
  Counts: array [TCapabilityCategory] of Integer;
begin
  Names := RtlxEnumerateKnownCapabilities;

  // Makes nodes for all known names
  SetLength(Nodes, Length(Names));

  j := 0;
  for i := 0 to High(Names) do
  begin
    Nodes[j] := UiLibMakeCapabilityNode(Names[i]);

    if Assigned(Nodes[j]) then
      Inc(j);
  end;

  if j <> Length(Nodes) then
    SetLength(Nodes, j);

  // Count nodes per category
  FillChar(Counts, SizeOf(Counts), 0);

  for i := 0 to High(Nodes) do
    Inc(Counts[Nodes[i].Category]);

  // Allocate groups
  for Category := Low(TCapabilityCategory) to High(TCapabilityCategory) do
  begin
    Result[Category].Group := TCapabilityBaseNode.Create(Category);
    SetLength(Result[Category].Items, Counts[Category]);
  end;

  // Assign nodes to groups
  FillChar(Counts, SizeOf(Counts), 0);

  for i := 0 to High(Nodes) do
  begin
    Category := Nodes[i].Category;
    Result[Category].Items[Counts[Category]] := Nodes[i];
    Inc(Counts[Category]);
  end;

  // Sort each group
  TArray.SortInline<ICapabilityNode>(Result[ccBuiltin].Items, CompareBySid);

  for Category := Succ(Low(TCapabilityCategory)) to High(TCapabilityCategory) do
    TArray.SortInline<ICapabilityNode>(Result[Category].Items, CompareByName);
end;

end.
