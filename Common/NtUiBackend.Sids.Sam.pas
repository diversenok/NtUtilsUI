unit NtUiBackend.Sids.Sam;

{
  This unit provides the logic traversing SAM domains.
}

interface

uses
  NtUtils, DevirtualizedTree, NtUiBackend.Sids, DelphiApi.Reflection;

type
  [NamingStyle(nsCamelCase, 'sn'), Range(1)]
  TSamNodeKind = (
    snInvalid = 0,
    snDomain,
    snGroup,
    snAlias,
    snUser
  );

  ISamErrorNode = interface (INodeProvider)
    ['{63D6B49D-DC26-4ECC-9969-B01784ADDD66}']
    function GetCaption: String;
    function GetStatus: TNtxStatus;
    function GetKind: TSamNodeKind;
    property Caption: String read GetCaption;
    property Status: TNtxStatus read GetStatus;
    property Kind: TSamNodeKind read GetKind;
  end;

  ISamSidNode = interface (ISidNode)
    ['{F611C86D-42B6-44C0-8634-118F47026395}']
    function GetName: String;
    function GetKind: TSamNodeKind;
    property Name: String read GetName;
    property Kind: TSamNodeKind read GetKind;
  end;

  TSamDomainNodes = record
    Domain: INodeProvider;
    Groups: TArray<INodeProvider>;
    Aliases: TArray<INodeProvider>;
    Users: TArray<INodeProvider>;
  end;

function NtUiLibCollectSamNodes(
  out Nodes: TArray<TSamDomainNodes>
): TNtxStatus;

implementation

uses
  Ntapi.ntsam, NtUtils.Sam, NtUtils.SysUtils, NtUtils.Security.Sid,
  NtUtils.Lsa.Sid, NtUtils.Errors, NtUiLib.Errors, DelphiUiLib.Reflection,
  DelphiUiLib.Reflection.Strings, DevirtualizedTree.Provider, UI.Colors;

const
  colName = 0;
  colAccountType = 1;
  colSid = 2;
  colSidFullName = 3;
  colSidType = 4;
  colMax = 5;

type
  ISamSidNodeInternal = interface (ISamSidNode)
    ['{ECDB6F8C-87FD-489A-B671-389E4A580054}']
    procedure SetSidName(const Value: TTranslatedName);
  end;

  TSamErrorNode = class (TNodeProvider, ISamErrorNode)
  private
    FCaption: String;
    FStatus: TNtxStatus;
    FKind: TSamNodeKind;
  protected
    procedure Initialize; override;
    function GetCaption: String;
    function GetStatus: TNtxStatus;
    function GetKind: TSamNodeKind;
  public
    constructor Create(
      const Name: String;
      const Status: TNtxStatus;
      Kind: TSamNodeKind  = snInvalid
    );
  end;

  TSamSidNode = class (TNodeProvider, ISamSidNode, ISamSidNodeInternal)
  private
    FName: String;
    FFullName: String;
    FKind: TSamNodeKind;
    FSidName: TTranslatedName;
  protected
    procedure Initialize; override;
    function GetName: String;
    function GetKind: TSamNodeKind;
    function GetSidName: TTranslatedName;
    procedure SetSidName(const Value: TTranslatedName);
  public
    constructor Create(
      const Name: String;
      const FullName: String;
      const Sid: ISid;
      Kind: TSamNodeKind
    );
  end;

{ TSamErrorNode }

constructor TSamErrorNode.Create;
begin
  inherited Create(colMax);
  FCaption:= Name;
  FStatus := Status;
  FKind := Kind;
end;

function TSamErrorNode.GetCaption;
begin
  Result := FCaption;
end;

function TSamErrorNode.GetKind;
begin
  Result := FKind;
end;

function TSamErrorNode.GetStatus;
begin
  Result := FStatus;
end;

procedure TSamErrorNode.Initialize;
begin
  inherited;
  FColumnText[colName] := FCaption;

  if FKind <> snInvalid then
  begin
    FColumnText[colAccountType] := TType.Represent(FKind).Text;;
    FColumnText[colSid] := '<unable to query>';
  end;

  FHint := FStatus.ToString;
  SetFontColor(ColorSettings.clForegroundError);
