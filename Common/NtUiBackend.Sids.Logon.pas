unit NtUiBackend.Sids.Logon;

interface

uses
  Ntapi.WinNt, Ntapi.NtSecApi, NtUtils, NtUiBackend.Sids, DevirtualizedTree;

type
  ILogonSessionErrorNode = interface (INodeProvider)
    ['{2A6AC1C0-3056-49D0-9706-A1356D179A1A}']
    function GetLogonId: TLogonId;
    function GetStatus: TNtxStatus;
    property LogonId: TLogonId read GetLogonId;
    property Status: TNtxStatus read GetStatus;
  end;

  ILogonSessionSidNode = interface (ISidNode)
    ['{C44BE4D5-EC6C-40EA-A183-27008F886278}']
    function GetLogonId: TLogonId;
    function GetLogonType: TSecurityLogonType;
    property LogonId: TLogonId read GetLogonId;
    property LogonType: TSecurityLogonType read GetLogonType;
  end;

function NtUiLibCollectLogonSidNodes(
  out Nodes: TArray<INodeProvider>
): TNtxStatus;

implementation

uses
  NtUtils.Security.Sid, NtUtils.Lsa.Sid, NtUtils.Lsa.Logon, NtUtils.Errors,
  NtUiLib.Errors, DevirtualizedTree.Provider, DelphiUtils.Arrays,
  DelphiUiLib.Strings, DelphiUiLib.Reflection, NtUiCommon.Colors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

const
  colId = 0;
  colLogonType = 1;
  colFriendlyName = 2;
  colSid = 3;
  colSidType = 4;
  colMax = 5;

type
  ILogonSessionSidNodeInternal = interface (ILogonSessionSidNode)
    ['{3F5FBC1B-0C47-4EFD-9E47-28786A7C44A9}']
    procedure SetSidName(const Value: TTranslatedName);
  end;

  TLogonSessionErrorNode = class (TNodeProvider, ILogonSessionErrorNode)
  private
    FLogonId: TLogonId;
    FStatus: TNtxStatus;
  protected
    procedure Initialize; override;
    function GetLogonId: TLogonId;
    function GetStatus: TNtxStatus;
  public
    constructor Create(const LogonId: TLogonId; const Status: TNtxStatus);
  end;

  TLogonSessionSidNode = class (TNodeProvider, ILogonSessionSidNode,
    ILogonSessionSidNodeInternal)
  private
    FLogonId: TLogonId;
    FLogonType: TSecurityLogonType;
    FSidName: TTranslatedName;
  protected
    procedure Initialize; override;
    function GetLogonId: TLogonId;
    function GetLogonType: TSecurityLogonType;
    function GetSidName: TTranslatedName;
    procedure SetSidName(const Value: TTranslatedName);
  public
    constructor Create(
      LogonId: TLogonId;
      LogonType: TSecurityLogonType;
      const Sid: ISid
    );
  end;

{ TLogonSessionErrorNode }

constructor TLogonSessionErrorNode.Create;
begin
  inherited Create(colMax);
  FLogonId := LogonId;
  FStatus := Status;
end;

function TLogonSessionErrorNode.GetLogonId;
begin
  Result := FLogonId;;
end;

function TLogonSessionErrorNode.GetStatus;
begin
  Result := FStatus;
end;

procedure TLogonSessionErrorNode.Initialize;
begin
  inherited;
  FColumnText[colId] := UiLibUIntToHex(FLogonId);

  if FStatus.IsSuccess then
  begin
    FColumnText[colFriendlyName] := '(None)';
    FColumnText[colSid] := '(None)';
    FColumnText[colSidType] := '(None)';
  end
  else
    FHint := FStatus.ToString;

  SetFontColor(ColorSettings.clForegroundInactive);
end;

{ TLogonSessionSidNode }

constructor TLogonSessionSidNode.Create;
begin
  inherited Create(colMax);
  FLogonId := LogonId;
  FLogonType := LogonType;
  FSidName.SID := Sid;
end;

function TLogonSessionSidNode.GetLogonId;
begin
  Result := FLogonId;
end;

