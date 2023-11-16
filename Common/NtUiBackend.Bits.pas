unit NtUiBackend.Bits;

{
  This module provides logic for a frame for showing bit masks and enumerations.
}

interface

uses
  Ntapi.WinNt, DevirtualizedTree;

type
  IFlagNode = interface (INodeProvider)
    ['{0D379F12-DEFF-47FD-BC91-1FFF25701AC3}']
    function GetName: String;
    function GetValue: UInt64;
    function GetMask: UInt64;
    property Name: String read GetName;
    property Value: UInt64 read GetValue;
    property Mask: UInt64 read GetMask;
  end;

// Collect and add tree nodes for known flags of a numeric type
procedure UiLibAddBitNodes(
  Tree: TDevirtualizedTree;
  ATypeInfo: Pointer;
  out TypeSize: Integer;
  out FullMask: UInt64
);

// Collect and add tree nodes for an access mask type
procedure UiLibAddAccessMaskNodes(
  Tree: TDevirtualizedTree;
  ATypeInfo: Pointer;
  const GenericMapping: TGenericMapping;
  out FullMask: UInt64;
  ShowGenericRights: Boolean = True;
  ShowMiscRights: Boolean = True
);

implementation

uses
  DelphiApi.Reflection, DelphiUtils.Arrays, DelphiUiLib.Reflection,
  DelphiUiLib.Strings, DelphiUiLib.Reflection.Strings, System.Rtti,
  DevirtualizedTree.Provider, UI.Helper, VirtualTrees.Types, System.SysUtils;

type
  TNodeGroup = record
    Name: String;
    Mask: UInt64;
    UseMaskHint : Boolean;
    IsDefault: Boolean;
    CheckBoxType: TCheckType;
    Nodes: TArray<IFlagNode>;
  end;

  TFlagNode = class (TNodeProvider, IFlagNode)
  protected
    FSize: Integer;
    FFlag: TFlagName;
    FMask: UInt64;
  public
    function GetName: String;
    function GetValue: UInt64;
    function GetMask: UInt64;
    constructor Create(
      Size: Integer;
      const Flag: TFlagName;
      const Mask: UInt64;
      IsSubEnum: Boolean
    );
  end;

constructor TFlagNode.Create;
begin
  inherited Create(1);
  FSize := Size;
  FFlag := Flag;
  FMask := Mask;

  FColumnText[0] := Flag.Name;
  FHint := BuildHint([
    THintSection.New('Name', Flag.Name),
    THintSection.New('Value', IntToHexEx(Flag.Value, Size * 2))
  ]);

  if IsSubEnum then
    FHint := FHint + #$D#$A + BuildHint('Mask', IntToHexEx(Mask, Size * 2));
end;

function TFlagNode.GetMask;
begin
  Result := FMask;
end;

function TFlagNode.GetName;
begin
  Result := FFlag.Name;
end;

function TFlagNode.GetValue;
begin
  Result := FFlag.Value;
end;

function SizeToMask(
  TypeSize: Integer
): UInt64;
begin
  case TypeSize of
    1: Result := Byte(-1);
    2: Result := Word(-1);
    4: Result := Cardinal(-1);
  else
    Result := Uint64(-1);
  end;
end;

function UiLibCollectEnumNodes(
  const RttiContext: TRttiContext;
  const RttiEnumType: TRttiEnumerationType
): TNodeGroup;
var
  Attributes: TCustomAttributeArray;
  a: TCustomAttribute;
  ValidBits: TValidBits;
  NamingStyle: NamingStyleAttribute;
  Names: TArray<String>;
  FlagName: TFlagName;
  i, Count: Integer;