end;

{ TSamSidNode }

constructor TSamSidNode.Create;
begin
  inherited Create(colMax);
  FName := Name;
  FFullName := FullName;
  FKind := Kind;
  FSidName.SID := Sid;
end;

function TSamSidNode.GetKind;
begin
  Result := FKind;
end;

function TSamSidNode.GetName;
begin
  Result := FName;
end;

function TSamSidNode.GetSidName;
begin
  Result := FSidName;
end;

procedure TSamSidNode.Initialize;
begin
  inherited;

  FColumnText[colName] := FName;
  FColumnText[colAccountType] := TType.Represent(FKind).Text;
  FColumnText[colSid] := RtlxSidToString(FSidName.Sid);

  if FSidName.IsValid then
  begin
    FColumnText[colSidType] := TType.Represent(FSidName.SidType).Text;
    FColumnText[colSidFullName] := FSidName.FullName;
  end;

  FHint := BuildHint([
    THintSection.New('Full Name', FFullName),
    THintSection.New('Account Type', FColumnText[colAccountType]),
    THintSection.New('SID', FColumnText[colSid])
  ]);
end;

procedure TSamSidNode.SetSidName;
begin
  FSidName := Value;
end;

{ Functions }

function MakeSamMemberNodes(
  const DomainName: String;
  const DomainSid: ISid;
  const Members: TArray<TRidAndName>;
  Kind: TSamNodeKind
): TArray<INodeProvider>;
var
  Status: TNtxStatus;
  MemberSid: ISid;
  i: Integer;
begin
  SetLength(Result, Length(Members));

  for i := 0 to High(Members) do
  begin
    // Deriver member SID
    Status := RtlxMakeChildSid(MemberSid, DomainSid, Members[i].RelativeID);

    if Status.IsSuccess then
      Result[i] := TSamSidNode.Create(Members[i].Name, RtlxCombinePaths(
        DomainName, Members[i].Name), MemberSid, Kind)
    else
      Result[i] := TSamErrorNode.Create(Members[i].Name, Status);
  end;
end;

procedure AttachLookup(
  const Nodes: TArray<TSamDomainNodes>
);
var
  SIDs: TArray<ISid>;
  Names: TArray<TTranslatedName>;
  TranslatedNodes: TArray<ISamSidNodeInternal>;
  i, j, Count: Integer;
  Node: ISamSidNodeInternal;
begin
  Count := 0;

  // Count non-error nodes
  for i := 0 to High(Nodes) do
  begin
    // Domain
    if Nodes[i].Domain.QueryInterface(ISamSidNodeInternal, Node).IsSuccess then
      Inc(Count);

    // Groups
    for j := 0 to High(Nodes[i].Groups) do
      if Nodes[i].Groups[j].QueryInterface(ISamSidNodeInternal,
        Node).IsSuccess then
        Inc(Count);

    // Aliases
    for j := 0 to High(Nodes[i].Aliases) do
      if Nodes[i].Aliases[j].QueryInterface(ISamSidNodeInternal,
        Node).IsSuccess then
        Inc(Count);

    // Users
    for j := 0 to High(Nodes[i].Users) do
      if Nodes[i].Users[j].QueryInterface(ISamSidNodeInternal,
        Node).IsSuccess then
        Inc(Count);
  end;

  // Collect their SIDs
  SetLength(SIDs, Count);
  SetLength(TranslatedNodes, Count);
  Count := 0;

  for i := 0 to High(Nodes) do
  begin
    // Domain
    if Nodes[i].Domain.QueryInterface(ISamSidNodeInternal, Node).IsSuccess then
    begin
      SIDs[Count] := Node.SidName.SID;
      TranslatedNodes[Count] := Node;
      Inc(Count);
    end;

    // Groups
    for j := 0 to High(Nodes[i].Groups) do
      if Nodes[i].Groups[j].QueryInterface(ISamSidNodeInternal,
        Node).IsSuccess then
      begin
        SIDs[Count] := Node.SidName.SID;
        TranslatedNodes[Count] := Node;
        Inc(Count);
      end;

    // Aliases
    for j := 0 to High(Nodes[i].Aliases) do
      if Nodes[i].Aliases[j].QueryInterface(ISamSidNodeInternal,
        Node).IsSuccess then
      begin
        SIDs[Count] := Node.SidName.SID;
        TranslatedNodes[Count] := Node;
        Inc(Count);
      end;

    // Users
    for j := 0 to High(Nodes[i].Users) do
      if Nodes[i].Users[j].QueryInterface(ISamSidNodeInternal,
        Node).IsSuccess then
      begin
        SIDs[Count] := Node.SidName.SID;
        TranslatedNodes[Count] := Node;
        Inc(Count);
      end;
  end;

  // Perform bulk lookup and attach it to nodes
  LsaxLookupSids(SIDs, Names);

  for i := 0 to High(TranslatedNodes) do
    TranslatedNodes[i].SetSidName(Names[i]);
