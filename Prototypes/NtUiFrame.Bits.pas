unit NtUiFrame.Bits;

{
  This module provides a frame for showing bit masks and enumerations.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, Vcl.StdCtrls, Vcl.ExtCtrls, Ntapi.WinNt,
  DelphiUtils.AutoObjects, NtUiCommon.Interfaces, NtUiBackend.Bits;

type
  TBitsFrame = class(TFrame, IHasDefaultCaption)
    Tree: TDevirtualizedTree;
    BottomPanel: TPanel;
    tbxValue: TEdit;
    btnClear: TButton;
    btnAll: TButton;
    procedure tbxValueChange(Sender: TObject);
    procedure TreeChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure btnClearClick(Sender: TObject);
    procedure btnAllClick(Sender: TObject);
  private
    FTypeSize: Byte;
    FValidMask: UInt64;
    FValue: UInt64;
    FIsReadOnly: Boolean;
    function SuppressTreeReadOnly: IAutoReleasable;
    procedure RefreshText(Editing: Boolean = False);
    procedure RefreshItems;
    procedure SetValue(const NewValue: UInt64);
    procedure SetTreeReadOnly(const Value: Boolean);
    procedure SetReadOnly(const Value: Boolean);
    function GetDefaultCaption: String;
  public
    procedure LoadType(ATypeInfo: Pointer);
    procedure LoadAccessMaskType(
      ATypeInfo: Pointer;
      const GenericMapping: TGenericMapping;
      ShowGenericRights: Boolean;
      ShowMiscRights: Boolean
    );
    property Value: UInt64 read FValue write SetValue;
    property IsReadOnly: Boolean read FIsReadOnly write SetReadOnly;
  end;

implementation

uses
  VirtualTrees.Types, NtUiCommon.Helpers, NtUiCommon.Colors, DelphiUiLib.Reflection.Strings,
  DelphiUiLib.Strings, NtUiCommon.Prototypes;

{$R *.dfm}

{ TBitsFrame }

procedure TBitsFrame.btnAllClick;
begin
  Value := FValidMask;
end;

procedure TBitsFrame.btnClearClick;
begin
  Value := 0;
end;

function TBitsFrame.GetDefaultCaption;
begin
  if FIsReadOnly then
    Result := 'Bit Mask Viewer'
  else
    Result := 'Bit Mask Editor'
end;

procedure TBitsFrame.LoadAccessMaskType;
begin
  SuppressTreeReadOnly;
  FTypeSize := SizeOf(TAccessMask);
  UiLibAddAccessMaskNodes(Tree, ATypeInfo, GenericMapping, FValidMask,
    ShowGenericRights, ShowMiscRights);

  // Update item states
  SetValue(FValue);
end;

procedure TBitsFrame.LoadType;
begin
  SuppressTreeReadOnly;
  UiLibAddBitNodes(Tree, ATypeInfo, FTypeSize, FValidMask);

  // Update item states
  SetValue(FValue);
end;

procedure TBitsFrame.RefreshItems;
const
  CHECK_STATE: array [Boolean] of TCheckState = (
    csUncheckedNormal, csCheckedNormal);
var
  Node: PVirtualNode;
  FlagNode: IFlagNode;
  OnCheckedReverter: IDeferredOperation;
begin
  Tree.BeginUpdateAuto;
  SuppressTreeReadOnly;
  Tree.OnChecked := nil;
  OnCheckedReverter := Auto.Defer(
    procedure
    begin
      Tree.OnChecked := TreeChecked;
    end
  );

  // Update states for checkboxes
  for Node in Tree.Nodes do
    if Node.TryGetProvider(IFlagNode, FlagNode) then
      Tree.CheckState[Node] := CHECK_STATE[(FlagNode.Mask and FValue) =
        FlagNode.Value];
end;

procedure TBitsFrame.RefreshText;
var
  OnCheckedReverter: IDeferredOperation;
begin
  if not Editing then
  begin
    tbxValue.OnChange := nil;
    OnCheckedReverter := Auto.Defer(
      procedure
      begin
        tbxValue.OnChange := tbxValueChange;
      end
    );

    // Update the text
    tbxValue.Text := UIntToHexEx(FValue, FTypeSize * 2);
  end;

  tbxValue.Hint := BuildHint('Decimal', UIntToStrEx(FValue));
  tbxValue.Color := clWindow;
end;

procedure TBitsFrame.SetReadOnly;
begin
  FIsReadOnly := Value;
  btnClear.Visible := not Value;
  btnAll.Visible := not Value;
  tbxValue.ReadOnly := Value;
  SetTreeReadOnly(Value);
  RefreshText;
end;

procedure TBitsFrame.SetTreeReadOnly;
begin
  if Value then
    Tree.TreeOptions.MiscOptions := Tree.TreeOptions.MiscOptions + [toReadOnly]
  else
    Tree.TreeOptions.MiscOptions := Tree.TreeOptions.MiscOptions - [toReadOnly];
end;

procedure TBitsFrame.SetValue;
begin
  FValue := NewValue;
  RefreshText;
  RefreshItems;
end;

function TBitsFrame.SuppressTreeReadOnly;
begin
  if FIsReadOnly then
  begin
    SetTreeReadOnly(False);
    Result := Auto.Defer(
      procedure
      begin
        SetTreeReadOnly(True);
      end
    );
  end
  else
    Result := nil;
end;

procedure TBitsFrame.tbxValueChange;
var
  NewValue: UInt64;
begin
  if TryStrToUInt64Ex(tbxValue.Text, NewValue) then
  begin
    // Truncate the value to the size of the type
    case FTypeSize of
      1: NewValue := NewValue and Byte(-1);
      2: NewValue := NewValue and Word(-1);
      4: NewValue := NewValue and Cardinal(-1);
    end;

    FValue := NewValue;
    RefreshText(True);
    RefreshItems;
  end
  else
    tbxValue.Color := ColorSettings.clBackgroundError;
end;

procedure TBitsFrame.TreeChecked;
var
  FlagNode: IFlagNode;
begin
  if not Node.TryGetProvider(IFlagNode, FlagNode) then
    Exit;

  // Modify the value according to the change
  case Tree.CheckState[Node] of
    csUncheckedNormal:
      if Tree.CheckType[Node] = ctCheckBox then
        FValue := FValue and not FlagNode.Value;

    csCheckedNormal:
      FValue := (FValue and not FlagNode.Mask) or FlagNode.Value;
  end;

  RefreshText;
  RefreshItems;
end;

procedure NtUiLibShowBitMask(
  const Value: UInt64;
  ATypeInfo: Pointer
);
begin
  if not Assigned(NtUiLibHostFrameShow) then
    raise ENotSupportedException.Create('Frame host not available');

  NtUiLibHostFrameShow(
    function (AOwner: TComponent): TFrame
    var
      Frame: TBitsFrame absolute Result;
    begin
      Frame := TBitsFrame.Create(AOwner);
      try
        Frame.LoadType(ATypeInfo);
        Frame.Value := Value;
        Frame.IsReadOnly := True;
      except
        Frame.Free;
        raise;
      end;
    end
  );
end;

procedure NtUiLibShowAccessMask(
  const Value: TAccessMask;
  ATypeInfo: Pointer;
  const GenericMapping: TGenericMapping
);
begin
  if not Assigned(NtUiLibHostFrameShow) then
    raise ENotSupportedException.Create('Frame host not available');

  NtUiLibHostFrameShow(
    function (AOwner: TComponent): TFrame
    var
      Frame: TBitsFrame absolute Result;
    begin
      Frame := TBitsFrame.Create(AOwner);
      try
        Frame.LoadAccessMaskType(ATypeInfo, GenericMapping, False, False);
        Frame.Value := Value;
        Frame.IsReadOnly := True;
      except
        Frame.Free;
        raise;
      end;
    end
  );
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowBitMask := NtUiLibShowBitMask;
  NtUiCommon.Prototypes.NtUiLibShowAccessMask := NtUiLibShowAccessMask;
end.
