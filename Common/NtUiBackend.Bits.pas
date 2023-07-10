unit NtUiBackend.Bits;

{
  This module provides logic for a frame for showing bit masks and enumerations.
}

interface

uses
  DevirtualizedTree;

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

implementation

uses
  DelphiApi.Reflection, DelphiUtils.Arrays, DelphiUiLib.Reflection,
  DelphiUiLib.Strings, DelphiUiLib.Reflection.Strings, System.Rtti,
  DevirtualizedTree.Provider, UI.Helper, VirtualTrees.Types, System.SysUtils;

type
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

procedure UiLibCollectEnumNodes(
  const RttiContext: TRttiContext;
  const RttiEnumType: TRttiEnumerationType;
  var FullMask: UInt64;
  out SubEnums: TArray<IFlagNode>
);
var
  Attributes: TCustomAttributeArray;
  a: TCustomAttribute;
  ValidBits: TValidBits;
  NamingStyle: NamingStyleAttribute;
  Names: TArray<String>;
  FlagName: TFlagName;
  i, Count: Integer;
begin
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
  SetLength(SubEnums, Count);

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

      SubEnums[Count] := TFlagNode.Create(RttiEnumType.TypeSize, FlagName,
        FullMask, True);
      Inc(Count);
    end;
end;

procedure UiLibCollectBitNodes(
  const RttiContext: TRttiContext;
  const RttiType: TRttiType;
  out Flags: TArray<IFlagNode>;
  out SubEnumGroups: TArray<TArrayGroup<UInt64, IFlagNode>>;
  var FullMask: UInt64
);
var
  Attributes: TCustomAttributeArray;
  a: TCustomAttribute;
  SubEnums: TArray<IFlagNode>;
  Count: Integer;
begin
  // Collect all (explicit + inherited) attribtues
  Attributes := RttixEnumerateAttributes(RttiContext, RttiType);

  for a in Attributes do
    if a is ValidBitsAttribute then
    begin
      // Save the valid mask
      FullMask := ValidBitsAttribute(a).ValidMask;
      Break;
    end;

  // Count flags
  Count := 0;
  for a in Attributes do
    if a is FlagNameAttribute then
      Inc(Count);

  SetLength(Flags, Count);

  // Save flags
  Count := 0;
  for a in Attributes do
    if a is FlagNameAttribute then
    begin
      Flags[Count] := TFlagNode.Create(RttiType.TypeSize,
        FlagNameAttribute(a).Flag, FlagNameAttribute(a).Flag.Value, False);
      Inc(Count)
    end;

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
      SubEnums[Count] := TFlagNode.Create(RttiType.TypeSize,
        SubEnumAttribute(a).Flag, SubEnumAttribute(a).Mask, True);
      Inc(Count)
    end;

  // Group all sub-enums by masks
  SubEnumGroups := TArray.GroupBy<IFlagNode, UInt64>(SubEnums,
    function (const Node: IFlagNode): UInt64
    begin
      Result := Node.Mask;
    end
  );
end;

procedure UiLibAddBitNodes;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  Flags: TArray<IFlagNode>;
  SubEnums: TArray<TArrayGroup<UInt64, IFlagNode>>;
  UseRootNodes: Boolean;
  GroupRoot: IEditableNodeProvider;
  GroupRootRef: PVirtualNode;
  Node: INodeProvider;
  i, j: Integer;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(ATypeInfo);
  TypeSize := RttiType.TypeSize;

  case RttiType.TypeSize of
    1: FullMask := Byte(-1);
    2: FullMask := Word(-1);
    4: FullMask := Cardinal(-1);
  else
    FullMask := UInt64(-1);
  end;

  if RttiType is TRttiEnumerationType then
  begin
    // Enumerations have no bit flags and one sub enum group
    Flags := nil;
    SetLength(SubEnums, 1);
    SubEnums[0].Key := FullMask;

    UiLibCollectEnumNodes(RttiContext, TRttiEnumerationType(RttiType), FullMask,
      SubEnums[0].Values);

    if Length(SubEnums[0].Values) = 0 then
      SubEnums := nil;
  end
  else if (RttiType is TRttiOrdinalType) or (RttiType is TRttiInt64Type) then
    // Other numeric type
    UiLibCollectBitNodes(RttiContext, RttiType, Flags, SubEnums, FullMask)
  else
    raise EArgumentException.Create('Ordinal type expected');

  // Group nodes in ambiguous scenarios
  UseRootNodes := ((Length(Flags) > 0) and (Length(SubEnums) > 0)) or
    (Length(SubEnums) >= 2);

  Tree.BeginUpdateAuto;
  Tree.Clear;

  if UseRootNodes then
    Tree.TreeOptions.PaintOptions := Tree.TreeOptions.PaintOptions + [toShowRoot]
  else
    Tree.TreeOptions.PaintOptions := Tree.TreeOptions.PaintOptions - [toShowRoot];

  // Add flags
  if Length(Flags) > 0 then
  begin
    if UseRootNodes then
    begin
      GroupRoot := TEditableNodeProvider.Create;
      GroupRoot.ColumnText[0] := 'Flags';
      GroupRootRef := Tree.AddChildEx(nil, GroupRoot).Node;
    end
    else
      GroupRootRef := nil;

    for i := 0 to High(Flags) do
    begin
      Node := Tree.AddChildEx(GroupRootRef, Flags[i]);
      Tree.CheckType[Node.Node] := ctCheckBox;
    end;

    if Assigned(GroupRootRef) then
      Tree.Expanded[GroupRootRef] := True;
  end;

  // Add each group for sub enums
  for j := 0 to High(SubEnums) do
  begin
    if UseRootNodes then
    begin
      GroupRoot := TEditableNodeProvider.Create;
      GroupRoot.ColumnText[0] := 'Options group';
      GroupRoot.Hint := BuildHint('Mask', IntToHexEx(SubEnums[j].Key));
      GroupRootRef := Tree.AddChildEx(nil, GroupRoot).Node;
    end
    else
      GroupRootRef := nil;

    for i := 0 to High(SubEnums[j].Values) do
    begin
      Node := Tree.AddChildEx(GroupRootRef, SubEnums[j].Values[i]);
      Tree.CheckType[Node.Node] := ctRadioButton;
    end;

    if Assigned(GroupRootRef) then
      Tree.Expanded[GroupRootRef] := True;
  end;
end;

end.
