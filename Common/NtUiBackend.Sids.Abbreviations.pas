unit NtUiBackend.Sids.Abbreviations;

{
  This unit provides the logic for listing SDDL SID abbrevations.
}

interface

uses
  NtUtils, NtUtils.Lsa.Sid, DevirtualizedTree;

type
  ISidAbbreviationNode = interface (INodeProvider)
    ['{33C79200-FE73-469A-9590-BA40FA80EF52}']
    function GetSDDL: String;
    function GetSidName: TTranslatedName;
    property SDDL: String read GetSddl;
    property SidName: TTranslatedName read GetSidName;
  end;

// Enumerate known SDDL SID abbreviations and create node for them
function NtUiLibCollectSidAbbreviations(
): TArray<ISidAbbreviationNode>;

implementation

uses
  NtUtils.Security.Sid, DelphiUiLib.Reflection, DelphiUiLib.Reflection.Strings,
  DevirtualizedTree.Provider;

const
  colSddl = 0;
  colFriendlyName = 1;
  colSid = 2;
  colSidType = 3;
  colMax = 4;

type
  TSidAbbreviationNode = class (TNodeProvider, ISidAbbreviationNode)
  private
    FSDDL: String;
    FSidName: TTranslatedName;
  public
    function GetSDDL: String;
    function GetSidName: TTranslatedName;
    procedure Initialize; override;
    constructor Create(const SDDL: String; const SidName: TTranslatedName);
  end;

{ TSidAbbreviationNode }

constructor TSidAbbreviationNode.Create;
begin
  inherited Create(colMax);
  FSDDL := SDDL;
  FSidName := SidName;
end;

function TSidAbbreviationNode.GetSDDL;
begin
  Result := FSDDL;
end;

function TSidAbbreviationNode.GetSidName;
begin
  Result := FSidName;
end;

procedure TSidAbbreviationNode.Initialize;
begin
  inherited;

  FColumnText[colSddl] := FSDDL;
  FColumnText[colSid] := RtlxSidToString(FSidName.SID);

  if FSidName.IsValid then
  begin
    FColumnText[colSidType] := TType.Represent(FSidName.SidType).Text;
    FColumnText[colFriendlyName] := FSidName.FullName;
  end;

  FHint := BuildHint([
    THintSection.New('SDDL', FColumnText[colSddl]),
    THintSection.New('Friendly Name', FColumnText[colFriendlyName]),
    THintSection.New('SID', FColumnText[colSid]),
    THintSection.New('SID Type', FColumnText[colSidType])
  ]);

  if not FSidName.IsValid then
    FColumnText[colFriendlyName] := FSidName.FullName;
end;

function NtUiLibCollectSidAbbreviations;
const
  ALPHABET_LENGTH = Ord('Z') - Ord('A') + 1;
var
  i, Count: Integer;
  Names: TArray<String>;
  SIDs: TArray<ISid>;
  Lookup: TArray<TTranslatedName>;
begin
  SetLength(Names, ALPHABET_LENGTH * ALPHABET_LENGTH);
  SetLength(SIDs, Length(Names));
  Count := 0;

  // Try converting each two-letter abbreviation to a SID
  for i := 0 to High(Names) do
  begin
    SetLength(Names[Count], 2);
    Names[Count][Low(String)] := Chr(Ord('A') + i div ALPHABET_LENGTH);
    Names[Count][Succ(Low(String))] := Chr(Ord('A') + i mod ALPHABET_LENGTH);

    if RtlxStringToSid(Names[Count], SIDs[Count]).IsSuccess then
      Inc(Count);
  end;

  SetLength(Result, Count);
  SetLength(SIDs, Count);

  // Translate SIDs in bulk
  LsaxLookupSids(SIDs, Lookup);

  // Create nodes
  for i := 0 to High(SIDs) do
    Result[i] := TSidAbbreviationNode.Create(Names[i], Lookup[i]);
end;

end.