begin
  // Use the default group
  Result.Name := 'Options group';
  Result.Mask := SizeToMask(RttiEnumType.TypeSize);
  Result.UseMaskHint := False;
  Result.IsDefault := True;
  Result.CheckBoxType := ctRadioButton;

  Attributes := RttiEnumType.GetAttributes;

  // By default, accept the entire range
  ValidBits := [0..Byte(RttiEnumType.MaxValue)];

  for a in Attributes do
    if a is ValidBitsAttribute then
    begin
      // Use the custom range
      ValidBits := ValidBitsAttribute(a).ValidBits;
      Break;
    end
    else if a is RangeAttribute then
    begin
      // Allow overwriting the minimal value
      if RangeAttribute(a).MinValue > 0 then
        ValidBits := ValidBits - [0..Byte(RangeAttribute(a).MinValue - 1)];
      Break;
    end;

  // Find the naming style
  NamingStyle := nil;
  for a in Attributes do
    if a is NamingStyleAttribute then
    begin
      NamingStyle := NamingStyleAttribute(a);
      Break;
    end;

  // Count valid names
  Count := 0;
  for i := 0 to RttiEnumType.MaxValue do
    if i in ValidBits then
      Inc(Count);

  // Save valid names
  Names := RttiEnumType.GetNames;
  SetLength(Result.Nodes, Count);

  Count := 0;
  for i := 0 to RttiEnumType.MaxValue do
    if i in ValidBits then
    begin
      FlagName.Value := Cardinal(i);
      FlagName.Name := Names[i];

      if Assigned(NamingStyle) then
        case NamingStyle.NamingStyle of
          nsCamelCase:
            FlagName.Name := PrettifyCamelCase(FlagName.Name,
              NamingStyle.Prefix, NamingStyle.Suffix);

          nsSnakeCase:
            FlagName.Name := PrettifySnakeCase(FlagName.Name,
              NamingStyle.Prefix, NamingStyle.Suffix);
        end;

      Result.Nodes[Count] := TFlagNode.Create(RttiEnumType.TypeSize, FlagName,
        SizeToMask(RttiEnumType.TypeSize), True);
      Inc(Count);
    end;
end;

function UiLibCollectSubEnumNodes(
  const Attributes: TCustomAttributeArray;
  TypeSize: Integer
): TArray<TNodeGroup>;
var
  a: TCustomAttribute;
  SubEnums: TArray<IFlagNode>;
  Groups: TArray<TArrayGroup<UInt64, IFlagNode>>;
  GroupNames: TArray<FlagGroupAttribute>;
  Count, i, j: Integer;
begin
  // Count sub enums
  Count := 0;
  for a in Attributes do
    if a is SubEnumAttribute then
      Inc(Count);

  SetLength(SubEnums, Count);

  // Save sub enums
  Count := 0;
  for a in Attributes do
    if a is SubEnumAttribute then
    begin
      SubEnums[Count] := TFlagNode.Create(TypeSize,
        SubEnumAttribute(a).Flag, SubEnumAttribute(a).Mask, True);
      Inc(Count)
    end;

  // Group all sub-enums by masks
  Groups := TArray.GroupBy<IFlagNode, UInt64>(SubEnums,
    function (const Node: IFlagNode): UInt64
    begin
      Result := Node.Mask;
    end
  );

  // Collect known names for groups
  RttixFilterAttributes(Attributes, FlagGroupAttribute,
    TCustomAttributeArray(GroupNames));

  // Convert flag groups into node groups
  SetLength(Result, Length(Groups));

  for i := 0 to High(Result) do
  begin
    Result[i].Name := 'Options group';

    // Allow attributes to override group names
    for j := 0 to High(GroupNames) do
      if GroupNames[j].Flag.Value = Groups[i].Key then
      begin
        Result[i].Name := GroupNames[j].Flag.Name;
        Break;
      end;

    Result[i].Mask := Groups[i].Key;
    Result[i].UseMaskHint := True;
    Result[i].IsDefault := True;
    Result[i].CheckBoxType := ctRadioButton;
    Result[i].Nodes := Groups[i].Values;
  end;
end;

function UiLibCollectFlagNodes(
  const Attributes: TCustomAttributeArray;
  TypeSize: Integer;
  Filter: UInt64 = UInt64(-1)
): TArray<IFlagNode>;
var
  a: TCustomAttribute;
  Count: Integer;
begin
  // Count flags
  Count := 0;
  for a in Attributes do
    if a is FlagNameAttribute then
      if FlagNameAttribute(a).Flag.Value and not Filter = 0 then
        Inc(Count);

  SetLength(Result, Count);

  // Save flags
  Count := 0;
  for a in Attributes do
    if a is FlagNameAttribute then
      if FlagNameAttribute(a).Flag.Value and not Filter = 0 then
      begin
        Result[Count] := TFlagNode.Create(TypeSize, FlagNameAttribute(a).Flag,
          FlagNameAttribute(a).Flag.Value, False);
        Inc(Count)
      end;
