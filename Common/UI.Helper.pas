unit UI.Helper;

interface

uses
  VirtualTrees, VirtualTreesEx, Vcl.StdCtrls, Vcl.Menus, System.Classes,
  NtUtils, DelphiUtils.Arrays;

type
  TCollectionHelper = class helper for TCollection
    function BeginUpdateAuto: IAutoReleasable;
  end;

  // Automatic operations on virtual tree views
  TVirtualTreeAutoHelper = class helper for TBaseVirtualTree
    function BeginUpdateAuto: IAutoReleasable;
    function BackupSelectionAuto(Comparer: TMapRoutine<PVirtualNode, TCondition<PVirtualNode>>): IDeferredOperation;
  end;

  TComboBoxHelper = class helper for TComboBox
    // Update the list of items preserving selection
    procedure UpdateItems(const NewItems: TArray<String>; FallbackIndex: Integer = -1);
  end;

  // Change of checkbox state that does not issue OnClick event
  TCheckBoxHack = class helper for TCheckBox
    procedure SetStateEx(Value: TCheckBoxState);
    procedure SetCheckedEx(Value: Boolean);
  end;

  // A type that captures shortcuts of items in a popup menu
  TMenuShortCut = record
    Menu: TMenuItem;
    ShiftState: TShiftState;
    Key: Word;
    constructor Create(Item: TMenuItem);
    class function Collect(Item: TMenuItem): TArray<TMenuShortCut>; static;
  end;

implementation

{ TCollectionHelper }

function TCollectionHelper.BeginUpdateAuto;
begin
  BeginUpdate;

  Result := Auto.Defer(
    procedure
    begin
      EndUpdate;
    end
  );
end;

{ TVirtualTreeAutoHelper }

function TVirtualTreeAutoHelper.BackupSelectionAuto;
var
  SelectionConditions: TArray<TCondition<PVirtualNode>>;
  FocusCondition: TCondition<PVirtualNode>;
begin
  // For each selected node, capture necessary data for later comparison
  SelectionConditions := TArray.Map<PVirtualNode, TCondition<PVirtualNode>>(
    SelectedNodes.ToArray, Comparer);

  // Same for the focused node
  if Assigned(FocusedNode) then
    FocusCondition := Comparer(FocusedNode)
  else
    FocusCondition := nil;

  // Restore selection afterward
  Result := Auto.Defer(
    procedure
    var
      SelectionCondition: TCondition<PVirtualNode>;
      Node: PVirtualNode;
      UpdateReleaser: IAutoReleasable;
    begin
      UpdateReleaser := BeginUpdateAuto;

      // Check if each new node matches any conditions for selection
      for Node in Nodes do
      begin
        for SelectionCondition in SelectionConditions do
          if Assigned(SelectionCondition) and SelectionCondition(Node) then
          begin
            Selected[Node] := True;
            Break;
          end;

        // Same for the focus
        if Assigned(FocusCondition) and FocusCondition(Node) then
          FocusedNode := Node;
      end;

      // Re-apply sorting
      Sort(RootNode, Header.SortColumn, Header.SortDirection);
    end
  );
end;

function TVirtualTreeAutoHelper.BeginUpdateAuto;
begin
  BeginUpdate;

  Result := Auto.Defer(
    procedure
    begin
      EndUpdate;
    end
  );
end;

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

  { TMenuShortCut }

class function TMenuShortCut.Collect;
begin
  Result := nil;

  if Item.ShortCut <> 0 then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := TMenuShortCut.Create(Item);
  end;

  for Item in Item do
    Result := Result + TMenuShortCut.Collect(Item);
end;

constructor TMenuShortCut.Create;
begin
  Menu := Item;
  Key := Item.ShortCut and $FFF;
  ShiftState := [];

  if BitTest(Item.ShortCut and scCommand) then
    Include(ShiftState, ssCommand);

  if BitTest(Item.ShortCut and scCtrl) then
    Include(ShiftState, ssCtrl);

  if BitTest(Item.ShortCut and scShift) then
    Include(ShiftState, ssShift);

  if BitTest(Item.ShortCut and scAlt) then
    Include(ShiftState, ssAlt);
end;

end.
