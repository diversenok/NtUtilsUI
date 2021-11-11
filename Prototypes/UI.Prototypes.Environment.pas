unit UI.Prototypes.Environment;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  VclEx.ListView, NtUtils, NtUtils.Environment;

type
  TEnvironmentGroupCallback = reference to function (const Variable:
    TEnvVariable): Boolean;

  TEnvironmentHightligter = reference to function (const Variable:
    TEnvVariable; out Color: TColor): Boolean;

  TEnvironmentGroup = record
    Name: String;
    HasColor: Boolean;
    Color: TColor;
    Callback: TEnvironmentGroupCallback;
  end;

  TEnvironmentFrame = class(TFrame)
    ListViewEx: TListViewEx;
  private
    FEnvirinment: IEnvironment;
    FGroups: TArray<TEnvironmentGroup>;
    FHighlight: TArray<TEnvironmentHightligter>;
    procedure SetVariable(Item: TListItemEx; const Variable: TEnvVariable);
    procedure SetEnvironment(const Value: IEnvironment);
    procedure SetGroups(const Value: TArray<TEnvironmentGroup>);
    procedure SetHighlighting(const Value: TArray<TEnvironmentHightligter>);
  public
    property Envirinment: IEnvironment read FEnvirinment write SetEnvironment;
    property Groups: TArray<TEnvironmentGroup> write SetGroups;
    property Highlight: TArray<TEnvironmentHightligter> write SetHighlighting;
  end;

// Prepare default groupping of environment variables by their origin
function GroupByOrigin(hxToken: IHandle): TArray<TEnvironmentGroup>;

// Highlight internal environment variables that start with the equal sign
function HighlightCmd: TArray<TEnvironmentHightligter>;

implementation

uses
  NtUtils.Environment.User, UI.Colors, NtUtils.SysUtils;

{$R *.dfm}

{ TEnvironmentFrame }

procedure TEnvironmentFrame.SetEnvironment(const Value: IEnvironment);
var
  i: Integer;
  Variables: TArray<TEnvVariable>;
begin
  FEnvirinment := Value;

  if Assigned(Value) then
    Variables := RtlxEnumerateEnvironmemt(Value)
  else
    Variables := nil;

  ListViewEx.Items.BeginUpdate(True);
  ListViewEx.Items.Clear;

  ListViewEx.GroupView := Length(FGroups) > 0;

  // Reload all variables
  for i := 0 to High(Variables) do
    SetVariable(ListViewEx.Items.Add, Variables[i]);

  ListViewEx.Items.EndUpdate(True);
end;

procedure TEnvironmentFrame.SetGroups(const Value: TArray<TEnvironmentGroup>);
var
  i: Integer;
begin
  FGroups := Copy(Value, 0, Length(Value));

  ListViewEx.Groups.BeginUpdate;
  ListViewEx.Groups.Clear;

  // Add all groups
  for i := 0 to High(FGroups) do
    with ListViewEx.Groups.Add do
    begin
      Header := FGroups[i].Name;
      State := [lgsNormal, lgsCollapsible];
    end;

  ListViewEx.Groups.EndUpdate;
  SetEnvironment(FEnvirinment);
end;

procedure TEnvironmentFrame.SetHighlighting(const Value:
  TArray<TEnvironmentHightligter>);
var
  i: Integer;
begin
  FHighlight := Value;
  SetEnvironment(FEnvirinment);
end;

procedure TEnvironmentFrame.SetVariable(Item: TListItemEx;
  const Variable: TEnvVariable);
var
  i: Integer;
  ColorOverride: TColor;
begin
  Item.Cell[0] := Variable.Name;
  Item.Cell[1] := Variable.Value;

  // Find a group for the variable going from the most to the least specific.
  // Treat no callback as a match, so we can simplify the global fallback.

  for i := High(FGroups) downto 0 do
    if not Assigned(FGroups[i].Callback) or FGroups[i].Callback(Variable) then
    begin
      Item.GroupID := i;

      if FGroups[i].HasColor then
        Item.Color := FGroups[i].Color;

      Break;
    end;

  // Override group-based colors with highlighting
  for i := 0 to High(FHighlight) do
    if FHighlight[i](Variable, ColorOverride) then
      Item.Color := ColorOverride;
end;

{ Functions }

function GroupByOrigin;
var
  SystemEnv, UserEnv: IEnvironment;
begin
  // Prepare the canonical environment for the system and the user
  UnvxCreateUserEnvironment(SystemEnv, nil);
  UnvxCreateUserEnvironment(UserEnv, hxToken);

  SetLength(Result, 3);

  // Mark as "Process" everything that does not fall into other categories
  Result[0].Name := 'Process';
  Result[0].HasColor := True;
  Result[0].Color := ColorSettings.clProcess;
  Result[0].Callback := nil;

  Result[1].Name := 'User';
  Result[1].HasColor := True;
  Result[1].Color := ColorSettings.clUser;
  Result[1].Callback :=
    function (const Variable: TEnvVariable): Boolean
    var
      Value: String;
    begin
      // Mask the variables that match those from the user profile
      Result := Assigned(UserEnv) and RtlxQueryVariableEnvironment(UserEnv,
        Variable.Name, Value).IsSuccess and (Value = Variable.Value);
    end;

  Result[2].Name := 'System';
  Result[2].HasColor := True;
  Result[2].Color := ColorSettings.clSystem;
  Result[2].Callback :=
    function (const Variable: TEnvVariable): Boolean
    var
      Value: String;
    begin
      // Mask the variables that match those for all users
      Result := Assigned(SystemEnv) and RtlxQueryVariableEnvironment(SystemEnv,
        Variable.Name, Value).IsSuccess and (Value = Variable.Value);
    end;
end;

function HighlightCmd: TArray<TEnvironmentHightligter>;
begin
  Result := [
    function (const Variable: TEnvVariable; out Color: TColor): Boolean
    begin
      Result := RtlxPrefixString('=', Variable.Name, False);

      if Result then
        Color := ColorSettings.clDebug;
    end
  ];
end;

end.
