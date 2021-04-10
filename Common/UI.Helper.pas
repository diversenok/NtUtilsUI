unit UI.Helper;

interface

uses
  VirtualTrees, Vcl.StdCtrls, Vcl.Menus, System.Classes, NtUtils;

// Call BeginUpdate and queue a deferred EndUpdate
function BeginUpdateAuto(VST: TBaseVirtualTree): IAutoReleasable;

// Convert virtual node enumeration into an array
function CollectNodes(Nodes: TVTVirtualNodeEnumeration): TArray<PVirtualNode>;

type
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

function BeginUpdateAuto;
begin
  VST.BeginUpdate;

  Result := TDelayedOperation.Delay(
    procedure
    begin
      VST.EndUpdate;
    end
  );
end;

function CollectNodes;
var
  Node: PVirtualNode;
  Count: Integer;
begin
  Count := 0;
  for Node in Nodes do
    Inc(Count);

  SetLength(Result, Count);

  Count := 0;
  for Node in Nodes do
  begin
    Result[Count] := Node;
    Inc(Count);
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
