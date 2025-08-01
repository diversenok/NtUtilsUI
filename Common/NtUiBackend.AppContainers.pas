unit NtUiBackend.AppContainers;

{
  This module provides logic for the AppContainer list dialog
}

interface

uses
  DevirtualizedTree, NtUtils.Security.AppContainer, NtUtils;

const
  colFriendlyName = 0;
  colDisplayName = 1;
  colMoniker = 2;
  colIsPackage = 3;
  colSID = 4;
  colMax = 5;

type
  TRtlxAppContainerInfo = NtUtils.Security.AppContainer.TRtlxAppContainerInfo;

  TAppContainerInfoHelper = record helper for TRtlxAppContainerInfo
    function Hint: String;
  end;

  IAppContainerNode = interface (INodeProvider)
    ['{AF1E4CBD-1752-4655-8C13-D6B0D18AFE3D}']
    function GetInfo: TRtlxAppContainerInfo;
    property Info: TRtlxAppContainerInfo read GetInfo;
  end;

// Derive AppContainer SID from name or SID
[MayReturnNil]
function UiLibDeriveAppContainer(
  const FullMonikerOrSid: String
): ISid;

// Get the current effective user to use as a default
function UiLibGetDefaultUser: ISid;

// Populate an AppContainer node from its information
function UiLibMakeAppContainerNode(
  const Info: TRtlxAppContainerInfo
): IAppContainerNode;

// Enumerate AppContainers and convert them into node providers
function UiLibEnumerateAppContainers(
  out Providers: TArray<IAppContainerNode>;
  const User: ISid;
  [opt] const ParentSid: ISid = nil
): TNtxStatus;

// Add property nodes for AppContainer
procedure UiLibMakeAppContainerPropertyNodes(
  Tree: TDevirtualizedTree;
  const Info: TRtlxAppContainerInfo
);

// Invoke the inspect menu on a property node
procedure UiLibInspectAppContainerProperty(
  const Info: TRtlxAppContainerInfo;
  NodeIndex: Integer
);

implementation

uses
  Ntapi.ntseapi, NtUtils.SysUtils, NtUtils.Security.Sid, NtUtils.Tokens,
  NtUtils.Tokens.Info, NtUtils.Packages, NtUtils.Profiles, Vcl.Graphics,
  Vcl.Controls, DevirtualizedTree.Provider, NtUiLib.Errors,
  DelphiUiLib.Reflection.Strings, NtUiCommon.Colors, NtUiCommon.Helpers,
  NtUiCommon.Prototypes, NtUtils.Profiles.AppContainer;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TAppContainerInfoHelper }

function TAppContainerInfoHelper.Hint;
begin
  Result := BuildHint([
    THintSection.New('Friendly Name', RtlxStringOrDefault(FriendlyName, '(Unknown)')),
    THintSection.New('Full Moniker', RtlxStringOrDefault(FullMoniker, '(Unknown)')),
    THintSection.New('SID', RtlxSidToString(Sid))
  ]);
end;

{ TAppContainerNode }

type
  TAppContainerNode = class (TNodeProvider, IAppContainerNode)
  private
    FInfo: TRtlxAppContainerInfo;
  protected
    procedure Initialize; override;
  public
    function GetInfo: TRtlxAppContainerInfo;
    constructor Create(
      const Info: TRtlxAppContainerInfo
    );
  end;

constructor TAppContainerNode.Create;
begin
  inherited Create(colMax);
  FInfo := Info;
end;

function TAppContainerNode.GetInfo;
begin
  Result := FInfo;
end;

procedure TAppContainerNode.Initialize;
var
  IsPackage: Boolean;
begin
  inherited;

  FColumnText[colSID] := RtlxSidToString(FInfo.Sid);
  FColumnText[colMoniker] := RtlxStringOrDefault(FInfo.Moniker, '(Unknown)');

  if FInfo.Moniker <> '' then
  begin
    IsPackage := PkgxIsValidFamilyName(FInfo.Moniker);
    FColumnText[colIsPackage] := YesNoToString(IsPackage);
    FColumnText[colDisplayName] := RtlxStringOrDefault(FInfo.DisplayName, '(None)');
    FColumnText[colFriendlyName] := RtlxStringOrDefault(FInfo.FriendlyName, '(None)');
    FColumnText[colFriendlyName] := RtlxStringOrDefault(FColumnText[colFriendlyName], '(None)');
    FHint := FInfo.Hint;

    if IsPackage then
      SetColor(ColorSettings.clBackgroundSystem)
    else
      SetColor(ColorSettings.clBackgroundUser);
  end
  else
  begin
    FColumnText[colFriendlyName] := '(Unknown)';
    FColumnText[colDisplayName] := '(Unknown)';
    FColumnText[colIsPackage] := '(Unknown)';
  end;
end;

{ Functions }

function UiLibDeriveAppContainer;
begin
  if FullMonikerOrSid = '' then
    Exit(nil);

  // Derive/convert the SID from text
  if RtlxPrefixString('S-1-', FullMonikerOrSid) then
    RtlxStringToSid(FullMonikerOrSid, Result).RaiseOnError
  else
    RtlxDeriveFullAppContainerSid(FullMonikerOrSid, Result).RaiseOnError;
