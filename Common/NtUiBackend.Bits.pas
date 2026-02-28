unit NtUiBackend.Bits;

{
  This module provides logic for a frame for showing bit masks and enumerations.
}

interface

uses
  Ntapi.WinNt, NtUtils.SysUtils, NtUtilsUI.DevirtualizedTree;

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
  out TypeSize: TIntegerSize;
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
  DelphiApi.Reflection, DelphiUtils.Arrays, DelphiUiLib.Strings,
  NtUtilsUI.DevirtualizedTree.Provider, NtUiCommon.Helpers,
  VirtualTrees.Types, DelphiUtils.LiteRTTI, System.SysUtils;

type
  TNodeGroup = record
    Name: String;
    Size: TIntegerSize;
    Mask: UInt64;
    UseMaskHint : Boolean;
    IsDefault: Boolean;
    CheckBoxType: TCheckType;
    Nodes: TArray<IFlagNode>;
  end;

  TFlagNode = class (TNodeProvider, IFlagNode)
  protected
    FSize: TIntegerSize;
    FName: String;
    FValue: UInt64;
    FMask: UInt64;
  public
    function GetName: String;
    function GetValue: UInt64;
    function GetMask: UInt64;
    constructor Create(
      Size: TIntegerSize;
      const Name: String;
      const Value: UInt64;
      const Mask: UInt64;
      ValueKind: TRttixBitwiseFlagKind
    );
  end;

constructor TFlagNode.Create;
begin
  inherited Create(1);
  FSize := Size;
  FName := Name;
  FValue := Value;
  FMask := Mask;

  FColumnText[0] := Name;
  FHint := BuildHint([
    THintSection.New('Name', Name),
    THintSection.New('Value', UiLibUIntToHex(Value,
      NUMERIC_WIDTH_PER_SIZE[Size]))
  ]);

  if ValueKind = rbkSubEnum then
    FHint := FHint + #$D#$A + BuildHint('Mask', UiLibUIntToHex(Mask,
      NUMERIC_WIDTH_PER_SIZE[Size]));
end;

function TFlagNode.GetMask;
begin
  Result := FMask;
end;

function TFlagNode.GetName;
begin
  Result := FName;
end;

function TFlagNode.GetValue;
begin
  Result := FValue;
end;

function ByteSizeToIntegerSize(
  ByteSize: Byte
): TIntegerSize;
begin
  case ByteSize of
    1: Result := isByte;
    2: Result := isWord;
    4: Result := isCardinal;
    8: Result := isUInt64;
  else
    Error(reAssertionFailed);
    Result := isUInt64;
  end;
end;

function SizeToMask(
  TypeSize: TIntegerSize
): UInt64;
begin
  case TypeSize of
    isByte: Result := Byte(-1);
    isWord: Result := Word(-1);
    isCardinal: Result := Cardinal(-1);
    isUInt64: Result := UInt64(-1);
  else
    Error(reAssertionFailed);
    Result := UInt64(-1);
  end;
end;

function UiLibCollectEnumNodes(
  const EnumType: IRttixEnumType;
  Size: TIntegerSize
): TNodeGroup;
var
  Attributes: TArray<PLiteRttiAttribute>;
  i, Count: Integer;
  Name: String;
begin
  // Use the default group
  Result.Name := 'Options group';
  Result.Size := Size;
  Result.Mask := SizeToMask(Size);
  Result.UseMaskHint := False;
  Result.IsDefault := True;
  Result.CheckBoxType := ctRadioButton;

  Attributes := EnumType.GetAttributes;

  // Count valid names
  Count := 0;
  for i in EnumType.ValidValues do
    Inc(Count);

  // Save valid names
  SetLength(Result.Nodes, Count);

  Count := 0;
  for i in EnumType.ValidValues do
  begin
    Name := EnumType.TypeInfo.EnumerationName(i);

    case EnumType.NamingStyle of
      nsCamelCase:
        Name := PrettifyCamelCase(Name, EnumType.Prefix, EnumType.Suffix);

      nsSnakeCase:
        Name := PrettifySnakeCase(Name, EnumType.Prefix, EnumType.Suffix);
    end;

    Result.Nodes[Count] := TFlagNode.Create(Size, Name, Cardinal(i),
      Result.Mask, rbkSubEnum);
    Inc(Count);
  end;
