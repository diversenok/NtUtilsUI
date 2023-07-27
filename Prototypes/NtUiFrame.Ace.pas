unit NtUiFrame.Ace;

{
  This unit provides a frame for detailed editing of Access Control Entries.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Ntapi.WinNt, NtUtils.Security.Acl,
  NtUiFrame.Bits, UI.Prototypes.Sid.Edit, Vcl.ExtCtrls, NtUiFrame.Ace.Condition,
  NtUiFrame, NtUiFrame.Hex.Edit, NtUiFrame.Guid, NtUiCommon.Interfaces;

type
  TAceFrame = class(TFrame, ICanConsumeEscape, IHasDefaultCaption,
    IHasModalCaptions, IHasModalResult)
    cbxType: TComboBox;
    lblType: TLabel;
    lblFlags: TLabel;
    lblAccessMask: TLabel;
    lblSid: TLabel;
    fmxSid: TSidEditor;
    lblServerSid: TLabel;
    fmxServerSid: TSidEditor;
    cbxObjectType: TCheckBox;
    fmxFlags: TBitsFrame;
    fmxAccessMask: TBitsFrame;
    cbxInheritedObjectType: TCheckBox;
    BitsPanel: TPanel;
    Splitter: TSplitter;
    lblCondition: TLabel;
    fmxCondition: TAceConditionFrame;
    fmxExtraData: THexEditFrame;
    lblExtraData: TLabel;
    fmxObjectType: TGuidFrame;
    fmxInheritedObjectType: TGuidFrame;
    procedure cbxObjectTypeClick(Sender: TObject);
    procedure cbxInheritedObjectTypeClick(Sender: TObject);
    procedure cbxTypeChange(Sender: TObject);
    procedure SplitterMoved(Sender: TObject);
  private
    FObjectFlags: TObjectAceFlags;
    FMaskType: Pointer;
    FGenericMapping: TGenericMapping;
    FPreviousAceType: TAceType;
    procedure SetAce(const Value: TAceData);
    function GetAce: TAceData;
    function GetAceType: TAceType;
    procedure UpdateMaskType;
  protected
    procedure Loaded; override;
    function ConsumesEscape: Boolean;
    function DefaultCaption: String;
    function GetConfirmationCaption: String;
    function GetCancellationCaption: String;
    function GetModalResult: IInterface;
  public
    procedure LoadType(
      AccessMaskType: Pointer;
      const GenericMapping: TGenericMapping
    );
    property Ace: TAceData read GetAce write SetAce;
  end;

implementation

uses
  NtUtils, NtUtils.Security, UI.Colors, NtUiLib.TaskDialog,
  NtUiCommon.Prototypes;

{$R *.dfm}

{ TAceFrame }

procedure TAceFrame.cbxInheritedObjectTypeClick;
begin
  fmxInheritedObjectType.Enabled := cbxInheritedObjectType.Checked;
end;

procedure TAceFrame.cbxObjectTypeClick;
begin
  fmxObjectType.Enabled := cbxObjectType.Checked;
end;

procedure TAceFrame.cbxTypeChange;
var
  AceType: TAceType;
begin
  AceType := GetAceType;
  lblServerSid.Enabled := AceType = ACCESS_ALLOWED_COMPOUND_ACE_TYPE;
  fmxServerSid.Enabled := AceType = ACCESS_ALLOWED_COMPOUND_ACE_TYPE;
  lblCondition.Enabled := AceType in CallbackAces;
  fmxCondition.Enabled := AceType in CallbackAces;
  cbxObjectType.Enabled := AceType in ObjectAces;
  fmxObjectType.Enabled := (AceType in ObjectAces) and cbxObjectType.Checked;
  cbxInheritedObjectType.Enabled := AceType in ObjectAces;
  fmxInheritedObjectType.Enabled := (AceType in ObjectAces) and
    cbxInheritedObjectType.Checked;
  lblExtraData.Enabled := not (AceType in CallbackAces);
  fmxExtraData.Enabled := not (AceType in CallbackAces);

  if (AceType = SYSTEM_MANDATORY_LABEL_ACE_TYPE) xor
    (FPreviousAceType = SYSTEM_MANDATORY_LABEL_ACE_TYPE) then
    UpdateMaskType;

  FPreviousAceType := AceType;
end;

function TAceFrame.ConsumesEscape;
begin
  Result := cbxType.DroppedDown;
end;

function TAceFrame.DefaultCaption;
begin
  Result := 'ACE Editor';
end;

function TAceFrame.GetAce;
begin
  Result := Default(TAceData);
  Result.AceType := GetAceType;
  Result.AceFlags := TAceFlags(fmxFlags.Value);
  Result.Mask := TAccessMask(fmxAccessMask.Value);
  Result.SID := fmxSid.Sid;

  // Server SID
  if Result.AceType = ACCESS_ALLOWED_COMPOUND_ACE_TYPE then
  begin
    Result.CompoundAceType := COMPOUND_ACE_IMPERSONATION;
    Result.ServerSID := fmxServerSid.Sid;
  end;

  // Extra & callback data
  if Result.AceType in CallbackAces then
    Result.ExtraData := fmxCondition.Condition
  else
    Result.ExtraData := fmxExtraData.Data;

  // Object & inherited object types
  if Result.AceType in ObjectAces then
  begin
    Result.ObjectFlags := FObjectFlags and not
      (ACE_OBJECT_TYPE_PRESENT or ACE_INHERITED_OBJECT_TYPE_PRESENT);

    if cbxObjectType.Checked then
    begin
      Result.ObjectFlags := Result.ObjectFlags or ACE_OBJECT_TYPE_PRESENT;
      Result.ObjectType := fmxObjectType.Guid;
    end;

    if cbxInheritedObjectType.Checked then
    begin
      Result.ObjectFlags := Result.ObjectFlags or
        ACE_INHERITED_OBJECT_TYPE_PRESENT;
      Result.InheritedObjectType := fmxInheritedObjectType.Guid;
    end;
  end;
end;

function TAceFrame.GetAceType;
begin
  if (cbxType.ItemIndex < 0) or (cbxType.ItemIndex > Integer(High(TAceType))) then
    raise Exception.Create('Invalid ACE type.');

  Result := TAceType(cbxType.ItemIndex);
end;

function TAceFrame.GetCancellationCaption;
begin
  Result := 'Cancel';
end;

function TAceFrame.GetConfirmationCaption;
begin
  Result := 'OK';
end;

function TAceFrame.GetModalResult;
begin
  Result := Auto.Copy(Ace);
end;

procedure TAceFrame.Loaded;
begin
  inherited;
  fmxFlags.LoadType(TypeInfo(TAceFlags));
  FMaskType := TypeInfo(TAccessMask);
  UpdateMaskType;
end;

procedure TAceFrame.LoadType;
begin
  if Assigned(AccessMaskType) then
    FMaskType := AccessMaskType
  else
    FMaskType := TypeInfo(TAccessMask);

  FGenericMapping := GenericMapping;
  UpdateMaskType;
end;

procedure TAceFrame.SetAce;
const
  UNRECOGNIZED_FLAGS_CAPTION = 'ACE Editor';
  UNRECOGNIZED_FLAGS_INSTRUCTION = 'Unrecognized Object Flags';
  UNRECOGNIZED_FLAGS_PROMPT = 'The ACE contains unrecognized object flags. ' +
    'Do you want to preserve them during editing?';
begin
  // Validate the ACE type
  if Value.AceType > High(TAceType) then
    raise Exception.Create('Unknown ACE type.');

  if (Value.AceType = ACCESS_ALLOWED_COMPOUND_ACE_TYPE) and
    (Value.CompoundAceType <> COMPOUND_ACE_IMPERSONATION) then
    raise Exception.Create('Unknown compound ACE sub-type');

  // Save unrecognized flags
  FObjectFlags := 0;
  if (Value.AceType in ObjectAces) and HasAny(Value.ObjectFlags and not
    (ACE_OBJECT_TYPE_PRESENT or ACE_INHERITED_OBJECT_TYPE_PRESENT)) and
    (UsrxShowTaskDialog(Handle, UNRECOGNIZED_FLAGS_CAPTION,
    UNRECOGNIZED_FLAGS_INSTRUCTION, UNRECOGNIZED_FLAGS_PROMPT, diInfo, dbYesNo)
    = IDYES) then
    FObjectFlags := Value.ObjectFlags;

  // Update component state
  cbxType.ItemIndex := Integer(Value.AceType);
  fmxSid.Sid := Value.SID;
  fmxFlags.Value := Value.AceFlags;
  fmxAccessMask.Value := Value.Mask;

  if Value.AceType = ACCESS_ALLOWED_COMPOUND_ACE_TYPE then
    fmxServerSid.Sid := Value.ServerSID
  else
    fmxServerSid.Sid := nil;

  if Value.AceType in ObjectAces then
  begin
    cbxObjectType.Checked := BitTest(Value.ObjectFlags and
      ACE_OBJECT_TYPE_PRESENT);
    cbxInheritedObjectType.Checked := BitTest(Value.ObjectFlags and
      ACE_INHERITED_OBJECT_TYPE_PRESENT);
    fmxObjectType.Guid := Value.ObjectType;
    fmxInheritedObjectType.Guid := Value.InheritedObjectType;
  end
  else
  begin
    cbxObjectType.Checked := False;
    cbxInheritedObjectType.Checked := False;
    fmxObjectType.Guid := Default(TGuid);
    fmxInheritedObjectType.Guid := Default(TGuid);
  end;

  if Value.AceType in CallbackAces then
  begin
    fmxCondition.TrySetCondition(Value.ExtraData);
    fmxExtraData.Data := nil;
  end
  else
  begin
    fmxCondition.TrySetCondition(nil);
    fmxExtraData.Data := Value.ExtraData;
  end;

  // Update enabled state
  cbxTypeChange(Self);
end;

procedure TAceFrame.SplitterMoved;
begin
  lblFlags.Left := fmxFlags.Left;
end;

procedure TAceFrame.UpdateMaskType;
begin
  if GetAceType = SYSTEM_MANDATORY_LABEL_ACE_TYPE then
    fmxAccessMask.LoadType(TypeInfo(TMandatoryLabelMask))
  else
    fmxAccessMask.LoadAccessMaskType(FMaskType, FGenericMapping, True, False);
end;

{ Integration }

function Initializer(
  AccessMaskType: Pointer;
  const GenericMapping: TGenericMapping
): TFrameInitializer;
begin
  Result := function (AOwner: TForm): TFrame
    var
      Frame: TAceFrame absolute Result;
    begin
      Frame := TAceFrame.Create(AOwner);
      try
        Frame.LoadType(AccessMaskType, GenericMapping);
      except
        Frame.Free;
        raise;
      end;
    end;
end;

function InitializerEx(
  AccessMaskType: Pointer;
  const GenericMapping: TGenericMapping;
  const Ace: TAceData
): TFrameInitializer;
begin
  Result := function (AOwner: TForm): TFrame
    var
      Frame: TAceFrame absolute Result;
    begin
      Frame := TAceFrame.Create(AOwner);
      try
        Frame.LoadType(AccessMaskType, GenericMapping);
        Frame.Ace := Ace;
      except
        Frame.Free;
        raise;
      end;
    end;
end;

function NtUiLibCreateAce(
  Owner: TComponent;
  AccessMaskType: Pointer;
  const GenericMapping: TGenericMapping
): TAceData;
var
  ModalResult: IInterface;
begin
  if not Assigned(NtUiLibHostFramePick) then
    raise ENotSupportedException.Create('Frame host not available');

  ModalResult := NtUiLibHostFramePick(Owner, Initializer(AccessMaskType,
    GenericMapping));

  Result := TAceData((ModalResult as IMemory).Data^);
end;

function NtUiLibEditAce(
  Owner: TComponent;
  AccessMaskType: Pointer;
  const GenericMapping: TGenericMapping;
  const Ace: TAceData
): TAceData;
var
  ModalResult: IInterface;
begin
  if not Assigned(NtUiLibHostFramePick) then
    raise ENotSupportedException.Create('Frame host not available');

  ModalResult := NtUiLibHostFramePick(Owner, InitializerEx(AccessMaskType,
    GenericMapping, Ace));

  Result := TAceData((ModalResult as IMemory).Data^);
end;

initialization
  NtUiCommon.Prototypes.NtUiLibCreateAce := NtUiLibCreateAce;
  NtUiCommon.Prototypes.NtUiLibEditAce := NtUiLibEditAce;
end.
