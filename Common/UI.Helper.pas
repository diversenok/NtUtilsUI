unit UI.Helper;

interface

uses
  VirtualTrees, Vcl.StdCtrls, NtUtils;

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

implementation

function BeginUpdateAuto;
begin
  VST.BeginUpdate;

  Result := TDelayedOperation.Create(
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


end.
