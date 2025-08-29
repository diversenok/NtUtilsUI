unit NtUiBackend.Sids.WellKnown;

{
  This unit provides the logic for listing the Well-known SIDs enum.
}

interface

uses
  Ntapi.WinBase, NtUtils, NtUiBackend.Sids;

type
  IWellKnownSidNode = interface (ISidNode)
    ['{C2FAA457-A134-4671-AEF3-DCDDB523166D}']
    function GetEnumValue: TWellKnownSidType;
    property EnumValue: TWellKnownSidType read GetEnumValue;
  end;

// Create node entries for all well-known SIDs
function NtUiLibMakeWellKnownSidNodes(
): TArray<IWellKnownSidNode>;

implementation

uses
  DevirtualizedTree.Provider, NtUtils.Security.Sid, NtUtils.Lsa.Sid,
  DelphiUiLib.Strings, DelphiUiLib.Reflection.Strings, DelphiUiLib.Reflection,
  System.SysUtils, System.TypInfo;

const
  colIndex = 0;
  colEnumName = 1;
  colFriendlyName = 2;
  colSid = 3;
  colSidType = 4;
  colMax = 5;

type
  TWellKnownSidNode = class (TNodeProvider, IWellKnownSidNode)
  private
    FEnumValue: TWellKnownSidType;
    FSidName: TTranslatedName;
  public
    function GetEnumValue: TWellKnownSidType;
    function GetSidName: TTranslatedName;
    procedure Initialize; override;
    constructor Create(Value: TWellKnownSidType; const SidName: TTranslatedName);
  end;

{ TWellKnownSidNode }

constructor TWellKnownSidNode.Create;
begin
  inherited Create(colMax);
  FEnumValue := Value;
  FSidName := SidName;
end;

function TWellKnownSidNode.GetEnumValue;
begin
  Result := FEnumValue;
end;

function TWellKnownSidNode.GetSidName;
begin
  Result := FSidName;
end;

procedure TWellKnownSidNode.Initialize;
begin
  inherited;

  FColumnText[colIndex] := UiLibUIntToDec(Cardinal(FEnumValue));
  FColumnText[colEnumName] := GetEnumName(TypeInfo(TWellKnownSidType),
    Integer(FEnumValue));
  FColumnText[colSid] := RtlxSidToString(FSidName.SID);

  if FSidName.IsValid then
  begin
    FColumnText[colSidType] := TType.Represent(FSidName.SidType).Text;
    FColumnText[colFriendlyName] := FSidName.FullName;
  end;

  FHint := BuildHint([
    THintSection.New('Enum Value', Format('%s (%d)', [
      FColumnText[colEnumName],
      Integer(FEnumValue)
    ])),
    THintSection.New('Friendly Name', FColumnText[colFriendlyName]),
    THintSection.New('SID', FColumnText[colSid]),
    THintSection.New('SID Type', FColumnText[colSidType])
  ]);
end;

function NtUiLibMakeWellKnownSidNodes;
var
  Value: TWellKnownSidType;
  Values: TArray<TWellKnownSidType>;
  Sids: TArray<ISid>;
  SidNames: TArray<TTranslatedName>;
  i: Integer;
begin
  SetLength(Values, Succ(Ord(High(TWellKnownSidType))));
  SetLength(Sids, Succ(Ord(High(TWellKnownSidType))));
  i := 0;

  // Collect SIDs for all enum values
  for Value := Low(TWellKnownSidType) to High(TWellKnownSidType) do
    if SddlxCreateWellKnownSid(Value, Sids[i]).IsSuccess then
    begin
      Values[i] := Value;
      Inc(i);
    end;

  // Truncate failed entries if necessary
  if i <> Succ(Ord(High(TWellKnownSidType))) then
  begin
    SetLength(Values, i);
    SetLength(Sids, i);
  end;

  // Ask LSA to translate them in bulk
  LsaxLookupSids(Sids, SidNames);

  // Create tree nodes
  SetLength(Result, Length(SidNames));

  for i := 0 to High(SidNames) do
    Result[i] := TWellKnownSidNode.Create(Values[i], SidNames[i]);
end;

end.