end;

function UiLibCollectSubEnumNodes(
  const BitwiseType: IRttixBitwiseType;
  Size: TIntegerSize
): TArray<TNodeGroup>;
var
  SubEnums: TArray<TRttixBitwiseFlag>;
  Groups: TArray<TArrayGroup<UInt64, TRttixBitwiseFlag>>;
  i, j: Integer;
begin
  // Collect sub-enum attributes
  SubEnums := TArray.Filter<TRttixBitwiseFlag>(BitwiseType.Flags,
    function (const Entry: TRttixBitwiseFlag): Boolean
    begin
      Result := Entry.Kind = rbkSubEnum;
    end
  );

  // Group sub-enums by mask
  Groups := TArray.GroupBy<TRttixBitwiseFlag, UInt64>(SubEnums,
    function (const Node: TRttixBitwiseFlag): UInt64
    begin
      Result := Node.Mask;
    end
  );

  // Prepare node groups
  SetLength(Result, Length(Groups));

  for i := 0 to High(Result) do
  begin
    Result[i].Name := 'Options group';
    Result[i].Size := Size;

    // Allow attributes to override group names
    for j := 0 to High(BitwiseType.FlagGroups) do
      if BitwiseType.FlagGroups[j].Mask = Groups[i].Key then
      begin
        Result[i].Name := BitwiseType.FlagGroups[j].Name;
        Break;
      end;

    Result[i].Mask := Groups[i].Key;
    Result[i].UseMaskHint := True;
    Result[i].IsDefault := True;
    Result[i].CheckBoxType := ctRadioButton;

    SetLength(Result[i].Nodes, Length(Groups[i].Values));
    for j := 0 to High(Result[i].Nodes) do
      Result[i].Nodes[j] := TFlagNode.Create(Size,
        Groups[i].Values[j].Name, Groups[i].Values[j].Value,
        Groups[i].Values[j].Mask, rbkSubEnum);
  end;
end;

function UiLibCollectFlagNodes(
  const BitwiseType: IRttixBitwiseType;
  Size: TIntegerSize;
  Filter: UInt64 = UInt64(-1)
): TArray<IFlagNode>;
var
  Flags: TArray<TRttixBitwiseFlag>;
  i: Integer;
begin
  // Collect matching flag attributes
  Flags := TArray.Filter<TRttixBitwiseFlag>(BitwiseType.Flags,
    function (const Entry: TRttixBitwiseFlag): Boolean
    begin
      Result := (Entry.Kind = rbkFlag) and (Entry.Value and not Filter = 0);
    end
  );

  // Prepare nodes
  SetLength(Result, Length(Flags));

  for i := 0 to High(Result) do
    Result[i] := TFlagNode.Create(Size, Flags[i].Name, Flags[i].Value,
      Flags[i].Value, rbkFlag);
end;

function UiLibCollectAllFlagNodes(
  const BitwiseType: IRttixBitwiseType;
  Size: TIntegerSize
): TArray<TNodeGroup>;
var
  UngroupedBits: UInt64;
  i: Integer;
begin
  UngroupedBits := SizeToMask(Size);
  SetLength(Result, Length(BitwiseType.FlagGroups));

  // Convert them into node groups
  for i := 0 to High(Result) do
  begin
    Result[i].Size := Size;
    Result[i].Name := BitwiseType.FlagGroups[i].Name;
    Result[i].Mask := BitwiseType.FlagGroups[i].Mask;
    Result[i].UseMaskHint := True;
    Result[i].IsDefault := False;
    Result[i].CheckBoxType := ctCheckBox;
    UngroupedBits := UngroupedBits and not Result[i].Mask;
  end;

  if UngroupedBits <> 0 then
  begin
    // Construct a default groups
    SetLength(Result, Length(Result) + 1);

    if Length(BitwiseType.FlagGroups) > 0 then
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
    Result[i].Nodes := UiLibCollectFlagNodes(BitwiseType, Size, Result[i].Mask);
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
        GroupNode.Hint := BuildHint('Mask', UiLibUIntToHex(Groups[i].Mask,
          NUMERIC_WIDTH_PER_SIZE[Groups[i].Size]));

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
  RttiType: IRttixType;
  EnumType: IRttixEnumType;
  BitwiseType: IRttixBitwiseType;
  Groups: TArray<TNodeGroup>;
