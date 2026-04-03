unit NtUiCommon.Helpers;

interface

uses
  Vcl.StdCtrls;

type
  TComboBoxHelper = class helper for TComboBox
    // Update the list of items preserving selection
    procedure UpdateItems(const NewItems: TArray<String>; FallbackIndex: Integer = -1);
  end;

  // Change of checkbox state that does not issue OnClick event
  TCheckBoxHack = class helper for TCheckBox
    procedure SetStateEx(Value: TCheckBoxState);
    procedure SetCheckedEx(Value: Boolean);
  end;

implementation

uses
  NtUtils, System.Classes;

{ TComboBoxHelper }

procedure TComboBoxHelper.UpdateItems;
var
  PreviousEvent: TNotifyEvent;
  PreviousItem: String;
  PreviousItemFound: Boolean;
  AutoEndUpdate: IDeferredOperation;
  i: Integer;
begin
  // Save the current state
  PreviousItem := Self.Text;
  PreviousEvent := Self.OnChange;

  // Remove all items
  Self.OnChange := nil;
  Self.Items.BeginUpdate;
  AutoEndUpdate := Auto.Defer(
    procedure
    begin
      Self.Items.EndUpdate;
      Self.OnChange := PreviousEvent;
    end
  );
  Self.Clear;

  // Add new items
  for i := 0 to High(NewItems) do
    Self.Items.Add(NewItems[i]);

  // Restore selection
  PreviousItemFound := False;
  for i := 0 to Pred(Self.Items.Count) do
    if Self.Items[i] = PreviousItem then
    begin
      Self.Text := PreviousItem;
      Self.ItemIndex := i;
      PreviousItemFound := True;
      Break;
    end;

  // Reset selection if necessary
  if not PreviousItemFound then
  begin
    Self.Text := PreviousItem;
    Self.ItemIndex := FallbackIndex;
  end;
end;

{ TCheckBoxHack }

procedure TCheckBoxHack.SetCheckedEx;
begin
  ClicksDisabled := True;
  Checked := Value;
  ClicksDisabled := False;
end;

procedure TCheckBoxHack.SetStateEx;
begin
  ClicksDisabled := True;
  State := Value;
  ClicksDisabled := False;
end;

end.
