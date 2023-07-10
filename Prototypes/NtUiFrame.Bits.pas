unit NtUiFrame.Bits;

{
  This module provides a frame for showing bit masks and enumerations.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  VirtualTreesEx, DevirtualizedTree, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TBitsFrame = class(TFrame)
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
    FTypeSize: Integer;
    FValidMask: UInt64;
    FValue: UInt64;
    FIsReadOnly: Boolean;
    procedure RefreshText(Editing: Boolean = False);
    procedure RefreshItems;
    procedure SetValue(const NewValue: UInt64);
    procedure SetReadOnly(const Value: Boolean);
  public
    procedure LoadType(ATypeInfo: Pointer);
    property Value: UInt64 read FValue write SetValue;
    property IsReadOnly: Boolean read FIsReadOnly write SetReadOnly;
  end;

implementation

uses
  NtUiBackend.Bits, VirtualTrees.Types, UI.Helper, UI.Colors,
  DelphiUiLib.Reflection.Strings, DelphiUiLib.Strings, DelphiUtils.AutoObjects;

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

procedure TBitsFrame.LoadType;
var
  ReadOnlyReverter: IAutoReleasable;
begin
  // Modifying the tree doesn't work in read-only mode; temporarily disable it
  if IsReadOnly then
  begin
    IsReadOnly := False;
    ReadOnlyReverter := Auto.Delay(
      procedure
      begin
        IsReadOnly := True;
      end
    );
  end;

  // Populate the nodes
  UiLibAddBitNodes(Tree, ATypeInfo, FTypeSize, FValidMask);
  Value := 0;
end;

procedure TBitsFrame.RefreshItems;
const
  CHECK_STATE: array [Boolean] of TCheckState = (
    csUncheckedNormal, csCheckedNormal);
var
  Node: PVirtualNode;
  FlagNode: IFlagNode;
begin
  Tree.BeginUpdateAuto;
  Tree.OnChecked := nil;
  Auto.Delay(
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
begin
  if not Editing then
  begin
    tbxValue.OnChange := nil;
    Auto.Delay(
      procedure
      begin
        tbxValue.OnChange := tbxValueChange;
      end
    );

    // Update the text
    tbxValue.Text := IntToHexEx(FValue, FTypeSize * 2);
  end;

  tbxValue.Hint := BuildHint('Decimal', IntToStrEx(FValue));
  tbxValue.Color := clWindow;
end;

procedure TBitsFrame.SetReadOnly;
begin
  FIsReadOnly := Value;
  btnClear.Visible := not Value;
  btnAll.Visible := not Value;
  tbxValue.ReadOnly := Value;

  if Value then
    Tree.TreeOptions.MiscOptions := Tree.TreeOptions.MiscOptions + [toReadOnly]
  else
    Tree.TreeOptions.MiscOptions := Tree.TreeOptions.MiscOptions - [toReadOnly];

  RefreshText;
end;

procedure TBitsFrame.SetValue;
begin
  FValue := NewValue;
  RefreshText;
  RefreshItems;
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
    tbxValue.Color := ColorSettings.clDisabledModified;
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

end.
