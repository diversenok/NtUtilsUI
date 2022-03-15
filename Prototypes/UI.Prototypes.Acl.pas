unit UI.Prototypes.Acl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  DevirtualizedTree, DevirtualizedTree.Provider, NtUtils.Security.Acl,
  NtUtils.Lsa.Sid, NtUtils, Ntapi.WinNt, VirtualTreesEx;

const
  colPrincipal = 0;
  colSid = 1;
  colAccess = 2;
  colAceType = 3;
  colFlags = 4;
  colMax = 5;

type
  IAceNode = interface (INodeProvider)
    ['{FB3F8975-D27F-4413-A288-C8FCEA16E0EA}']
    function GetAce: TAceData;
  end;

  TAceNodeData = class (TCustomNodeProvider, IAceNode, INodeProvider)
    Ace: TAceData;
    Lookup: TTranslatedName;
    function GetAce: TAceData;

    constructor Create(
      const AceSrc: TAceData;
      const LookupSrc: TTranslatedName;
      MaskType: Pointer
    );

    class function CreateMany(
      const Aces: TArray<TAceData>;
      MaskType: Pointer
    ): TArray<IAceNode>;
  end;

type
  TFrameAcl = class(TFrame)
    VST: TDevirtualizedTree;
  public
    procedure Load(Acl: PAcl; MaskType: Pointer);
  end;

implementation

uses
  NtUtils.Security.Sid, DelphiUiLib.Reflection.Numeric,
  NtUiLib.Reflection.AccessMasks, UI.Colors, UI.Helper;

{$R *.dfm}

{ TAceNodeData }

constructor TAceNodeData.Create;
begin
  inherited Create(colMax);

  Lookup := LookupSrc;
  Ace := AceSrc;
  Cells[colSid] := RtlxSidToString(Ace.Sid);

  if Lookup.IsValid then
    Cells[colPrincipal] := Lookup.FullName
  else
    Cells[colPrincipal] := Cells[colSid];

  Cells[colAccess] := FormatAccess(Ace.Mask, MaskType);
  Cells[colFlags] := TNumeric.Represent(Ace.AceFlags).Text;
  Cells[colAceType] := TNumeric.Represent(Ace.AceType).Text;

  HasColor := True;

  if Ace.AceType in AccessAllowedAces then
    Color := ColorSettings.clEnabled
  else if Ace.AceType in AccessDeniedAces then
    Color := ColorSettings.clDisabled
  else
    Color := ColorSettings.clIntegrity;
end;

class function TAceNodeData.CreateMany;
var
  Sids: TArray<ISid>;
  Lookup: TArray<TTranslatedName>;
  i: Integer;
begin
  SetLength(Sids, Length(Aces));
  for i := 0 to High(Sids) do
    Sids[i] := Aces[i].Sid;

  // Lookup all SIDs at once to speed things up
  if not LsaxLookupSids(Sids, Lookup).IsSuccess then
    SetLength(Lookup, Length(Aces));

  SetLength(Result, Length(Aces));
  for i := 0 to High(Aces) do
    Result[i] := TAceNodeData.Create(Aces[i], Lookup[i], MaskType);
end;

function TAceNodeData.GetAce;
begin
  Result := Ace;
end;

{ TFrameAcl }

procedure TFrameAcl.Load;
var
  Aces: TArray<TAceData>;
  Ace: IAceNode;
begin
  VST.BeginUpdateAuto;

  if not RtlxDumpAcl(Acl, Aces).IsSuccess then
    Aces := nil;

  for Ace in TAceNodeData.CreateMany(Aces, MaskType) do
    VST.AddChild(VST.RootNode).SetProvider(Ace);
end;

end.
