unit NtUtilsUI.Processes;

{
  This module provides a process selection dialog.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VirtualTrees,
  NtUtilsUI.Tree, NtUtilsUI.Tree.Search, NtUtilsUI.Base, NtUtilsUI.SessionID,
  Vcl.StdCtrls, NtUtilsUI.Tree.Hysteresis, NtUtils.Processes.Snapshots,
  Vcl.ExtCtrls, Vcl.Menus, Ntapi.WinNt, NtUtilsUI;

type
  TUiLibProcessSnapshotMethod = (
    psNormal,
    psExtended,
    psFull,
    psSession,
    psGetNext,
    psNtdll,
    psBruteforce
  );

  [DefaultCaption('Processes')]
  TUiLibProcesses = class(TFrame, IModalResult<TProcessId>,
    IModalResultControl)
    ComboBoxMethod: TComboBox;
    SessionIdBox: TUiLibSessionIdBox;
    SearchBox: TUiLibTreeSearchBox;
    Tree: TUiLibTree;
    RefreshTimer: TTimer;
    LabelMethod: TLabel;
    LabelSession: TLabel;
    LabelCount: TLabel;
    LabelTotal: TLabel;
    LabelPeak: TLabel;
    procedure RefreshTimerTimer(Sender: TObject);
    procedure ComboBoxMethodChange(Sender: TObject);
    procedure SessionIdBoxChange(Sender: TObject);
    procedure TreeSortChange(Sender: TObject);
    procedure TreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeMainAction(Node: INodeProvider);
  private
    SnapshotMethod: TUiLibProcessSnapshotMethod;
    HysteresisContainer: IUiLibHysteresisContainer<TNtxProcessEntry>;
    FRefreshShortcut: TUiLibShortCut;
    FOnModalResultAvailabilityChange: TOnModalResultAvailabilityChange;
    FOnModalComplete: TNotifyEvent;
    procedure Refresh;
    procedure RefreshNoDiff;
    procedure RefreshShortcut(Sender: TUiLibShortCut; var Handled: Boolean);
    function GetModalResult: TProcessId;
    function GetModalResultType: Pointer;
    procedure SetOnModalResultAvailabilityChange(Event: TOnModalResultAvailabilityChange);
    procedure SetOnModalComplete(Event: TNotifyEvent);
  protected
    procedure Loaded; override;
  public
    class function Factory: TWinControlFactory; static;
  end;

implementation

uses
  Ntapi.ntpebteb, NtUtils, NtUtils.SysUtils, NtUtils.Files, NtUtils.Objects,
  NtUtils.Processes.Info, NtUtils.Objects.Snapshots, NtUiLib.Errors,
  DelphiUiLib.Strings, DelphiUiLib.HysteresisTree, NtUiCommon.Icons,
  Vcl.ImgList, System.UITypes, NtUtilsUI.Components.Factories;

{$R *.dfm}

const
  colImageName = 0;
  colPid = 1;
  colPidHex = 2;
  colFullImageName = 3;
  colMax = 4;

type
  IProcessNode = interface (IHysteresisNodeProvider<TNtxProcessEntry>)
    ['{33B48588-049A-4F36-998F-787C4D9E8D40}']
    function GetProcess: PNtxProcessEntry;
    property Process: PNtxProcessEntry read GetProcess;
  end;

  TProcessNode = class (THysteresisNodeProvider<TNtxProcessEntry>, IProcessNode)
  private
    FImageIndex: TImageIndex;
    function GetProcess: PNtxProcessEntry;
  protected
    procedure PreUpdate; override;
    function GetColor(out Value: TColor): Boolean; override;
    function GetFontColor(out Value: TColor): Boolean; override;
    function GetIcon(Column: TColumnIndex; out ImageIndex: TImageIndex): TCustomImageList; override;
    function SearchNumber(const Value: UInt64; Column: TColumnIndex): Boolean; override;
    function SortCompare(Node: INodeProvider; Column: TColumnIndex): Integer; override;
    procedure Initialize; override;
    property Process: PNtxProcessEntry read GetProcess;
  end;

{ TProcessNode }

function TProcessNode.GetColor(out Value: TColor): Boolean;
begin
  if HysteresisNode.TransitionState <> hntNormal then
  begin
    Result := inherited;
    Exit;
  end;

  Result := False;

  // Highlight the current process
  if Process.Basic.ProcessID = NtCurrentTeb.ClientID.UniqueProcess then
  begin
    Result := True;
    Value := ColorSettings.clBackgroundUser;
  end;
end;

function TProcessNode.GetFontColor;
begin
  Result := HysteresisNode.Data.IsTerminated;

  if Result then
    Value := ColorSettings.clForegroundInactive;
end;

function TProcessNode.GetIcon;
begin
  if Column = 0 then
  begin
    Result := TProcessIcons.ImageList;
    ImageIndex := FImageIndex;
  end
  else
    Result := nil;
end;

function TProcessNode.GetProcess;
begin
  Result := HysteresisNode.DataStart;
end;

procedure TProcessNode.Initialize;
begin
  inherited;
  SetLength(FColumnText, colMax);

  // Query the full image name if not yet available. We'll need it for the icon
  if Process.Full.ImagePath = '' then
    NtxQueryImageNameProcessId(Process.Basic.ProcessID, Process.Full.ImagePath);

  // Populate the columns
  FColumnText[colImageName] := RtlxStringOrDefault(Process.ImageName,
    '(Unnamed process)');
  FColumnText[colPid] := UiLibUIntToDec(Process.Basic.ProcessID);
  FColumnText[colPidHex] := UiLibUIntToHex(Process.Basic.ProcessID);
  FColumnText[colFullImageName] := Process.Full.ImagePath;

  // Query and cache the icon
  FImageIndex := TProcessIcons.GetIcon(RtlxNativePathToDosPath(
    Process.Full.ImagePath));
end;

procedure TProcessNode.PreUpdate;
begin
  inherited;

  // Make sure our handles don't keep processes in a zombie state
  if Process.IsTerminated then
    NtxCloseHandleIfLast(Process.hxProcess);
end;

function TProcessNode.SearchNumber;
begin
  if (Column < 0) or (Column = colPID) or (Column = colPidHex) then
    Result := Value = HysteresisNode.Data.Basic.ProcessID
  else
    Result := False;
end;

function TProcessNode.SortCompare;
begin
  if Column in [colPid, colPidHex] then
    {$R-}{$Q-}
    // Use the original order when resetting sorting
    Result := (Node as IProcessNode).Process.Basic.ProcessID -
      Process.Basic.ProcessID
    {$IFDEF Q+}{$Q+}{$ENDIF}{$IFDEF R+}{$R+}{$ENDIF}
  else
    Result := inherited;
end;

{ TUiLibProcesses }

procedure TUiLibProcesses.ComboBoxMethodChange;
begin
  SnapshotMethod := TUiLibProcessSnapshotMethod(ComboBoxMethod.ItemIndex);
  SessionIdBox.Enabled := SnapshotMethod = psSession;
  RefreshNoDiff;
end;

class function TUiLibProcesses.Factory;
begin
  Result := function (AOwner: TComponent): TWinControl
    begin
      Result := TUiLibProcesses.Create(AOwner);
    end;
end;

function TUiLibProcesses.GetModalResult;
begin
  Result := (Tree.HighlightedNode.Provider as
    IProcessNode).Process.Basic.ProcessID;
end;

function TUiLibProcesses.GetModalResultType;
begin
  Result := TypeInfo(TProcessId);
end;

procedure TUiLibProcesses.Loaded;
begin
  inherited;

  FRefreshShortcut := TUiLibShortCut.Create(Self);
  FRefreshShortcut.ShortCut := VK_F5;
  FRefreshShortcut.OnExecute := RefreshShortcut;

  SearchBox.AttachToTree(Tree);
  HysteresisContainer := TUiLibHysteresisContainer<TNtxProcessEntry>.Initialize(
    Tree, TProcessNode, RtlxIsSameProcess);
  HysteresisContainer.Core.ParentCheck := RtlxIsParentProcess;
  HysteresisContainer.Core.TransitionTime := 1;
end;

procedure TUiLibProcesses.Refresh;
var
  Processes: TArray<TNtxProcessEntry>;
  ProcessType: TNtxObjectTypeInfo;
  Status: TNtxStatus;
  StartTime: TDateTime;
  DurationMillisec: Integer;
begin
  // Notify nodes we are starting an update sequence
  HysteresisContainer.PreUpdate;

  // Enumerate processes
  StartTime := Now;
  case SnapshotMethod of
    psNormal:     Status := NtxEnumerateProcesses(Processes);
    psExtended:   Status := NtxEnumerateProcessesEx(Processes);
    psFull:       Status := NtxEnumerateProcessesFull(Processes);
    psSession:    Status := NtxEnumerateProcessesSession(Processes, SessionIdBox.SessionID);
    psGetNext:    Status := NtxEnumerateProcessesGetNext(Processes);
    psNtdll:      Status := NtxEnumerateProcessesByNtdll(Processes);
    psBruteforce: Status := NtxEnumerateProcessesBruteforce(Processes);
  else
    Exit;
  end;
  DurationMillisec := Round((Now - StartTime) * 86400 * 1000);

  // Ntdll and bruteforce methods are not very fast. Detect if enumeration takes
  // too long and slow down the refresh rate accordingly to make UI resonsive.
  if DurationMillisec > 333 then
    RefreshTimer.Interval := DurationMillisec * 3
  else
    RefreshTimer.Interval := 1000;

  // Report status
  if Status.IsSuccess then
    Tree.EmptyListMessage := 'No items to display'
  else
  begin
    Tree.EmptyListMessage := Status.ToString;
    Processes := nil;
  end;

  // Give the snapshot to the hysteresis tree container which will compare it to
  // the previous state and issue necessary node transformation events
  HysteresisContainer.Update(Processes);
  SearchBox.ReapplySearch;
  Tree.SortIfNecessary;

  // Refresh informational labels
  LabelCount.Caption := 'Displaying: ' + UiLibUIntToDec(Length(Processes));

  if RtlxFindKernelType('Process', ProcessType, False).IsSuccess then
  begin
    LabelTotal.Caption := 'Total: ' + UiLibUIntToDec(
      ProcessType.Native.TotalNumberOfObjects);
    LabelPeak.Caption := 'Peak: ' + UiLibUIntToDec(
      ProcessType.Native.HighWaterNumberOfObjects);
  end
  else
  begin
    LabelTotal.Caption := 'Total: (unknown)';
    LabelPeak.Caption := 'Peak: (unknown)';
  end;
end;

procedure TUiLibProcesses.RefreshNoDiff;
var
  TTL: Integer;
begin
  // Suppress transitions for one update
  TTL := HysteresisContainer.Core.TransitionTime;
  HysteresisContainer.Core.TransitionTime := 0;
  Refresh;
  HysteresisContainer.Core.TransitionTime := TTL;
end;

procedure TUiLibProcesses.RefreshShortcut;
begin
  Refresh;
end;

procedure TUiLibProcesses.RefreshTimerTimer;
begin
  try
    Refresh;
  except
    // If something breaks, stop auto-refreshing to prevent spamming errors
    RefreshTimer.Enabled := False;
    raise;
  end;
end;

procedure TUiLibProcesses.SessionIdBoxChange;
begin
  RefreshNoDiff;
end;

procedure TUiLibProcesses.SetOnModalComplete;
begin
  FOnModalComplete := Event;
  Tree.MainActionMenuText := 'Select';
end;

procedure TUiLibProcesses.SetOnModalResultAvailabilityChange;
begin
  FOnModalResultAvailabilityChange := Event;
  TreeChange(nil, nil);
end;

procedure TUiLibProcesses.TreeChange;
begin
  if Assigned(FOnModalResultAvailabilityChange) then
    FOnModalResultAvailabilityChange(Assigned(Tree.HighlightedNode));
end;

procedure TUiLibProcesses.TreeMainAction;
begin
  if Assigned(FOnModalComplete) then
    FOnModalComplete(Self);
end;

procedure TUiLibProcesses.TreeSortChange;
begin
  // Disable the tree hierarchy when items are sorted
  if Tree.Header.SortColumn = NoColumn then
    HysteresisContainer.Core.ParentCheck := RtlxIsParentProcess
  else
    HysteresisContainer.Core.ParentCheck := nil;

  RefreshNoDiff;
end;

initialization
  UiLibFactoryProcess := TUiLibProcesses.Factory;
end.
