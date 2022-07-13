unit UI.Prototypes.BitMask;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  VclEx.ListView, DelphiApi.Reflection;

type
  TBitMaskFrame = class(TFrame)
    ListViewEx: TListViewEx;
    procedure ListViewExItemChecked(Sender: TObject; Item: TListItem);
  private
    FFlags, FGroups: TArray<TFlagName>;
    FValue, FShadowValue: Cardinal;
    FOnValueChange: TNotifyEvent;
    FReadOnly: Boolean;
    procedure SetValue(const NewValue: Cardinal);
    procedure UpdateHighlighting;
  public
    procedure Initialize(const Flags: TArray<TFlagName>; const Groups: TArray<TFlagName> = nil);
    property Value: Cardinal read FValue write SetValue;
    property OnValueChange: TNotifyEvent read FOnValueChange write FOnValueChange;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
  end;

implementation

uses
  DelphiUiLib.Reflection.Strings, DelphiUiLib.Strings, UI.Colors;

{$R *.dfm}

{ TFlagsFrame }

procedure TBitMaskFrame.Initialize;
var
  i, j: Integer;
begin
  // Disable event triggering
  ListViewEx.OnItemChecked := nil;

  // Reset the value
  FValue := 0;
  FShadowValue := 0;

  // Reload the groups
  FGroups := Groups;
  ListViewEx.Groups.BeginUpdate;
  ListViewEx.Groups.Clear;
  ListViewEx.GroupView := Length(Groups) > 0;

  for i := 0 to High(Groups) do
    with ListViewEx.Groups.Add do
    begin
      Header := Groups[i].Name;
      State := [lgsNormal, lgsCollapsible];
    end;

  ListViewEx.Groups.EndUpdate;

  // Reload the items
  FFlags := Flags;
  ListViewEx.Items.BeginUpdate;
  ListViewEx.Items.Clear;

  for i := 0 to High(Flags) do
    with ListViewEx.Items.Add do
    begin
      Caption := Flags[i].Name;
      Hint := BuildHint('Value', IntToHexEx(Flags[i].Value));
      Color := ColorSettings.clStale;
      ColorEnabled := False;

      // Find the suitable group
      for j := 0 to High(Groups) do
        if LongBool(Flags[i].Value and Groups[j].Value) then
        begin
          GroupID := j;
          Break;
        end;
    end;

  ListViewEx.Items.EndUpdate;

  // Enable checking events
  ListViewEx.OnItemChecked := ListViewExItemChecked;
end;

procedure TBitMaskFrame.ListViewExItemChecked;
begin
  // Prevent checking items in a read-only mode
  if FReadOnly then
  begin
    ListViewEx.OnItemChecked := nil;
    Item.Checked := not Item.Checked;
    ListViewEx.OnItemChecked := ListViewExItemChecked;
    Exit;
  end;

  if Item.Checked then
    FValue := FValue or FFlags[Item.Index].Value
  else
    FValue := FValue and not FFlags[Item.Index].Value;

  UpdateHighlighting;

  if Assigned(OnValueChange) then
    OnValueChange(Self);
end;

procedure TBitMaskFrame.SetValue;
var
  i: Integer;
begin
  // Disable event triggering
  ListViewEx.OnItemChecked := nil;

  // Check the corresponding items
  for i := 0 to High(FFlags) do
    ListViewEx.Items[i].Checked := LongBool(FFlags[i].Value and NewValue);

  FValue := NewValue;
  FShadowValue := NewValue;
  UpdateHighlighting;
  ListViewEx.OnItemChecked := ListViewExItemChecked;
end;

procedure TBitMaskFrame.UpdateHighlighting;
var
  i: Integer;
begin
  ListViewEx.Items.BeginUpdate;

  // Highlight modified items
  for i := 0 to High(FFlags) do
    ListViewEx.Items[i].ColorEnabled :=
      LongBool((FShadowValue xor FValue) and FFlags[i].Value);

  ListViewEx.Items.EndUpdate;
end;

end.