end;

function UiLibCollectAllFlagNodes(
  const Attributes: TCustomAttributeArray;
  TypeSize: Integer
): TArray<TNodeGroup>;
var
  GroupAttributes: TArray<FlagGroupAttribute>;
  UngroupedBits: UInt64;
  i: Integer;
begin
  // Infer flag groups from the type information
  RttixFilterAttributes(Attributes, FlagGroupAttribute,
    TCustomAttributeArray(GroupAttributes));

  UngroupedBits := SizeToMask(TypeSize);
  SetLength(Result, Length(GroupAttributes));

  // Convert them into node groups
  for i := 0 to High(GroupAttributes) do
  begin
    Result[i].Name := GroupAttributes[i].Flag.Name;
    Result[i].Mask := GroupAttributes[i].Flag.Value;
    Result[i].UseMaskHint := True;
    Result[i].IsDefault := False;
    Result[i].CheckBoxType := ctCheckBox;
    UngroupedBits := UngroupedBits and not Result[i].Mask;
  end;

  if UngroupedBits <> 0 then
  begin
    // Construct a default groups
    SetLength(Result, Length(Result) + 1);

    if Length(GroupAttributes) > 0 then
      Result[High(Result)].Name := 'Other'
    else
      Result[High(Result)].Name := 'Flags';

    Result[High(Result)].Mask := UngroupedBits;
    Result[High(Result)].UseMaskHint := False;
    Result[High(Result)].IsDefault := True;
    Result[High(Result)].CheckBoxType := ctCheckBox;
  end;

  // Collect nodes for each group
  for i := 0 to High(Result) do
    Result[i].Nodes := UiLibCollectFlagNodes(Attributes, TypeSize,
      Result[i].Mask);
end;

procedure UiLibUpdateFullMask(
  const Attributes: TCustomAttributeArray;
  var FullMask: UInt64
);
var
  a: TCustomAttribute;
begin
  for a in Attributes do
    if a is ValidBitsAttribute then
    begin
      // Save the valid mask
      FullMask := ValidBitsAttribute(a).ValidMask;
      Break;
    end;
end;

procedure UiLibAddNodeGroups(
  Tree: TDevirtualizedTree;
  var Groups: TArray<TNodeGroup>
);
var
  i, j: Integer;
  HideRoot: Boolean;
  GroupNode: IEditableNodeProvider;
  ParentNode: PVirtualNode;
  FlagNode: IFlagNode;
begin
  // Remove empty groups
  j := 0;
  for i := 0 to High(Groups) do
    if Length(Groups[i].Nodes) > 0 then
    begin
      if i <> j then
        Groups[j] := Groups[i];
      Inc(j);
    end;

  SetLength(Groups, j);

  // Omit groups in unambiguous scenarios
  HideRoot := (Length(Groups) = 1) and Groups[0].IsDefault;

  Tree.BeginUpdateAuto;
  Tree.Clear;

  if HideRoot then
    Tree.TreeOptions.PaintOptions := Tree.TreeOptions.PaintOptions - [toShowRoot]
  else
    Tree.TreeOptions.PaintOptions := Tree.TreeOptions.PaintOptions + [toShowRoot];

  // Add all groups and nodes
  for i := 0 to High(Groups) do
  begin
    if not HideRoot then
    begin
      // Add the group node
      GroupNode := TEditableNodeProvider.Create;
      GroupNode.ColumnText[0] := Groups[i].Name;

      if Groups[i].UseMaskHint then
        GroupNode.Hint := BuildHint('Mask', IntToHexEx(Groups[i].Mask));

      ParentNode := Tree.AddChildEx(nil, GroupNode).Node;
    end
    else
      ParentNode := nil;

    // Add nested nodes
    for FlagNode in Groups[i].Nodes do
    begin
      Tree.AddChildEx(ParentNode, FlagNode);
      Tree.CheckType[FlagNode.Node] := Groups[i].CheckBoxType;
    end;

    if Assigned(ParentNode) then
      Tree.Expanded[ParentNode] := True;
  end;
end;

