unit UI.Prototypes.Sid.Cheatsheet;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VirtualTrees,
  DevirtualizedTree, DevirtualizedTree.Provider, UI.Prototypes.Forms, NtUtils,
  NtUtils.Security.Sid, NtUtils.Lsa.Sid, VirtualTreesEx;

const
  colSddl = 0;
  colFullName = 1;
  colSid = 2;
  colSidType = 3;
  colCount = 4;

type
  TSidCheatsheet = class (TChildForm)
    btnClose: TButton;
    VST: TDevirtualizedTree;
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    Names: TArray<String>;
    Sids: TArray<ISid>;
    Lookup: TArray<TTranslatedName>;
    procedure FindAbbreviations;
    function MakeProvider(Index: Integer): IEditableNodeProvider;
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
    Lookup := nil;
end;

procedure TSidCheatsheet.FormCreate;
var
  i: Integer;
begin
  FindAbbreviations;
  VST.BeginUpdateAuto;

  for i := 0 to High(Names) do
    VST.AddChild(VST.RootNode).Provider := MakeProvider(i);
end;

function TSidCheatsheet.MakeProvider;
begin
  Result := TEditableNodeProvider.Create(colCount);

  Result.ColumnText[colSddl] := Names[Index];
  Result.ColumnText[colSid] := RtlxSidToString(Sids[Index]);

  if Assigned(Lookup) and Lookup[Index].IsValid then
  begin
    Result.ColumnText[colSidType] := TNumeric.Represent(Lookup[Index].SidType).Text;
    Result.ColumnText[colFullName] := Lookup[Index].FullName;

    Result.Hint := BuildHint([
      THintSection.New('Short Name', Result.ColumnText[colSddl]),
      THintSection.New('Full Name', Result.ColumnText[colFullName]),
      THintSection.New('SID', Result.ColumnText[colSid]),
      THintSection.New('SID Type', Result.ColumnText[colSidType])
    ]);
  end
  else
  begin
    Result.ColumnText[colFullName] := Result.ColumnText[colSid];

    Result.Hint := BuildHint([
      THintSection.New('Short Name', Result.ColumnText[colSddl]),
      THintSection.New('SID', Result.ColumnText[colSid])
    ]);
  end;
end;

end.
