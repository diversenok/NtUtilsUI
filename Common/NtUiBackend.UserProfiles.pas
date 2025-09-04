unit NtUiBackend.UserProfiles;

{
  This module provides logic for the user profile list dialog
}

interface

uses
  DevirtualizedTree, NtUtils.Profiles, NtUtils, NtUiCommon.Prototypes;

const
  colUserName = 0;
  colSID = 1;
  colPath = 2;
  colFullProfile = 3;
  colLoaded = 4;
  colMax = 5;

type
  IProfileNode = interface (INodeProvider)
    ['{3FEAB0A3-69D5-45EA-AA34-F35FBDC60E57}']
    function GetInfo: TNtUiLibProfileInfo;
    property Info: TNtUiLibProfileInfo read GetInfo;
  end;

// Enumerate user profiles and convert them into node providers
function UiLibEnumerateProfiles(
  out Providers: TArray<IProfileNode>
): TNtxStatus;

implementation

uses
  DelphiApi.Reflection, DevirtualizedTree.Provider, NtUtils.Security.Sid,
  DelphiUiLib.Reflection, DelphiUiLib.Strings, NtUiCommon.Colors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TProfileNode }

type
  TProfileNode = class (TNodeProvider, IProfileNode)
  private
    FUser: ISid;
    FListKey: IHandle;
    FIsLoaded: Boolean;
  protected
    procedure Initialize; override;
  public
    function GetInfo: TNtUiLibProfileInfo;
    constructor Create(
      const User: ISid
    );
  end;

constructor TProfileNode.Create;
begin
  inherited Create(colMax);
  FUser := User;
end;

function TProfileNode.GetInfo;
begin
  Result.User := FUser;
  Result.hxListKey := FListKey;
end;

procedure TProfileNode.Initialize;
var
  UserRepresentation: TRepresentation;
  FullProfile: LongBool;
  ProfilePath: String;
begin
  inherited;

  RtlxOpenProfileListKey(FUser, FListKey);
  FIsLoaded := RtlxIsProfileLoaded(FUser);
  ProfilePath := '';

  if Assigned(FListKey) then
  begin
    if not RtlxQueryProfileIsFullProfile(FListKey, FullProfile).IsSuccess then
      FullProfile := False;

    FColumnText[colFullProfile] := BooleanToString(FullProfile, bkYesNo);

    if FullProfile then
      SetColor(ColorSettings.clBackgroundUser)
    else
      SetColor(ColorSettings.clBackgroundSystem);

    if RtlxQueryProfilePath(FListKey, ProfilePath).IsSuccess then
      FColumnText[colPath] := ProfilePath;
  end;

  UserRepresentation := TType.Represent(FUser);
  FColumnText[colUserName] := UserRepresentation.Text;
  FColumnText[colSID] := RtlxSidToString(FUser);
  FColumnText[colLoaded] := BooleanToString(FIsLoaded, bkYesNo);

  FHint := UserRepresentation.Hint + #$D#$A + BuildHint([
    THintSection.New('Profile Path', FColumnText[colPath]),
    THintSection.New('Loaded', FColumnText[colLoaded])
  ]);

  if not FIsLoaded then
    SetFontColor(ColorSettings.clForegroundInactive);
end;

{ Functions }

function UiLibEnumerateProfiles;
var
  Sids: TArray<ISid>;
  i: Integer;
begin
  Result := RtlxEnumerateProfiles(Sids);

  if not Result.IsSuccess then
    Exit;

  SetLength(Providers, Length(Sids));

  for i := 0 to High(Sids) do
    Providers[i] := TProfileNode.Create(Sids[i]);
end;

end.
