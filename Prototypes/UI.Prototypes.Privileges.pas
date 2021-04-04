unit UI.Prototypes.Privileges;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ComCtrls, VclEx.ListView, Vcl.Menus, Ntapi.ntseapi, NtUtils;

type
  TPrivilegeRecord = record
    Data: TPrivilege;
    Name, Description: String;
    procedure Load(Privilege: TPrivilege; hxPolicy: IHandle);
  end;

  TPrivilegeColoring = (pcStateBased, pcRemoved, pcNone);

  TPrivilegesFrame = class(TFrame)
    ListViewEx: TListViewEx;
    procedure ListViewExItemChecked(Sender: TObject; Item: TListItem);
  private
    Privileges: TArray<TPrivilegeRecord>;
    FColoringUnChecked, FCheckedColoring: TPrivilegeColoring;
    procedure ReloadState(Item: TListItemEx; Attributes: TPrivilegeAttributes);
    procedure RecolorItem(Item: TListItemEx; Attributes: TPrivilegeAttributes);
    procedure LoadChecked(Check: TArray<TPrivilege>);
    function ListChecked: TArray<TPrivilege>;
    function ListSelected: TArray<TPrivilege>;
    function GetPrivilege(Index: Integer): TPrivilege;
  public
    procedure Load(const New: TArray<TPrivilege>);
    procedure LoadEvery;
    function Find(Luid: TPrivilegeId): Integer;
    property Checked: TArray<TPrivilege> read ListChecked write LoadChecked;
    property Selected: TArray<TPrivilege> read ListSelected;
    property Privilege[Index: Integer]: TPrivilege read GetPrivilege;
    procedure UpdateState(Index: Integer; Attributes: TPrivilegeAttributes);
  published
    property ColoringUnChecked: TPrivilegeColoring read FColoringUnChecked write FColoringUnChecked default pcStateBased;
    property ColoringChecked: TPrivilegeColoring read FCheckedColoring write FCheckedColoring default pcStateBased;
  end;

implementation

uses
  Winapi.WinNt, Winapi.ntlsa, NtUtils.Lsa, DelphiUtils.Arrays,
  DelphiUiLib.Strings, DelphiUiLib.Reflection.Strings,
  DelphiUiLib.Reflection.Numeric, UI.Colors;

{$R *.dfm}

{ TPrivilegeRecord }

procedure TPrivilegeRecord.Load(Privilege: TPrivilege; hxPolicy: IHandle);
var
  RawName: String;
begin
  Data := Privilege;

  // Try to query the name and the description from the system
  if Assigned(hxPolicy) and LsaxQueryPrivilege(Privilege.Luid, RawName,
    Description, hxPolicy).IsSuccess then
    Name := PrettifyCamelCase(RawName, 'Se')
  else
  begin
    // Otherwise, prepare names based on well-known privileges
    Name := TNumeric.Represent(TSeWellKnownPrivilege(Privilege.Luid)).Text;
    Description := '';
  end;
end;

{ Functions }

function GetPrivilegeGroupId(Value: TLuid): Integer;
const
  // Be consistent with ListView's groups
  GROUP_ID_HIGH = 0;
  GROUP_ID_MEDIUM = 1;
  GROUP_ID_LOW = 2;
var
  Integrity: Cardinal;
begin
  Integrity := LsaxQueryIntegrityPrivilege(Value);

  if Integrity > SECURITY_MANDATORY_MEDIUM_RID then
    Result := GROUP_ID_HIGH
  else if Integrity < SECURITY_MANDATORY_MEDIUM_RID then
    Result := GROUP_ID_LOW
  else
    Result := GROUP_ID_MEDIUM;
end;

function GetAllPrivileges: TArray<TPrivilege>;
var
  New: TArray<TPrivilegeDefinition>;
  i: Integer;
begin
  if LsaxEnumeratePrivileges(New).IsSuccess then
  begin
    SetLength(Result, Length(New));

    // Copy LUIDs
    for i := 0 to High(New) do
      Result[i].Luid := New[i].LocalValue;
  end
  else
  begin
    // If privilege enumeration does not work, use the whole well-known range
    SetLength(Result, SE_MAX_WELL_KNOWN_PRIVILEGE -
      SE_MIN_WELL_KNOWN_PRIVILEGE + 1);

    for i := 0 to High(Result) do
      Result[i].Luid := SE_MIN_WELL_KNOWN_PRIVILEGE + i;
  end;

  // Only enable SeChangeNotifyPrivilege by default
  for i := 0 to High(Result) do
    with Result[i] do
      if Luid = TPrivilegeId(SE_CHANGE_NOTIFY_PRIVILEGE) then
        Attributes := SE_PRIVILEGE_ENABLED_BY_DEFAULT or SE_PRIVILEGE_ENABLED;
end;

{ TPrivilegesFrame }

function TPrivilegesFrame.Find(Luid: TPrivilegeId): Integer;
var
  i: Integer;
begin
  for i := 0 to High(Privileges) do
    if Privileges[i].Data.Luid = Luid then
      Exit(i);

  Result := -1;
end;

function TPrivilegesFrame.GetPrivilege(Index: Integer): TPrivilege;
begin
  Result := Privileges[Index].Data;
end;