begin
  RttiType := RttixTypeInfo(ATypeInfo);

  if RttiType.SubKind = rtkEnumeration then
  begin
    EnumType := RttiType as IRttixEnumType;
    TypeSize := ByteSizeToIntegerSize(EnumType.Size);
    FullMask := SizeToMask(TypeSize);

    // Enumerations have no bit flags and one sub enum group
    Groups := [UiLibCollectEnumNodes(EnumType, TypeSize)];
  end
  else if RttiType.SubKind = rtkBitwise then
  begin
    BitwiseType := RttiType as IRttixBitwiseType;

    // Collect flags and sub-enums from all (explicit + inherited) attributes
    Groups := UiLibCollectAllFlagNodes(BitwiseType, TypeSize);
    Groups := Groups + UiLibCollectSubEnumNodes(BitwiseType, TypeSize);
    FullMask := BitwiseType.ValidMask;
  end
  else
    raise EArgumentException.Create('Expected an enumeration or bitwise type');

  // Add the grouped nodes
  UiLibAddNodeGroups(Tree, Groups);
end;

procedure UiLibAddAccessMaskNodes;
var
  RttiType: IRttixType;
  BitwiseType: IRttixBitwiseType;
  Groups: TArray<TNodeGroup>;
  Group: TNodeGroup;
  i: Integer;
begin
  RttiType := RttixTypeInfo(ATypeInfo);

  if RttiType.SubKind <> rtkBitwise then
    raise EArgumentException.Create('Expected a bitwise type');

  BitwiseType := RttiType as IRttixBitwiseType;
  FullMask := BitwiseType.ValidMask;

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
  Group.Size := isCardinal;

  // Add groups of rights
  Group.Name := 'Read';
  Group.Mask := GenericMapping.GenericRead;
  Group.Nodes := UiLibCollectFlagNodes(BitwiseType, isCardinal,
    Group.Mask and SPECIFIC_RIGHTS_ALL);
  Groups[0] := Group;

  Group.Name := 'Write';
  Group.Mask := GenericMapping.GenericWrite;
  Group.Nodes := UiLibCollectFlagNodes(BitwiseType, isCardinal,
    Group.Mask and SPECIFIC_RIGHTS_ALL);
  Groups[1] := Group;

  Group.Name := 'Execute';
  Group.Mask := GenericMapping.GenericExecute;
  Group.Nodes := UiLibCollectFlagNodes(BitwiseType, isCardinal,
    Group.Mask and SPECIFIC_RIGHTS_ALL);
  Groups[2] := Group;

  Group.Name := 'Other';
  Group.Mask := SPECIFIC_RIGHTS_ALL and not GenericMapping.GenericRead
    and not GenericMapping.GenericWrite and not GenericMapping.GenericExecute;
  Group.Nodes := UiLibCollectFlagNodes(BitwiseType, isCardinal, Group.Mask);
  Groups[3] := Group;

  Group.Name := 'Standard';
  Group.Mask := FullMask and STANDARD_RIGHTS_ALL;
  Group.Nodes := UiLibCollectFlagNodes(BitwiseType, isCardinal, Group.Mask);
  Groups[4] := Group;

  i := 5;

  if ShowGenericRights then
  begin
    Group.Name := 'Generic';
    Group.Mask := GENERIC_RIGHTS_ALL;
    Group.Nodes := UiLibCollectFlagNodes(BitwiseType, isCardinal, Group.Mask);
    Groups[i] := Group;
    Inc(i);
  end;

  if ShowMiscRights then
  begin
    Group.Name := 'Miscellaneous';
    Group.Mask := MAXIMUM_ALLOWED or ACCESS_SYSTEM_SECURITY;
    Group.Nodes := UiLibCollectFlagNodes(BitwiseType, isCardinal, Group.Mask);
    Groups[i] := Group;
  end;

  // Add the groups of flags
  UiLibAddNodeGroups(Tree, Groups);
end;

end.