procedure UiLibAddBitNodes;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  Attributes: TCustomAttributeArray;
  Groups: TArray<TNodeGroup>;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(ATypeInfo);
  TypeSize := RttiType.TypeSize;
  FullMask := SizeToMask(TypeSize);

  if RttiType is TRttiEnumerationType then
    // Enumerations have no bit flags and one sub enum group
    Groups := [UiLibCollectEnumNodes(RttiContext, TRttiEnumerationType(RttiType))]
  else if (RttiType is TRttiOrdinalType) or (RttiType is TRttiInt64Type) then
  begin
    // Collect flags and sub-enums from all (explicit + inherited) attributes
    Attributes := RttixEnumerateAttributes(RttiContext, RttiType);
    Groups := UiLibCollectAllFlagNodes(Attributes, RttiType.TypeSize);
    Groups := Groups + UiLibCollectSubEnumNodes(Attributes, RttiType.TypeSize);

    // Allow attributes override the full mask
    UiLibUpdateFullMask(Attributes, FullMask);
  end
  else
    raise EArgumentException.Create('Ordinal type expected');

  // Add the grouped nodes
  UiLibAddNodeGroups(Tree, Groups);
end;

procedure UiLibAddAccessMaskNodes;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  Attributes: TCustomAttributeArray;
  Groups: TArray<TNodeGroup>;
  Group: TNodeGroup;
  i: Integer;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(ATypeInfo);

  if not (RttiType is TRttiOrdinalType) then
    raise EArgumentException.Create('Ordinal type expected');

  // Use all (explicit and inherited) attributes
  Attributes := RttixEnumerateAttributes(RttiContext, RttiType);

  // Allow the attributes to override the Full Access mask
  FullMask := SizeToMask(RttiType.TypeSize);
  UiLibUpdateFullMask(Attributes, FullMask);

  Tree.BeginUpdateAuto;
  Tree.Clear;

  if ShowMiscRights and ShowGenericRights then
    SetLength(Groups, 7)
  else if ShowMiscRights or ShowGenericRights then
    SetLength(Groups, 6)
  else
    SetLength(Groups, 5);

  Group.UseMaskHint := True;
  Group.IsDefault := False;
  Group.CheckBoxType := ctCheckBox;

  // Add groups of rights
  Group.Name := 'Read';
  Group.Mask := GenericMapping.GenericRead;
  Group.Nodes := UiLibCollectFlagNodes(Attributes, RttiType.TypeSize,
    Group.Mask and SPECIFIC_RIGHTS_ALL);
  Groups[0] := Group;

  Group.Name := 'Write';
  Group.Mask := GenericMapping.GenericWrite;
  Group.Nodes := UiLibCollectFlagNodes(Attributes, RttiType.TypeSize,
    Group.Mask and SPECIFIC_RIGHTS_ALL);
  Groups[1] := Group;

  Group.Name := 'Execute';
  Group.Mask := GenericMapping.GenericExecute;
  Group.Nodes := UiLibCollectFlagNodes(Attributes, RttiType.TypeSize,
    Group.Mask and SPECIFIC_RIGHTS_ALL);
  Groups[2] := Group;

  Group.Name := 'Other';
  Group.Mask := SPECIFIC_RIGHTS_ALL and not GenericMapping.GenericRead
    and not GenericMapping.GenericWrite and not GenericMapping.GenericExecute;
  Group.Nodes := UiLibCollectFlagNodes(Attributes, RttiType.TypeSize,
    Group.Mask);
  Groups[3] := Group;

  Group.Name := 'Standard';
  Group.Mask := FullMask and STANDARD_RIGHTS_ALL;
  Group.Nodes := UiLibCollectFlagNodes(Attributes, RttiType.TypeSize,
    Group.Mask);
  Groups[4] := Group;

  i := 5;

  if ShowGenericRights then
  begin
    Group.Name := 'Generic';
    Group.Mask := GENERIC_RIGHTS_ALL;
    Group.Nodes := UiLibCollectFlagNodes(Attributes, RttiType.TypeSize,
      Group.Mask);
    Groups[i] := Group;
    Inc(i);
  end;

  if ShowMiscRights then
  begin
    Group.Name := 'Miscellaneous';
    Group.Mask := MAXIMUM_ALLOWED or ACCESS_SYSTEM_SECURITY;
    Group.Nodes := UiLibCollectFlagNodes(Attributes, RttiType.TypeSize,
      Group.Mask);
    Groups[i] := Group;
  end;

  // Add the groups of flags
  UiLibAddNodeGroups(Tree, Groups);
end;

end.
