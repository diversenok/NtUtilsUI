unit UI.Prototypes.Groups;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ComCtrls, VclEx.ListView, Ntapi.ntseapi, NtUtils;

type
  TGroupsFrame = class(TFrame)
    ListViewEx: TListViewEx;
  private
    Groups: TArray<TGroup>;
    procedure Reload(Item: TListItemEx; const Group: TGroup;
      hxPolicy: IHandle);
    function ListAll: TArray<TGroup>;
    function ListChecked: TArray<TGroup>;
    function ListSelected: TArray<TGroup>;
    function GetGroup(Index: Integer): TGroup;
    procedure SetGroup(Index: Integer; const New: TGroup);
  public
    procedure Load(const New: TArray<TGroup>);
    procedure Add(const New: TArray<TGroup>);
    procedure UpdateSelected(AddAttributes, RemoveAttributes: TGroupAttributes);
    procedure RemoveSelected;
    function Find(const Sid: ISid): Integer;
    property Group[Index: Integer]: TGroup read GetGroup write SetGroup; default;
    property All: TArray<TGroup> read ListAll;
    property Checked: TArray<TGroup> read ListChecked;
    property Selected: TArray<TGroup> read ListSelected;
  end;

implementation

uses
  Winapi.WinNt, Ntapi.ntrtl, Winapi.ntlsa, NtUtils.Lsa, DelphiUtils.AutoObject,
  DelphiUtils.Arrays, UI.Colors, DelphiApi.Reflection,
  DelphiUiLib.Reflection.Numeric, NtUiLib.Reflection.Types;

{$R *.dfm}

{ TGroupsFrame }

procedure TGroupsFrame.Add(const New: TArray<TGroup>);
var
  hxPolicy: IHandle;
  i: Integer;
begin
  ListViewEx.Items.BeginUpdate;

  // Connect to LSA once, so we don't need to reconnect on every iteration
  if not LsaxOpenPolicy(hxPolicy, POLICY_LOOKUP_NAMES).IsSuccess then
    hxPolicy := nil;

  Groups := Concat(Groups, New);

  for i := 0 to High(New) do
    Reload(ListViewEx.Items.Add, New[i], hxPolicy);

  ListViewEx.Items.EndUpdate;
end;

function TGroupsFrame.Find(const Sid: ISid): Integer;
var
  i: Integer;
begin
  for i := 0 to High(Groups) do
    if RtlEqualSid(Groups[i].Sid.Data, Sid.Data) then
      Exit(i);

  Result := -1;
end;

function TGroupsFrame.GetGroup(Index: Integer): TGroup;
begin
  Result := Groups[Index];
end;

function TGroupsFrame.ListAll: TArray<TGroup>;
begin
  Result := Copy(Groups, 0, Length(Groups));
end;

function TGroupsFrame.ListChecked: TArray<TGroup>;
begin
  Result := TArray.FilterEx<TGroup>(Groups,
    function (const Index: Integer; const Entry: TGroup): Boolean
    begin
      Result := ListViewEx.Items[Index].Checked;
    end
  );
end;

function TGroupsFrame.ListSelected: TArray<TGroup>;
begin
  Result := TArray.FilterEx<TGroup>(Groups,
    function (const Index: Integer; const Entry: TGroup): Boolean
    begin
      Result := ListViewEx.Items[Index].Selected;
    end
  );
end;

procedure TGroupsFrame.Load(const New: TArray<TGroup>);
begin
  ListViewEx.Items.BeginUpdate(True);

  ListViewEx.Items.Clear;
  SetLength(Groups, 0);

  Add(New);

  ListViewEx.Items.EndUpdate(True);
end;

procedure TGroupsFrame.Reload(Item: TListItemEx; const Group: TGroup;
  hxPolicy: IHandle);
var
  NoState: IgnoreSubEnumsAttribute;
begin
  ListViewEx.Items.BeginUpdate;

  // SID + hint
  with RepresentSidWorker(IMem.RefOrNil<PSid>(Group.Sid), Group.Attributes,
    True, hxPolicy) do
  begin
    Item.Cell[0] := Text;
    Item.Hint := Hint;
  end;

  // Represent state only
  Item.Cell[1] := TNumeric.Represent<TGroupAttributes>(Group.Attributes and
    SE_GROUP_STATE_MASK).Text;

  // Represent flags only
  NoState := IgnoreSubEnumsAttribute.Create;
  Item.Cell[2] := TNumeric.Represent<TGroupAttributes>(Group.Attributes and
    not SE_GROUP_STATE_MASK, [NoState]).Text;

  // Update the color
  if Group.Attributes and SE_GROUP_INTEGRITY_ENABLED <> 0 then
    Item.Color := ColorSettings.clIntegrity
  else
    if Group.Attributes and SE_GROUP_ENABLED <> 0 then
      if Group.Attributes and SE_GROUP_ENABLED_BY_DEFAULT <> 0 then
        Item.Color := ColorSettings.clEnabled
      else
        Item.Color := ColorSettings.clEnabledModified
    else
      if Group.Attributes and SE_GROUP_ENABLED_BY_DEFAULT <> 0 then
        Item.Color := ColorSettings.clDisabledModified
      else
        Item.Color := ColorSettings.clDisabled;

  ListViewEx.Items.EndUpdate;
  NoState.Free;
end;

procedure TGroupsFrame.RemoveSelected;
var
  i: Integer;
begin
  if ListViewEx.SelCount = 0 then
    Exit;

  ListViewEx.Items.BeginUpdate;

  // Remove from storage
  TArray.FilterInlineEx<TGroup>(Groups,
    function (const Index: Integer; const Entry: TGroup): Boolean
    begin
      Result := not ListViewEx.Items[Index].Selected;
    end
  );

  // Remove from UI
  for i := Pred(ListViewEx.Items.Count) downto 0 do
    if ListViewEx.Items[i].Selected then
      ListViewEx.Items.Delete(i);

  ListViewEx.Items.EndUpdate;
end;

procedure TGroupsFrame.SetGroup(Index: Integer; const New: TGroup);
begin
  Groups[Index] := New;
  Reload(ListViewEx.Items[Index], New, nil);
end;

procedure TGroupsFrame.UpdateSelected(AddAttributes, RemoveAttributes:
  TGroupAttributes);
var
  NewGroups: TArray<TGroup>;
  i: Integer;
begin
  NewGroups := Copy(Groups, 0, Length(Groups));

  for i := 0 to High(NewGroups) do
    if ListViewEx.Items[i].Selected then
      NewGroups[i].Attributes := (NewGroups[i].Attributes or AddAttributes) and
        not RemoveAttributes;

  Load(NewGroups);
end;

end.
