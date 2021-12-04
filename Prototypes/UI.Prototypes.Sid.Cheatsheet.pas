unit UI.Prototypes.Sid.Cheatsheet;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VirtualTrees,
  VirtualTreesEx, UI.Prototypes.Forms, NtUtils, NtUtils.Security.Sid,
  NtUtils.Lsa.Sid;

const
  colSddl = 0;
  colFullName = 1;
  colSid = 2;
  colSidType = 3;
  colCount = 4;

type
  TSidCheatsheet = class (TChildForm)
    btnClose: TButton;
    VST: TVirtualStringTreeEx;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    Names: TArray<String>;
    Sids: TArray<ISid>;
    Lookup: TArray<TTranslatedName>;
    procedure FindAbbreviations;
    function MakeINodeData(Index: Integer): INodeData;
  end;

implementation

uses
  NtUtils.SysUtils, UI.Helper, DelphiUiLib.Reflection.Numeric,
  DelphiUiLib.Reflection.Strings;

{$R *.dfm}

procedure TSidCheatsheet.btnCloseClick;
begin
  Close;
end;

procedure TSidCheatsheet.FindAbbreviations;
const
  ALPHABET_LENGTH = Ord('Z') - Ord('A') + 1;
var
  i, Count: Integer;
begin
  SetLength(Names, ALPHABET_LENGTH * ALPHABET_LENGTH);
  SetLength(Sids, Length(Names));
  Count := 0;

  // Try converting each two-letter abbreviation to a SID
  for i := 0 to High(Names) do
  begin
    SetLength(Names[Count], 2);
    Names[Count][Low(String)] := Chr(Ord('A') + i div ALPHABET_LENGTH);
    Names[Count][Succ(Low(String))] := Chr(Ord('A') + i mod ALPHABET_LENGTH);

    if RtlxStringToSid(Names[Count], Sids[Count]).IsSuccess then
      Inc(Count);
  end;

  SetLength(Names, Count);
  SetLength(Sids, Count);

  // Lookup friendly names
  if not LsaxLookupSids(Sids, Lookup).IsSuccess then
    SetLength(Lookup, Length(Names));
end;

procedure TSidCheatsheet.FormCreate;
var
  i: Integer;
begin
  FindAbbreviations;
  BeginUpdateAuto(VST);
  VST.UseINodeDataMode;

  for i := 0 to High(Names) do
    VST.AddChild(VST.RootNode).SetINodeData(MakeINodeData(i));
end;

function TSidCheatsheet.MakeINodeData;
var
  Cells: TArray<String>;
  Hint: String;
begin
  SetLength(Cells, colCount);

  Cells[colSddl] := Names[Index];
  Cells[colSid] := RtlxSidToString(Sids[Index]);
  Cells[colSidType] := TNumeric.Represent(Lookup[Index].SidType).Text;

  if Lookup[Index].IsValid then
  begin
    Cells[colFullName] := Lookup[Index].FullName;

    Hint := BuildHint([
      THintSection.New('Short Name', Cells[colSddl]),
      THintSection.New('Full Name', Cells[colFullName]),
      THintSection.New('SID', Cells[colSid]),
      THintSection.New('SID Type', Cells[colSidType])
    ]);
  end
  else
  begin
    Cells[colFullName] := Cells[colSid];

    Hint := BuildHint([
      THintSection.New('Short Name', Cells[colSddl]),
      THintSection.New('SID', Cells[colSid])
    ]);
  end;

  Result := TCustomNodeData.Create(Cells, Hint);
end;

end.