end;

function NtUiLibCollectSamNodes;
const
  MSG_ERROR_GROUPS = '<unable to enumerate groups>';
  MSG_ERROR_ALIASES = '<unable to enumerate aliases>';
  MSG_ERROR_USERS = '<unable to enumerate users>';
var
  hxServer, hxDomain: ISamHandle;
  DomainNames: TArray<String>;
  DomainSid: ISid;
  Members: TArray<TRidAndName>;
  i: Integer;
begin
  Result := SamxConnect(hxServer, SAM_SERVER_ENUMERATE_DOMAINS or
    SAM_SERVER_LOOKUP_DOMAIN);

  if not Result.IsSuccess then
    Exit;

  // Collect all domain names
  Result := SamxEnumerateDomains(DomainNames, hxServer);

  if not Result.IsSuccess then
    Exit;

  Nodes := nil;
  SetLength(Nodes, Length(DomainNames));

  for i := 0 to High(DomainNames) do
  begin
    // Convert the name into a SID
    Result := SamxLookupDomain(DomainNames[i], DomainSid, hxServer);

    if not Result.IsSuccess then
    begin
      // At least add a placeholder on failure
      Nodes[i].Domain := TSamErrorNode.Create(DomainNames[i], Result, snDomain);
      Continue;
    end;

    // Add the normal domain node
    Nodes[i].Domain := TSamSidNode.Create(DomainNames[i], DomainNames[i],
      DomainSid, snDomain);

    // Open for group/aliast/user enumeration
    Result := SamxOpenDomainByName(hxDomain, DomainNames[i],
      DOMAIN_LIST_ACCOUNTS, hxServer);

    if not Result.IsSuccess then
    begin
      // Add placeholders on error
      Nodes[i].Groups := [TSamErrorNode.Create(MSG_ERROR_GROUPS, Result)];
      Nodes[i].Aliases := [TSamErrorNode.Create(MSG_ERROR_ALIASES, Result)];
      Nodes[i].Users := [TSamErrorNode.Create(MSG_ERROR_USERS, Result)];
      Continue;
    end;

    // Groups
    Result := SamxEnumerateGroups(hxDomain, Members);

    if not Result.IsSuccess then
      Nodes[i].Groups := [TSamErrorNode.Create(MSG_ERROR_GROUPS, Result)]
    else
      Nodes[i].Groups := MakeSamMemberNodes(DomainNames[i], DomainSid, Members,
        snGroup);

    // Aliases
    Result := SamxEnumerateAliases(hxDomain, Members);

    if not Result.IsSuccess then
      Nodes[i].Aliases := [TSamErrorNode.Create(MSG_ERROR_ALIASES, Result)]
    else
      Nodes[i].Aliases := MakeSamMemberNodes(DomainNames[i], DomainSid, Members,
        snAlias);

    // Users
    Result := SamxEnumerateUsers(hxDomain, Members);

    if not Result.IsSuccess then
      Nodes[i].Users := [TSamErrorNode.Create(MSG_ERROR_USERS, Result)]
    else
      Nodes[i].Users := MakeSamMemberNodes(DomainNames[i], DomainSid, Members,
        snUser);
  end;

  // Translate names and return
  AttachLookup(Nodes);
  Result := NtxSuccess;
end;

end.
