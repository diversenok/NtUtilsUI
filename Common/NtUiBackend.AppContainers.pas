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
  TAppContainerInfo = NtUtils.Security.AppContainer.TAppContainerInfo;

  TAppContainerInfoHelper = record helper for TAppContainerInfo
    function Hint: String;
  end;

  IAppContainerNode = interface (INodeProvider)
    ['{AF1E4CBD-1752-4655-8C13-D6B0D18AFE3D}']
    function GetInfo: TAppContainerInfo;
    property Info: TAppContainerInfo read GetInfo;
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
  const Info: TAppContainerInfo
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
  const Info: TAppContainerInfo
);

// Invoke the inspect menu on a property node
procedure UiLibInspectAppContainerProperty(
  const Info: TAppContainerInfo;
  NodeIndex: Integer
);

implementation

uses
  Ntapi.ntseapi, NtUtils.SysUtils, NtUtils.Security.Sid, NtUtils.Tokens,
  NtUtils.Tokens.Info, NtUtils.Packages, NtUtils.Profiles, Vcl.Graphics,
  Vcl.Controls, DevirtualizedTree.Provider, NtUiLib.Errors,
  DelphiUiLib.Reflection.Strings, UI.Colors, UI.Helper, NtUiCommon.Prototypes;

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
    FInfo: TAppContainerInfo;
  protected
    procedure Initialize; override;
  public
    function GetInfo: TAppContainerInfo;
    constructor Create(
      const Info: TAppContainerInfo
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
    FHasColor := True;

    if IsPackage then
      FColor := ColorSettings.clSystem
    else
      FColor := ColorSettings.clUser;
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
  Info: TAppContainerInfo;
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

procedure UiLibMakeAppContainerPropertyNodes(
  Tree: TDevirtualizedTree;
  const Info: TAppContainerInfo
);
var
  Node: IEditableNodeProvider;
  ParentSid: ISid;
  Status: TNtxStatus;
  IsPackage: Boolean;
  FolderPath: String;
  CurrentUser: ISid;
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
      Node.FontColorForColumn[1] := clHotLight;
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

  if NtxQuerySidToken(NtxCurrentEffectiveToken, TokenUser,
    CurrentUser).IsSuccess and RtlxEqualSids(CurrentUser, Info.User) then
  begin
    // Querying folder only works for on current user
    Status := UnvxQueryFolderAppContainer(Info.Sid, FolderPath);

    if Status.IsSuccess then
      Node.ColumnText[1] := FolderPath
    else
    begin
      Node.ColumnText[1] := '<Unable to query>';
      Node.Hint := Status.ToString;
    end;
  end
  else
  begin
    Node.ColumnText[1] := '<Unable to query>';
    Node.Hint := 'Cannot query information for another user';
  end;

  Tree.AddChildEx(nil, Node);
end;

procedure UiLibInspectAppContainerProperty;
var
  ParentSid: ISid;
  ParentInfo: TAppContainerInfo;
begin
  if not Assigned(NtUiLibShowAppContainer) or (NodeIndex <> 2) then
    Exit;

  RtlxGetAppContainerParent(Info.Sid, ParentSid).RaiseOnError;
  RtlxQueryAppContainer(ParentInfo, ParentSid, Info.User).RaiseOnError;
  NtUiLibShowAppContainer(ParentInfo);
end;

end.
