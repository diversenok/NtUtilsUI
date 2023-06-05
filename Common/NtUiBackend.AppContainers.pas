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
  IAppContainerNode = interface (INodeProvider)
    ['{AF1E4CBD-1752-4655-8C13-D6B0D18AFE3D}']
    function GetInfo: TAppContainerInfo;
    property Info: TAppContainerInfo read GetInfo;
  end;

// Populate an AppContainer node from its information
function UiLibMakeAppContainerNode(
  const Info: TAppContainerInfo
): IAppContainerNode;

function UiLibEnumerateAppContainers(
  out Providers: TArray<IAppContainerNode>;
  const User: ISid;
  [opt] const ParentSid: ISid = nil
): TNtxStatus;

implementation

uses
  DevirtualizedTree.Provider, NtUtils.SysUtils, NtUtils.Security.Sid,
  NtUtils.Packages, DelphiUiLib.Reflection.Strings, UI.Colors;

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
  FColumnText[colMoniker] := RtlxStringOrDefault(FInfo.Moniker, 'Unknown');

  if FInfo.Moniker <> '' then
  begin
    IsPackage := PkgxIsValidFamilyName(FInfo.Moniker);
    FColumnText[colIsPackage] := YesNoToString(IsPackage);
    FColumnText[colDisplayName] := RtlxStringOrDefault(FInfo.DisplayName, '(None)');
    FColumnText[colFriendlyName] := FInfo.DisplayName;

    if RtlxPrefixString('@{', FInfo.DisplayName, True) then
      PkgxExpandResourceStringVar(FColumnText[colFriendlyName]);

    FColumnText[colFriendlyName] := RtlxStringOrDefault(
      FColumnText[colFriendlyName], '(None)');

     FHasColor := True;

    if IsPackage then
      FColor := ColorSettings.clSystem
    else
      FColor := ColorSettings.clUser;

    FHint := BuildHint([
      THintSection.New('Friendly Name', FColumnText[colFriendlyName]),
      THintSection.New('Monker', FColumnText[colMoniker]),
      THintSection.New('SID', FColumnText[colSID])
    ]);
  end
  else
  begin
    FColumnText[colFriendlyName] := 'Unknown';
    FColumnText[colDisplayName] := 'Unknown';
    FColumnText[colIsPackage] := 'Unknown';
  end;
end;

{ Function }

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
    if not RtlxQueryAppContainer(Info, Sids[i], User).IsSuccess then
    begin
      Info := Default(TAppContainerInfo);
      Info.Sid := Sids[i];
    end;

    Providers[i] := UiLibMakeAppContainerNode(Info);
  end;
end;

end.
