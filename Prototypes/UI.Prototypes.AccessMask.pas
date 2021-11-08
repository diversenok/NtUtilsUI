unit UI.Prototypes.AccessMask;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  VclEx.ListView, DelphiApi.Reflection, Ntapi.WinNt, Vcl.ExtCtrls;

type
  TAccessMaskFrame = class(TFrame)
    ListViewEx: TListViewEx;
    EditMask: TEdit;
    ButtonClear: TButton;
    ButtonFull: TButton;
    Panel: TPanel;
    procedure ListViewExItemChecked(Sender: TObject; Item: TListItem);
    procedure ButtonClearClick(Sender: TObject);
    procedure EditMaskChange(Sender: TObject);
    procedure ButtonFullClick(Sender: TObject);
  private
    FAccessMask, FFullAccess: TAccessMask;
    GenericMapping: TGenericMapping;
    FReadOnly: Boolean;
    procedure AddItem(const Flag: TFlagName; Group: Integer;
      ItemData: IInterface);
    procedure PopulateItems(Attributes: TArray<TCustomAttribute>);
    procedure UpdateEdit;
    procedure UpdateCheckboxes;
    procedure SetAccessMask(const Value: TAccessMask);
    procedure SetReadOnly(const Value: Boolean);
  public
    property AccessMask: TAccessMask read FAccessMask write SetAccessMask;
    property IsReadOnly: Boolean read FReadOnly write SetReadOnly;
    procedure LoadType(AType: Pointer; const Mapping: TGenericMapping);
  end;

implementation

uses
  System.Rtti, DelphiUtils.Arrays, DelphiUiLib.Strings,
  DelphiUiLib.Reflection.Strings;

{$R *.dfm}

const
  // Be consistent with the listview
  GROUP_READ = 0;
  GROUP_WRITE = 1;
  GROUP_EXECUTE = 2;
  GROUP_SPECIFIC = 3;
  GROUP_STANDARD = 4;
  GROUP_GENERIC = 5;
  GROUP_MISC = 6;

type
  IAccessBit = interface
    function Value: TAccessMask;
  end;

  TAccessBit = class(TInterfacedObject, IAccessBit)
  private
    FValue: TAccessMask;
  public
    constructor Create(Value: TAccessMask);
    function Value: TAccessMask;
  end;

{ TAccessBit }

constructor TAccessBit.Create(Value: TAccessMask);
begin
  FValue := Value;
end;

function TAccessBit.Value: TAccessMask;
begin
  Result := FValue;
end;

{ Custom attribute filters }

function FilterFlags(const Attribute: TCustomAttribute; out FlagName: TFlagName)
  : Boolean;
begin
  Result := Attribute is FlagNameAttribute;

  if Result then
    FlagName := FlagNameAttribute(Attribute).Flag;
end;

function FilterFullAccess(const Attribute: TCustomAttribute; out Mask:
  TAccessMask): Boolean;
begin
  Result := Attribute is ValidMaskAttribute;

  if Result then
    Mask := TAccessMask(ValidMaskAttribute(Attribute).ValidMask);
end;

{ TAccessMaskFrame }

procedure TAccessMaskFrame.AddItem(const Flag: TFlagName; Group: Integer;
  ItemData: IInterface);
begin
  with ListViewEx.Items.Add do
  begin
    Caption := Flag.Name;
    OwnedIData := ItemData;
    GroupID := Group;
    Hint := BuildHint('Value', IntToHexEx(Flag.Value, 8));
  end;
end;

procedure TAccessMaskFrame.LoadType(AType: Pointer;
  const Mapping: TGenericMapping);
var
  RttiContext: TRttiContext;
  CheckedEvent: TLVCheckedItemEvent;
  Attributes: TArray<TCustomAttribute>;
begin
  RttiContext := TRttiContext.Create;

  GenericMapping := Mapping;

  with ListViewEx.Items do
  begin
    // Disable event and redraw
    CheckedEvent := ListViewEx.OnItemChecked;
    ListViewEx.OnItemChecked := nil;
    BeginUpdate;
    Clear;

    // Add type-specific access rights
    if Assigned(AType) and (AType <> TypeInfo(TAccessMask)) then
    begin
      Attributes := RttiContext.GetType(AType).GetAttributes;
      PopulateItems(Attributes);
    end
    else
      Attributes := nil;

    // Save full access mask
    FFullAccess := TArray.ConvertFirstOrDefault<TCustomAttribute, TAccessMask>(
      Attributes, FilterFullAccess, GENERIC_RIGHTS_ALL);

    // Add standard, generic, and other access rights
    PopulateItems(RttiContext.GetType(TypeInfo(TAccessMask)).GetAttributes);

    // Enable event and redraw back
    EndUpdate;
    ListViewEx.OnItemChecked := CheckedEvent;
  end;