function TPrivilegesFrame.ListChecked: TArray<TPrivilege>;
begin
  // Get all checked privileges

  Result := TArray.ConvertEx<TPrivilegeRecord, TPrivilege>(Privileges,
    function (const Index: Integer; const Entry: TPrivilegeRecord;
      out ConvertedEntry: TPrivilege): Boolean
    begin
      Result := ListViewEx.Items[Index].Checked;

      if Result then
        ConvertedEntry := Entry.Data;
    end
  );
end;

function TPrivilegesFrame.ListSelected: TArray<TPrivilege>;
begin
  // Get all checked privileges

  Result := TArray.ConvertEx<TPrivilegeRecord, TPrivilege>(Privileges,
    function (const Index: Integer; const Entry: TPrivilegeRecord;
      out ConvertedEntry: TPrivilege): Boolean
    begin
      Result := ListViewEx.Items[Index].Selected;

      if Result then
        ConvertedEntry := Entry.Data;
    end
  );
end;

procedure TPrivilegesFrame.ListViewExItemChecked(Sender: TObject;
  Item: TListItem);
begin
  if FColoringUnChecked <> FCheckedColoring then
    RecolorItem(Item as TListItemEx, Privileges[Item.Index].Data.Attributes);
end;

procedure TPrivilegesFrame.Load(const New: TArray<TPrivilege>);
var
  hxPolicy: IHandle;
  i: Integer;
  NewItem: TListItemEx;
  HintSections: TArray<THintSection>;
begin
  with ListViewEx.Items do
  begin
    BeginUpdate(True);
    Clear;

    // Prepare LSA policy handle for querying
    if not LsaxOpenPolicy(hxPolicy, POLICY_LOOKUP_NAMES).IsSuccess then
      hxPolicy := nil;

    SetLength(Privileges, Length(New));

    for i := 0 to High(Privileges) do
    begin
      // Copy the privilege and resolve its name
      Privileges[i].Load(New[i], hxPolicy);

      // Add an item and fill static columns
      NewItem := Add;
      NewItem.Cell[0] := Privileges[i].Name;
      NewItem.Cell[2] := Privileges[i].Description;
      NewItem.GroupID := GetPrivilegeGroupId(Privileges[i].Data.Luid);

      // Make a hint
      SetLength(HintSections, 3);
      HintSections[0].Title := 'Name';
      HintSections[0].Content := Privileges[i].Name;
      HintSections[1].Title := 'Description';
      HintSections[1].Content := Privileges[i].Description;
      HintSections[2].Title := 'Value';
      HintSections[2].Content := IntToStr(Privileges[i].Data.Luid);
      NewItem.Hint := BuildHint(HintSections);

      // Update the attributes column and color
      ReloadState(NewItem, Privileges[i].Data.Attributes);
    end;

    EndUpdate(True);
  end;
end;

procedure TPrivilegesFrame.LoadEvery;
begin
  Load(GetAllPrivileges);
end;

procedure TPrivilegesFrame.LoadChecked(Check: TArray<TPrivilege>);
var
  i, Index: Integer;
begin
  ListViewEx.Items.BeginUpdate;

  // Uncheck existing privileges
  for i := 0 to Pred(ListViewEx.Items.Count) do
    ListViewEx.Items[i].Checked := False;

  // Try to locate overlay privileges
  for i := 0 to High(Check) do
  begin
    Index := Find(Check[i].Luid);

    // Check and update corresponding items
    if Index >= 0 then
    begin
      ListViewEx.Items[Index].Checked := True;
      UpdateState(Index, Check[i].Attributes);
    end;
  end;

  ListViewEx.Items.EndUpdate;
end;

procedure TPrivilegesFrame.RecolorItem(Item: TListItemEx; Attributes:
  TPrivilegeAttributes);
var
  Mode: TPrivilegeColoring;
begin
  // Determine coloring mode
  if ListViewEx.Checkboxes and Item.Checked then
    Mode := FCheckedColoring
  else
    Mode := FColoringUnChecked;

  // Apply it
  case Mode of
    pcNone:    Item.ColorEnabled := False;
    pcRemoved: Item.Color := ColorSettings.clRemoved;
    pcStateBased:
      if Attributes and SE_PRIVILEGE_ENABLED <> 0 then
        if Attributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT <> 0 then
          Item.Color := ColorSettings.clEnabled
        else
          Item.Color := ColorSettings.clEnabledModified
      else
        if Attributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT <> 0 then
          Item.Color := ColorSettings.clDisabledModified
        else
          Item.Color := ColorSettings.clDisabled;
  end;
end;

procedure TPrivilegesFrame.ReloadState(Item: TListItemEx; Attributes:
  TPrivilegeAttributes);
begin
  ListViewEx.Items.BeginUpdate;

  // Fill-in the attributes
  Item.Cell[1] := TNumeric.Represent(Attributes).Text;

  // Update the color
  RecolorItem(Item, Attributes);

  ListViewEx.Items.EndUpdate;
end;

procedure TPrivilegesFrame.UpdateState(Index: Integer;
  Attributes: TPrivilegeAttributes);
begin
  if Privileges[Index].Data.Attributes <> Attributes then
  begin
    ListViewEx.Items.BeginUpdate;

    Privileges[Index].Data.Attributes := Attributes;
    ReloadState(ListViewEx.Items[Index], Attributes);

    ListViewEx.Items.EndUpdate;
  end;
end;

end.
