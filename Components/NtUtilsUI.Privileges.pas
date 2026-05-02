unit NtUtilsUI.Privileges;

{
  This module contains the full runtime component definition for a privilege
  list control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, Vcl.Menus, NtUtilsUI.Base, NtUtilsUI.Tree,
  NtUtilsUI.Tree.Search, NtUtilsUI.Components, Ntapi.ntseapi;

type
  TUiLibPrivilegeListMode = (pmNormal, pmAdding, pmRemoving);

  TUiLibPrivilegeList = class (TUiLibControl)
  private
    FSearch: TUiLibTreeSearchBox;
    FTree: TUiLibTree;
    FMode: TUiLibPrivilegeListMode;
    function GetPrivileges: TArray<TPrivilege>;
    procedure SetPrivileges(const Values: TArray<TPrivilege>);
    function GetSelectedPrivileges: TArray<TPrivilege>;
    function GetCheckedPrivileges: TArray<TPrivilege>;
    procedure SetCheckedPrivileges(const Values: TArray<TPrivilege>);
    procedure SetMode(const Value: TUiLibPrivilegeListMode);
    function GetPopupMenu: TPopupMenu; reintroduce;
    procedure SetPopupMenu(const Value: TPopupMenu);
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadAllPrivileges;
    procedure AdjustSelected(NewAttributes: TPrivilegeAttributes);
    property Privileges: TArray<TPrivilege> read GetPrivileges write SetPrivileges;
    property SelectedPrivileges: TArray<TPrivilege> read GetSelectedPrivileges;
    property CheckedPrivileges: TArray<TPrivilege> read GetCheckedPrivileges write SetCheckedPrivileges;
    class function Factory(Privileges: TArray<TPrivilege>): TWinControlFactory; static;
    class function FactoryAll: TWinControlFactory; static;
    class procedure Show(const Privileges: TArray<TPrivilege>); static;
    class procedure ShowAll; static;
  published
    property Mode: TUiLibPrivilegeListMode read FMode write SetMode;
    property PopupMenu: TPopupMenu read GetPopupMenu write SetPopupMenu;
  end;

implementation

uses
  Vcl.Controls, Vcl.Graphics, VirtualTrees, VirtualTrees.Types,
  VirtualTrees.Header, Ntapi.WinNt, Ntapi.ntlsa, NtUtils, NtUtils.SysUtils,
  NtUtils.Lsa, DelphiUtils.Arrays, DelphiUiLib.Strings,
  DelphiUiLib.LiteReflection, NtUtilsUI;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

const
  colFriendly = 0;
  colName = 1;
  colValue = 2;
  colState = 3;
  colDescription = 4;
  colIntegrity = 5;
  colMax = 6;

type
  IPrivilege = interface (INodeProvider)
    ['{A4403219-F7CE-4B5D-A96D-6541DCEF549A}']
    function GetLuid: TLuid;
    function GetAttributes: TPrivilegeAttributes;
    procedure SetAttributes(Value: TPrivilegeAttributes);
    property Luid: TLuid read GetLuid;
    property Attributes: TPrivilegeAttributes read GetAttributes write SetAttributes;
  end;

  TPrivilegeProvider = class (TNodeProvider, IPrivilege)
  private
    FControl: TUiLibPrivilegeList;
    FPrivilege: TPrivilege;
    function GetLuid: TLuid;
    function GetAttributes: TPrivilegeAttributes;
    procedure SetAttributes(Value: TPrivilegeAttributes);
    function UseTextStyle: Boolean;
  protected
    function GetColor(out Value: TColor): Boolean; override;
    function GetFontColor(out Value: TColor): Boolean; override;
    function GetFontStyleForColumn(Column: TColumnIndex; out Value: TFontStyles): Boolean; override;
    function SearchNumber(const Value: UInt64; Column: TColumnIndex): Boolean; override;
    function SameEntity(Node: INodeProvider): Boolean; override;
  public
    constructor Create(
      Control: TUiLibPrivilegeList;
      const Privilege: TPrivilege;
      const hxPolicy: ILsaHandle = nil
    );
    class function CreateMany(
      Control: TUiLibPrivilegeList;
      const Privileges: TArray<TPrivilege>
    ): TArray<IPrivilege>; static;
  end;

function CollectPrivileges(
  const Enum: TVTVirtualNodeEnumeration
): TArray<TPrivilege>;
var
  Providers: TArray<IPrivilege>;
  i: Integer;
begin
  Providers := Enum.Providers<IPrivilege>;
  SetLength(Result, Length(Providers));

  for i := 0 to High(Result) do
  begin
    Result[i].Luid := Providers[i].Luid;
    Result[i].Attributes := Providers[i].Attributes;
  end;
end;

{ TPrivilegeProvider }

constructor TPrivilegeProvider.Create;
begin
  inherited Create(colMax);
  FControl := Control;
  FPrivilege := Privilege;
  FHasColor := True;

  FColumnText[colValue] := UiLibUIntToDec(Privilege.Luid);
  FColumnText[colIntegrity] := Rttix.Format(
    LsaxQueryIntegrityPrivilege(Privilege.Luid));

  // Try to query the name and the description from the system
  if LsaxQueryPrivilege(Privilege.Luid, FColumnText[colName],
    FColumnText[colDescription], hxPolicy).IsSuccess then
  begin
    FColumnText[colFriendly] := FColumnText[colName];
    RtlxPrefixStripString('Se', FColumnText[colFriendly], True);
    FColumnText[colFriendly] := RtlxPrettifyIdentifier(FColumnText[colFriendly]);

    FHint := BuildHint([
      THintSection.New('Friendly Name', FColumnText[colFriendly]),
      THintSection.New('Description', FColumnText[colDescription]),
      THintSection.New('Required Integrity', FColumnText[colIntegrity]),
      THintSection.New('Value', FColumnText[colValue])
    ]);
  end
  else
  begin
    // Otherwise, prepare names based on well-known privileges
    FColumnText[colFriendly] := Rttix.Format(
      TSeWellKnownPrivilege(Privilege.Luid));
  end;

  SetAttributes(Privilege.Attributes);
end;

class function TPrivilegeProvider.CreateMany;
var
  hxPolicy: ILsaHandle;
  i: Integer;
begin
  LsaxOpenPolicy(hxPolicy, POLICY_LOOKUP_NAMES);
  SetLength(Result, Length(Privileges));

  for i := 0 to High(Privileges) do
    Result[i] := TPrivilegeProvider.Create(Control, Privileges[i], hxPolicy);
end;

function TPrivilegeProvider.GetAttributes;
begin
  Result := FPrivilege.Attributes;
end;

function TPrivilegeProvider.GetColor;
begin
  Result := True;

  if BitTest(FPrivilege.Attributes and SE_PRIVILEGE_ENABLED) then
    if BitTest(FPrivilege.Attributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT) then
      Value := ColorSettings.clBackgroundAllow
    else
      Value := ColorSettings.clBackgroundAllowAccent
  else
    if BitTest(FPrivilege.Attributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT) then
      Value := ColorSettings.clBackgroundDenyAccent
    else
      Value := ColorSettings.clBackgroundDeny;
end;

function TPrivilegeProvider.GetFontColor;
begin
  Result := UseTextStyle;

  if Result then
    Value := ColorSettings.clForegroundInactive;
end;

function TPrivilegeProvider.GetFontStyleForColumn;
begin
  Result := (Column = colState) and UseTextStyle;

  if Result then
    Value := [fsStrikeOut];
end;

function TPrivilegeProvider.GetLuid;
begin
  Result := FPrivilege.Luid;
end;

function TPrivilegeProvider.SameEntity;
var
  AnotherPrivilege: IPrivilege;
begin
  Result := (Node.QueryInterface(IPrivilege, AnotherPrivilege) = S_OK)
   and (AnotherPrivilege.Luid = FPrivilege.Luid);
end;

function TPrivilegeProvider.SearchNumber;
begin
  Result := ((Column < 0) or (Column = colValue)) and (FPrivilege.Luid = Value);
end;

procedure TPrivilegeProvider.SetAttributes;
begin
  FPrivilege.Attributes := Value;
  FColumnText[colState] := Rttix.Format<TPrivilegeAttributesState>(Value);
  Invalidate;
end;

function TPrivilegeProvider.UseTextStyle;
begin
  Result := False;

  if Attached then
    case FControl.Mode of
      pmAdding:   Result := not FTree.CheckState[FNode].IsChecked;
      pmRemoving: Result := FTree.CheckState[FNode].IsChecked;
    end;
end;

{ TUiLibPrivilegeList }

procedure TUiLibPrivilegeList.AdjustSelected;
var
  Provider: IPrivilege;
begin
  FTree.BeginUpdateAuto;

  for Provider in FTree.SelectedNodes.Providers<IPrivilege> do
    Provider.Attributes := NewAttributes;
end;

constructor TUiLibPrivilegeList.Create;
var
  Column: TVirtualTreeColumn;
begin
  inherited;

  Width := 500;
  Height := 400;
  Constraints.MinHeight := 120;
  DoubleBuffered := True;

  FSearch := TUiLibTreeSearchBox.Create(Self);
  FSearch.Width := Width;
  FSearch.Align := alTop;
  FSearch.Parent := Self;

  FTree := TUiLibTree.Create(Self);
  FTree.Width := Width;
  FTree.Height := Height - FSearch.Height;
  FTree.Align := alClient;
  FTree.Header.Columns.BeginUpdate;

  Column := FTree.Header.Columns.Add;
  Column.Text := 'Friendly Name';
  Column.Width := 160;

  Column := FTree.Header.Columns.Add;
  Column.Text := 'Name';
  Column.Width := 140;
  Column.Options := Column.Options - [coVisible];

  Column := FTree.Header.Columns.Add;
  Column.Text := 'Value';
  Column.Width := 50;
  Column.Options := Column.Options - [coVisible];

  Column := FTree.Header.Columns.Add;
  Column.Text := 'State';
  Column.Width := 100;

  Column := FTree.Header.Columns.Add;
  Column.Text := 'Description';
  Column.Width := 200;

  Column := FTree.Header.Columns.Add;
  Column.Text := 'Required Integrity';
  Column.Width := 110;
  Column.Options := Column.Options - [coVisible];

  FTree.Header.AutoSizeIndex := colDescription;
  FTree.Header.Columns.EndUpdate;
  FTree.Parent := Self;
  FTree.TabOrder := 0;
  FSearch.AttachToTree(FTree);
end;

class function TUiLibPrivilegeList.Factory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      ResultRef : TUiLibPrivilegeList absolute Result;
    begin
      ResultRef := TUiLibPrivilegeList.Create(nil);
      try
        ResultRef.Privileges := Privileges;
      except
        ResultRef.Free;
        raise;
      end;
    end;
end;

class function TUiLibPrivilegeList.FactoryAll;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      ResultRef : TUiLibPrivilegeList absolute Result;
    begin
      ResultRef := TUiLibPrivilegeList.Create(nil);
      try
        ResultRef.LoadAllPrivileges;
      except
        ResultRef.Free;
        raise;
      end;
    end;
end;

function TUiLibPrivilegeList.GetCheckedPrivileges;
begin
  Result := CollectPrivileges(FTree.CheckedNodes);
end;

function TUiLibPrivilegeList.GetPopupMenu;
begin
  Result := FTree.PopupMenu;
end;

function TUiLibPrivilegeList.GetPrivileges;
begin
  Result := CollectPrivileges(FTree.Nodes);
end;

function TUiLibPrivilegeList.GetSelectedPrivileges;
begin
  Result := CollectPrivileges(FTree.SelectedNodes);
end;

procedure TUiLibPrivilegeList.LoadAllPrivileges;
var
  SeChangeNotify: TPrivilege;
begin
  SetPrivileges(TArray.Map<TLuid, TPrivilege>(
    LsaxEnumeratePrivilegesWithFallback,
    function (const Luid: TLuid): TPrivilege
    begin
      Result.Luid := Luid;
      Result.Attributes := SE_PRIVILEGE_ENABLED or
        SE_PRIVILEGE_ENABLED_BY_DEFAULT;
    end
  ));

  // Check only SeChangeNotify by default
  SeChangeNotify.Luid := TLuid(SE_CHANGE_NOTIFY_PRIVILEGE);
  SeChangeNotify.Attributes := SE_PRIVILEGE_ENABLED or
    SE_PRIVILEGE_ENABLED_BY_DEFAULT;
  SetCheckedPrivileges([SeChangeNotify]);
end;

procedure TUiLibPrivilegeList.SetCheckedPrivileges;
var
  i: Integer;
  Provider: IPrivilege;
begin
  FTree.BeginUpdateAuto;
  FTree.ClearChecked;

  for Provider in FTree.Nodes.Providers<IPrivilege> do
    for i := 0 to High(Values) do
      if Provider.Luid = Values[i].Luid then
        begin
          // Check the node and refresh its attributes
          FTree.CheckState[Provider.Node] := csCheckedNormal;
          Provider.Attributes := Values[i].Attributes;
          Break;
        end;
end;

procedure TUiLibPrivilegeList.SetMode;
var
  Node: PVirtualNode;
begin
  FMode := Value;
  FTree.BeginUpdateAuto;

  if Mode = pmNormal then
    FTree.TreeOptions.MiscOptions := FTree.TreeOptions.MiscOptions -
      [toCheckSupport]
  else
    FTree.TreeOptions.MiscOptions := FTree.TreeOptions.MiscOptions +
      [toCheckSupport];

  for Node in FTree.Nodes do
    FTree.InvalidateNode(Node);
end;

procedure TUiLibPrivilegeList.SetPopupMenu;
begin
  FTree.PopupMenu := Value;
end;

procedure TUiLibPrivilegeList.SetPrivileges;
var
  Providers: TArray<IPrivilege>;
  i: Integer;
begin
  Providers := TPrivilegeProvider.CreateMany(Self, Values);

  FTree.BeginUpdateAuto;
  FTree.BackupSelectionAuto;
  FTree.Clear;

  for i := 0 to High(Values) do
  begin
    FTree.AddChild(Providers[i]);
    FTree.CheckType[Providers[i].Node] := ctCheckBox;
  end;
end;

class procedure TUiLibPrivilegeList.Show;
begin
  UiLibShow(TUiLibPrivilegeList.Factory(Privileges));
end;

class procedure TUiLibPrivilegeList.ShowAll;
begin
  UiLibShow(TUiLibPrivilegeList.FactoryAll());
end;

initialization
  UiLibHostShowPrivilegeList := TUiLibPrivilegeList.Show;
  UiLibHostShowPrivilegeListAll := TUiLibPrivilegeList.ShowAll;
end.