end;

procedure TAccessMaskFrame.ButtonClearClick(Sender: TObject);
begin
  AccessMask := 0;
end;

procedure TAccessMaskFrame.ButtonFullClick(Sender: TObject);
begin
  AccessMask := FFullAccess;
end;

procedure TAccessMaskFrame.EditMaskChange(Sender: TObject);
begin
  if TryStrToUIntEx(EditMask.Text, Cardinal(FAccessMask)) then
    UpdateCheckboxes;
end;

procedure TAccessMaskFrame.ListViewExItemChecked(Sender: TObject;
  Item: TListItem);
var
  ItemEx: TListItemEx absolute Item;
  CheckEvent: TLVCheckedItemEvent;
  i: Integer;
begin
  // Prevent checking items in a read-only mode
  if FReadOnly then
  begin
    CheckEvent := ListViewEx.OnItemChecked;
    ListViewEx.OnItemChecked := nil;
    Item.Checked := not Item.Checked;
    ListViewEx.OnItemChecked := CheckEvent;
  end;

  // Collect the access mask based on checked items
  FAccessMask := 0;

  with ListViewEx do
    for i := 0 to Pred(Items.Count) do
    begin
      // Always keep duplicated items (the once with the same value) in sync
      if (ItemEx.Index <> i) and (ItemEx.OwnedIData = Items[i].OwnedIData) then
        Items[i].Checked := Item.Checked;

      // Compute the access mask
      if Items[i].Checked then
        FAccessMask := FAccessMask or IAccessBit(Items[i].OwnedIData).Value;
    end;

  UpdateEdit;
end;

procedure TAccessMaskFrame.PopulateItems(Attributes: TArray<TCustomAttribute>);
var
  Flag: TFlagName;
  ItemData: IAccessBit;
  UnknownSpecific: Boolean;
begin
  for Flag in TArray.Convert<TCustomAttribute, TFlagName>(
    Attributes, FilterFlags) do
  begin
    ItemData := TAccessBit.Create(Flag.Value);

    // Standard rights go into their category regardless of generic mapping
    if Flag.Value and STANDARD_RIGHTS_ALL <> 0 then
      AddItem(Flag, GROUP_STANDARD, ItemData)

    // Generic bits do that as well
    else if Flag.Value and GENERIC_RIGHTS_ALL <> 0 then
      AddItem(Flag, GROUP_GENERIC, ItemData)

    // Specific rights have more options
    else if Flag.Value and SPECIFIC_RIGHTS_ALL <> 0 then
    begin
      UnknownSpecific := True;

      // They can appear in multiple RWX categories at once
      if Flag.Value and GenericMapping.GenericRead <> 0 then
      begin
        AddItem(Flag, GROUP_READ, ItemData);
        UnknownSpecific := False;
      end;

      if Flag.Value and GenericMapping.GenericWrite <> 0 then
      begin
        AddItem(Flag, GROUP_WRITE, ItemData);
        UnknownSpecific := False;
      end;

      if Flag.Value and GenericMapping.GenericExecute <> 0 then
      begin
        AddItem(Flag, GROUP_EXECUTE, ItemData);
        UnknownSpecific := False;
      end;

      // As a fallback, they go into specific
      if UnknownSpecific then
        AddItem(Flag, GROUP_SPECIFIC, ItemData)
    end

    // The rets goes to misc.
    else
      AddItem(Flag, GROUP_MISC, ItemData);
  end;
end;

procedure TAccessMaskFrame.SetAccessMask(const Value: TAccessMask);
begin
  FAccessMask := Value;
  UpdateEdit;
  UpdateCheckboxes;
end;

procedure TAccessMaskFrame.SetReadOnly(const Value: Boolean);
begin
  FReadOnly := Value;
  ButtonClear.Visible := not FReadOnly;
  ButtonFull.Visible := not FReadOnly;
  EditMask.ReadOnly := FReadOnly;
end;

procedure TAccessMaskFrame.UpdateCheckboxes;
var
  i: Integer;
  CheckedEvent: TLVCheckedItemEvent;
begin
  with ListViewEx do
  begin
    Items.BeginUpdate;
    CheckedEvent := OnItemChecked;
    OnItemChecked := nil;

    // Check items with enabled bits
    for i := 0 to Pred(Items.Count) do
      Items[i].Checked := FAccessMask and
        IAccessBit(Items[i].OwnedIData).Value <> 0;

    OnItemChecked := CheckedEvent;
    Items.EndUpdate;
  end;
end;

procedure TAccessMaskFrame.UpdateEdit;
begin
  EditMask.Text := IntToHexEx(FAccessMask, 8);
  EditMask.TextHint := EditMask.Text;
end;

end.