end;

function UiLibGetDefaultUser;
begin
  NtxQuerySidToken(NtxCurrentEffectiveToken, TokenUser, Result).RaiseOnError;
end;

function UiLibMakeAppContainerNode;
begin
  Result := TAppContainerNode.Create(Info);
end;

function UiLibEnumerateAppContainers;
var
  Sids: TArray<ISid>;
  Info: TRtlxAppContainerInfo;
  i: Integer;
begin
  Result := RtlxEnumerateAppContainerSIDs(Sids, ParentSid, User);

  if not Result.IsSuccess then
    Exit;

  SetLength(Providers, Length(Sids));

  for i := 0 to High(Sids) do
  begin
    RtlxQueryAppContainer(Info, Sids[i], User);
    Providers[i] := UiLibMakeAppContainerNode(Info);
  end;
end;

procedure UiLibMakeAppContainerPropertyNodes;
var
  Node: IEditableNodeProvider;
  ParentSid: ISid;
  Status: TNtxStatus;
  IsPackage: Boolean;
  FolderPath: String;
begin
  Tree.BeginUpdateAuto;
  Tree.Clear;

  IsPackage := not Info.IsChild and PkgxIsValidFamilyName(Info.Moniker);

  // Type
  Node := TEditableNodeProvider.Create(2);
  Node.EnabledMainActionMenu := False;
  Node.ColumnText[0] := 'Type';

  if IsPackage then
    Node.ColumnText[1] := 'Package AppContainer'
  else if Info.IsChild then
    Node.ColumnText[1] := 'Child AppContainer'
  else
    Node.ColumnText[1] := 'Parent AppContainer';

  Tree.AddChildEx(nil, Node);

  // SID
  Node := TEditableNodeProvider.Create(2);
  Node.EnabledMainActionMenu := False;
  Node.ColumnText[0] := 'SID';
  Node.ColumnText[1] := RtlxSidToString(Info.Sid);
  Tree.AddChildEx(nil, Node);

  // Parent SID
  Node := TEditableNodeProvider.Create(2);
  Node.EnabledMainActionMenu := False;
  Node.ColumnText[0] := 'Parent SID';

  if Info.IsChild then
  begin
    Status := RtlxGetAppContainerParent(Info.Sid, ParentSid);

    if Status.IsSuccess then
    begin
      Node.ColumnText[1] := RtlxSidToString(ParentSid);
      Node.FontStyleForColumn[1] := [TFontStyle.fsUnderline];
      Node.FontColorForColumn[1] := ColorSettings.clForegroundLink;
      Node.Cursor := crHandPoint;
      Node.EnabledMainActionMenu := True;
    end
    else
    begin
      Node.ColumnText[1] := '<Unable to query>';
      Node.Hint := Status.ToString;
    end;
  end
  else
    Node.ColumnText[1] := 'N/A';

  Tree.AddChildEx(nil, Node);

  // Full moniker
  Node := TEditableNodeProvider.Create(2);
  Node.EnabledMainActionMenu := False;
  Node.ColumnText[0] := 'Full Moniker';
  Node.ColumnText[1] := Info.FullMoniker;
  Tree.AddChildEx(nil, Node);

  // Display name
  Node := TEditableNodeProvider.Create(2);
  Node.EnabledMainActionMenu := False;
  Node.ColumnText[0] := 'Display Name';
  Node.ColumnText[1] := Info.DisplayName;
  Tree.AddChildEx(nil, Node);

  // Friendly name
  Node := TEditableNodeProvider.Create(2);
  Node.EnabledMainActionMenu := False;
  Node.ColumnText[0] := 'Friendly Name';
  Node.ColumnText[1] := Info.FriendlyName;
  Tree.AddChildEx(nil, Node);

  // Registry path
  Node := TEditableNodeProvider.Create(2);
  Node.EnabledMainActionMenu := False;
  Node.ColumnText[0] := 'Registry Path';
  Node.ColumnText[1] := RtlxQueryStoragePathAppContainer(Info);
  Tree.AddChildEx(nil, Node);

  // File path
  Node := TEditableNodeProvider.Create(2);
  Node.EnabledMainActionMenu := False;
  Node.ColumnText[0] := 'File Path';

  Status := UnvxQueryAppContainerPath(FolderPath, Info.User, Info.Sid);

  if Status.IsSuccess then
    Node.ColumnText[1] := FolderPath
  else
  begin
    Node.ColumnText[1] := '<Failed to query>';
    Node.Hint := Status.ToString;
  end;

  Tree.AddChildEx(nil, Node);
end;

procedure UiLibInspectAppContainerProperty;
var
  ParentSid: ISid;
  ParentInfo: TRtlxAppContainerInfo;
begin
  if not Assigned(NtUiLibShowAppContainer) or (NodeIndex <> 2) then
    Exit;

  RtlxGetAppContainerParent(Info.Sid, ParentSid).RaiseOnError;
  RtlxQueryAppContainer(ParentInfo, ParentSid, Info.User).RaiseOnError;
  NtUiLibShowAppContainer(ParentInfo);
end;

end.