function TLogonSessionSidNode.GetLogonType;
begin
  Result := FLogonType;
end;

function TLogonSessionSidNode.GetSidName;
begin
  Result := FSidName;
end;

procedure TLogonSessionSidNode.Initialize;
begin
  inherited;
  FColumnText[colId] := UiLibUIntToHex(FLogonId);
  FColumnText[colSid] := RtlxSidToString(FSidName.SID);

  if FLogonType in [TSecurityLogonType.Interactive..High(TSecurityLogonType)] then
    FColumnText[colLogonType] := TType.Represent(FLogonType).Text;

  if FSidName.IsValid then
  begin
    FColumnText[colFriendlyName] := FSidName.FullName;
    FColumnText[colSidType] := TType.Represent(FSidName.SidType).Text;
  end;

  FHint := BuildHint([
    THintSection.New('Logon ID', FColumnText[colId]),
    THintSection.New('Logon Type', FColumnText[colLogonType]),
    THintSection.New('Owner SID Friendly Name', FColumnText[colFriendlyName]),
    THintSection.New('Owner SID', FColumnText[colSid])
  ]);
end;

procedure TLogonSessionSidNode.SetSidName;
begin
  FSidName := Value;
end;

{ Functions }

procedure AttachLookup(
  const Nodes: TArray<INodeProvider>
);
var
  SIDs: TArray<ISid>;
  Names: TArray<TTranslatedName>;
  TranslatedNodes: TArray<ILogonSessionSidNodeInternal>;
  i, Count: Integer;
  Node: ILogonSessionSidNodeInternal;
begin
  Count := 0;

  // Count non-error nodes
  for i := 0 to High(Nodes) do
    if Nodes[i].QueryInterface(ILogonSessionSidNodeInternal, Node).IsSuccess then
      Inc(Count);

  // Collect their SIDs
  SetLength(SIDs, Count);
  SetLength(TranslatedNodes, Count);
  Count := 0;

  // Count non-error nodes
  for i := 0 to High(Nodes) do
    if Nodes[i].QueryInterface(ILogonSessionSidNodeInternal, Node).IsSuccess then
    begin
      SIDs[Count] := Node.SidName.SID;
      TranslatedNodes[Count] := Node;
      Inc(Count);
    end;

  // Perform bulk lookup and attach it to nodes
  LsaxLookupSids(SIDs, Names);

  for i := 0 to High(TranslatedNodes) do
    TranslatedNodes[i].SetSidName(Names[i]);
end;

function NtUiLibCollectLogonSidNodes;
var
  Luids: TArray<TLogonId>;
  Info: ILogonSession;
  LogonType: TSecurityLogonType;
  Sid: ISid;
  i: Integer;
begin
  // Snapshot logon sessions
  Result := LsaxEnumerateLogonSessions(Luids);

  if not Result.IsSuccess then
    Exit;

  TArray.SortInline<TLogonId>(Luids,
    function (const A, B: TLogonId): Integer
    begin
      if A > B then
        Result := 1
      else if A < B then
        Result := -1
      else
        Result := 0;
    end
  );

  SetLength(Nodes, Length(Luids));

  for i := 0 to High(Luids) do
  begin
    // Retrieve details
    Result := LsaxQueryLogonSession(Luids[i], Info);

    if not Result.IsSuccess or not Assigned(Info.Data.SID) or
      not RtlxCopySid(Info.Data.SID, Sid).SaveTo(Result).IsSuccess then
      Sid := nil;

    if Result.IsSuccess then
      LogonType := Info.Data.LogonType
    else
    begin
      // Check if we know the SID from logon ID
      Sid := LsaxLookupKnownLogonSessionSid(Luids[i]);
      LogonType := TSecurityLogonType.UndefinedLogonType;
    end;

    if Assigned(Sid) then
      Nodes[i] := TLogonSessionSidNode.Create(Luids[i], LogonType, Sid)
    else
      Nodes[i] := TLogonSessionErrorNode.Create(Luids[i], Result);
  end;

  // Perform bulk SID lookup and attach it
  AttachLookup(Nodes);
  Result := NtxSuccess;
end;

end.
