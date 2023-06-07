unit NtUiBackend.UserProfiles;

{
  This module provides logic for the user profile list dialog
}

interface

uses
  DevirtualizedTree, NtUtils.Profiles, NtUtils;

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
    function GetInfo: TProfileInfo;
    property Info: TProfileInfo read GetInfo;
  end;

// Populate a user profile node from its information
function UiLibMakeProfileNode(
  const Info: TProfileInfo
): IProfileNode;

// Enumerate user profiles and convert them into node providers
function UiLibEnumerateProfiles(
  out Providers: TArray<IProfileNode>
): TNtxStatus;

implementation

uses
  DevirtualizedTree.Provider, NtUtils.Security.Sid, DelphiUiLib.Reflection,
  DelphiUiLib.Reflection.Strings, UI.Colors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TProfileNode }

type
  TProfileNode = class (TNodeProvider, IProfileNode)
  private
    FInfo: TProfileInfo;
  protected
    procedure Initialize; override;
  public
    function GetInfo: TProfileInfo;
    constructor Create(
      const Info: TProfileInfo
    );
  end;

constructor TProfileNode.Create;
begin
  inherited Create(colMax);
  FInfo := Info;
end;

function TProfileNode.GetInfo;
begin
  Result := FInfo;
end;

procedure TProfileNode.Initialize;
var
  UserRepresentation: TRepresentation;
begin
  inherited;

  UserRepresentation := TType.Represent(FInfo.User);
  FColumnText[colUserName] := UserRepresentation.Text;
  FColumnText[colSID] := RtlxSidToString(FInfo.User);
  FColumnText[colPath] := FInfo.ProfilePath;
  FColumnText[colFullProfile] := YesNoToString(FInfo.FullProfile);
  FColumnText[colLoaded] := YesNoToString(FInfo.IsLoaded);
  FHint := UserRepresentation.Hint;

  if FInfo.ProfilePath <> '' then
  begin
    FHasColor := True;

    if FInfo.FullProfile then
      FColor := ColorSettings.clUser
    else
      FColor := ColorSettings.clSystem;

    if not FInfo.IsLoaded then
    begin
      FHasFontColor := True;
      FFontColor := ColorSettings.clHidden;
    end;

    FHint := FHint + #$D#$A + BuildHint([
      THintSection.New('Profile Path', FColumnText[colPath]),
      THintSection.New('Loaded', FColumnText[colLoaded])
    ]);
  end;
end;

{ Functions }

function UiLibMakeProfileNode;
begin
  Result := TProfileNode.Create(Info);
end;

function UiLibEnumerateProfiles;
var
  Sids: TArray<ISid>;
  Info: TProfileInfo;
  i: Integer;
begin
  Result := UnvxEnumerateProfiles(Sids);

  if not Result.IsSuccess then
    Exit;

  SetLength(Providers, Length(Sids));

  for i := 0 to High(Sids) do
  begin
    UnvxQueryProfile(Sids[i], Info);
    Providers[i] := UiLibMakeProfileNode(Info);
  end;
end;

end.
