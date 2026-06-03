unit NtUtilsUI.Processes.Threads;

{
  This module provides a thread selection control.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  NtUtilsUI.Base, NtUtilsUI.Tree.Search, NtUtilsUI.SessionID, VirtualTrees,
  NtUtilsUI.Tree, NtUtilsUI.Tree.Hysteresis, NtUtils.Processes.Snapshots,
  Vcl.ExtCtrls, NtUtils, Ntapi.ntdef, Ntapi.WinNt, NtUtilsUI, Vcl.Menus;

type
  TUiLibThreadSnapshotMethod = (
    tsNormal,
    tsExtended,
    tsFull,
    tsSession,
    tsGetNext,
    tsBruteforce
  );

  TUiLibThreads = class(TFrame, IModalResult<TClientId>,
    IModalResultControl, IDefaultCaption)
    SearchBox: TUiLibTreeSearchBox;
    LabelMethod: TLabel;
    ComboBoxMethod: TComboBox;
    LabelSession: TLabel;
    SessionIdBox: TUiLibSessionIdBox;
    Tree: TUiLibTree;
    LabelCount: TLabel;
    LabelTotal: TLabel;
    LabelPeak: TLabel;
    RefreshTimer: TTimer;
    PopupMenu: TPopupMenu;
    cmTerminate: TMenuItem;
    cmSuspend: TMenuItem;
    cmResume: TMenuItem;
    cmAlert: TMenuItem;
    cmAlertResume: TMenuItem;
    cmCancelO: TMenuItem;
    procedure ComboBoxMethodChange(Sender: TObject);
    procedure RefreshTimerTimer(Sender: TObject);
    procedure SessionIdBoxChange(Sender: TObject);
    procedure TreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeMainAction(Node: INodeProvider);
    procedure PopupMenuPopup(Sender: TObject);
    procedure cmTerminateClick(Sender: TObject);
    procedure cmSuspendClick(Sender: TObject);
    procedure cmResumeClick(Sender: TObject);
    procedure cmAlertClick(Sender: TObject);
    procedure cmAlertResumeClick(Sender: TObject);
    procedure cmCancelOClick(Sender: TObject);
  private
    FProcessId: TProcessId;
    SnapshotMethod: TUiLibThreadSnapshotMethod;
    HysteresisContainer: IUiLibHysteresisContainer<TNtxThreadEntry>;
    FOnModalResultAvailabilityChange: TOnModalResultAvailabilityChange;
    FOnModalComplete: TNotifyEvent;
    function Snapshot(out Threads: TArray<TNtxThreadEntry>): TNtxStatus;
    procedure Refresh;
    procedure RefreshNoDiff;
    function GetDefaultCaption: String;
    function GetModalResult: TClientId;
    function GetModalResultType: Pointer;
    procedure SetOnModalResultAvailabilityChange(Event: TOnModalResultAvailabilityChange);
    procedure SetOnModalComplete(Event: TNotifyEvent);
    procedure AskForConfirmation(Action: String; const ClientId: TClientId);
    function HighlightedClientId: TClientId;
  protected
    procedure Loaded; override;
  public
    property ProcessId: TProcessId read FProcessId write FProcessId;
    class function Factory(ProcessId: TProcessId): TWinControlFactory; static;
  end;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntstatus, Ntapi.ntexapi, NtUtils.Threads, NtUtils.NtUser,
  NtUtils.Objects, NtUtils.Objects.Snapshots, NtUiLib.Errors, NtUiLib.TaskDialog,
  DelphiUiLib.LiteReflection, DelphiUiLib.LiteReflection.Types,
  DelphiUiLib.HysteresisTree, DelphiUiLib.Strings, NtUtilsUI.Components,
  NtUtilsUI.Components.Factories;

{$R *.dfm}

const
  colName = 0;
  colTid = 1;
  colTidHex = 2;
  colCreateTime = 3;
  colWaitReason = 4;
  colSuspendCount = 5;
  colMax = 6;

type
  IThreadNode = interface (IHysteresisNodeProvider<TNtxThreadEntry>)
    ['{D0A97EED-DB91-49E4-8709-82F0A6FFC936}']
    function GetThread: PNtxThreadEntry;
    property Thread: PNtxThreadEntry read GetThread;
  end;

  TThreadNodeCache = (
    tcHandle,
    tcName,
    tcCreationTime,
    tcIsGui,
    tcSuspendCount,
    tcWaitReason
  );

  TThreadNode = class (THysteresisNodeProvider<TNtxThreadEntry>, IThreadNode)
  private
    FControl: TUiLibThreads;
    hxThread: IHandle;
    FCached: array [TThreadNodeCache] of Boolean;
    IsGui: Boolean;
    SuspendCountKnown: Boolean;
    SuspendCount: Cardinal;
    function GetThread: PNtxThreadEntry;
    procedure EnsureHandleCached;
    procedure EnsureNameCached;
    procedure EnsureTimesCached;
    procedure EnsureIsGuiCached;
    procedure EnsureSuspendCount;
    procedure EnsureWaitReason;
  protected
    procedure PreUpdate; override;
    procedure PostUpdate; override;
    procedure Attach(Value: PVirtualNode); override;
    function GetColumnText(Column: TColumnIndex): String; override;
    function GetColor(out Value: TColor): Boolean; override;
    function GetFontColor(out Value: TColor): Boolean; override;
    function GetFontColorForColumn(Column: TColumnIndex; out Value: TColor): Boolean; override;
    function SearchNumber(const Value: UInt64; Column: TColumnIndex): Boolean; override;
    procedure Initialize; override;
    property Thread: PNtxThreadEntry read GetThread;
  end;

  TUiLibThreadModalCache = class (TModalResultCache<TClientId>)
    procedure Save(const ModalResultImplementor: IInterface); override;
    class function Factory: IModalResultCache; static;
  end;

{ TThreadNode }

procedure TThreadNode.EnsureTimesCached;
var
  Times: TKernelUserTimes;
begin
  if FCached[tcCreationTime] then
    Exit;

  FCached[tcCreationTime] := True;
  EnsureHandleCached;

  if (Thread.Basic.CreateTime <= 0) and Assigned(hxThread) and
    NtxThread.Query(hxThread, ThreadTimes, Times).IsSuccess then
  begin
    Thread.Basic.CreateTime := Times.CreateTime;
    Thread.Basic.KernelTime := Times.KernelTime;
    Thread.Basic.UserTime := Times.UserTime;
    Thread.IsTerminated := Times.ExitTime > 0;
  end;

  if Thread.Basic.CreateTime > 0 then
    FColumnText[colCreateTime] := UiLibNativeTimeToString(
      Thread.Basic.CreateTime)
  else
    FColumnText[colCreateTime] := '';
end;

procedure TThreadNode.EnsureWaitReason;
begin
  if FCached[tcWaitReason] then
    Exit;

  FCached[tcWaitReason] := True;

  if FControl.SnapshotMethod in [tsNormal, tsExtended, tsFull, tsSession] then
    FColumnText[colWaitReason] := Rttix.Format(Thread.Basic.WaitReason)
  else
    FColumnText[colWaitReason] := '';
end;

procedure TThreadNode.Attach;
begin
  inherited;
  FControl := FTree.Owner as TUiLibThreads;
end;

procedure TThreadNode.EnsureHandleCached;
begin
  if FCached[tcHandle] then
    Exit;

  FCached[tcHandle] := True;

  if Assigned(Thread.hxThread) then
  begin
    hxThread := Thread.hxThread;
    Thread.hxThread := nil;
  end
  else if not Assigned(hxThread) then
    NtxOpenThread(hxThread, Thread.Basic.ClientID.UniqueThread,
     THREAD_QUERY_LIMITED_INFORMATION, 0, Thread.Basic.ClientID.UniqueProcess);
end;

procedure TThreadNode.EnsureIsGuiCached;
begin
  if FCached[tcIsGui] then
    Exit;

  FCached[tcIsGui] := True;
  IsGui := NtxIsGuiThread(Thread.Basic.ClientID.UniqueThread);
end;

procedure TThreadNode.EnsureNameCached;
begin
  if FCached[tcName] then
    Exit;

  FCached[tcName] := True;
  EnsureHandleCached;

  if Assigned(hxThread) then
    NtxQueryNameThread(hxThread, FColumnText[colName])
  else
    FColumnText[colName] := '';
end;

procedure TThreadNode.EnsureSuspendCount;
begin
  if FCached[tcSuspendCount] then
    Exit;

  FCached[tcSuspendCount] := True;
  EnsureHandleCached;

  SuspendCountKnown := Assigned(hxThread) and NtxThread.Query(hxThread,
    ThreadSuspendCount, SuspendCount).IsSuccess;

  if SuspendCountKnown then
    FColumnText[colSuspendCount] := UiLibUIntToDec(SuspendCount)
  else
    FColumnText[colSuspendCount] := '';
end;

function TThreadNode.GetColor;
begin
  if HysteresisNode.TransitionState <> hntNormal then
  begin
    Result := inherited;
    Exit;
  end;

  // Suspension determined from snapshot
  if (Thread.Basic.WaitReason = TWaitReason.Suspended) or
    (Thread.Basic.WaitReason = TWaitReason.WrSuspended) then
  begin
    Result := True;
    Value := ColorSettings.clBackgroundSuspended;
    Exit;
  end;

  // Suspension determined from query
  EnsureSuspendCount;

  if SuspendCountKnown and (SuspendCount > 0) then
  begin
    Result := True;
    Value := ColorSettings.clBackgroundSuspended;
    Exit;
  end;

  // GUI state
  EnsureIsGuiCached;

  if IsGui then
  begin
    Result := True;
    Value := ColorSettings.clBackgroundGuiThread;
    Exit;
  end;

  Result := False;
end;

function TThreadNode.GetColumnText;
begin
  case Column of
    colName:          EnsureNameCached;
    colCreateTime:    EnsureTimesCached;
    colSuspendCount:  EnsureSuspendCount;
    colWaitReason:    EnsureWaitReason;
  end;

  Result := inherited;

  if (Column = colName) and (Result = '') then
    Result := 'Unnamed'
end;

function TThreadNode.GetFontColor;
begin
  EnsureTimesCached;
  Result := HysteresisNode.Data.IsTerminated;

  if Result then
    Value := ColorSettings.clForegroundInactive;
end;

function TThreadNode.GetFontColorForColumn;
begin
  Result := (Column = colName) and (FColumnText[colName] = '');

  if Result then
    Value := ColorSettings.clForegroundInactive;
end;

function TThreadNode.GetThread;
begin
  Result := HysteresisNode.DataStart;
end;

procedure TThreadNode.Initialize;
begin
  inherited;
  SetLength(FColumnText, colMax);

  // Populate static columns
  FColumnText[colTid] := UiLibUIntToDec(Thread.Basic.ClientID.UniqueThread);
  FColumnText[colTidHex] := UiLibUIntToHex(Thread.Basic.ClientID.UniqueThread);
end;

procedure TThreadNode.PostUpdate;
var
  i: TThreadNodeCache;
begin
  for i := Low(TThreadNodeCache) to High(TThreadNodeCache) do
    FCached[i] := False;

  inherited;
end;

procedure TThreadNode.PreUpdate;
begin
  inherited;

  // Make sure our handles don't keep threads in a zombie state
  if Thread.IsTerminated then
    NtxCloseHandleIfLast(hxThread);
end;

function TThreadNode.SearchNumber;
begin
  if (Column < 0) or (Column = colTid) or (Column = colTidHex) then
    Result := Value = Thread.Basic.ClientID.UniqueThread
  else if (Column = colSuspendCount) and SuspendCountKnown then
    Result := Value = SuspendCount
  else
    Result := False;
end;

{ TUiLibThreads }

procedure TUiLibThreads.AskForConfirmation;
begin
  ConfirmOperation(Handle, 'Are you sure you want to ' + Action + ' ' +
    Rttix.Format(ClientId));
end;

procedure TUiLibThreads.cmAlertClick;
var
  ClientId: TClientId;
  hxThread: IHandle;
begin
  ClientId := HighlightedClientId;
  NtxOpenThread(hxThread, ClientId.UniqueThread, THREAD_ALERT, 0,
    ClientId.UniqueProcess).RaiseOnError;
  AskForConfirmation('alert', ClientId);
  NtxAlertThread(hxThread).RaiseOnError;
end;

procedure TUiLibThreads.cmAlertResumeClick;
var
  ClientId: TClientId;
  hxThread: IHandle;
begin
  ClientId := HighlightedClientId;
  NtxOpenThread(hxThread, ClientId.UniqueThread, THREAD_SUSPEND_RESUME, 0,
    ClientId.UniqueProcess).RaiseOnError;
  AskForConfirmation('alert & resume', ClientId);
  NtxAlertResumeThread(hxThread).RaiseOnError;
end;

procedure TUiLibThreads.cmCancelOClick(Sender: TObject);
var
  ClientId: TClientId;
  hxThread: IHandle;
begin
  ClientId := HighlightedClientId;
  NtxOpenThread(hxThread, ClientId.UniqueThread, THREAD_TERMINATE, 0,
    ClientId.UniqueProcess).RaiseOnError;
  AskForConfirmation('cancel synchronous I/O of',
    ClientId);
  NtxCancelSynchronousIoThread(hxThread).RaiseOnError;
end;

procedure TUiLibThreads.cmResumeClick;
var
  ClientId: TClientId;
  hxThread: IHandle;
begin
  ClientId := HighlightedClientId;
  NtxOpenThread(hxThread, ClientId.UniqueThread, THREAD_RESUME, 0,
    ClientId.UniqueProcess).RaiseOnError;
  AskForConfirmation('resume', ClientId);
  NtxResumeThread(hxThread).RaiseOnError;
end;

procedure TUiLibThreads.cmSuspendClick;
var
  ClientId: TClientId;
  hxThread: IHandle;
begin
  ClientId := HighlightedClientId;
  NtxOpenThread(hxThread, ClientId.UniqueThread, THREAD_SUSPEND_RESUME, 0,
    ClientId.UniqueProcess).RaiseOnError;
  AskForConfirmation('suspend', ClientId);
  NtxSuspendThread(hxThread).RaiseOnError;
end;

procedure TUiLibThreads.cmTerminateClick;
var
  ClientId: TClientId;
  hxThread: IHandle;
begin
  ClientId := HighlightedClientId;
  NtxOpenThread(hxThread, ClientId.UniqueThread, THREAD_TERMINATE, 0,
    ClientId.UniqueProcess).RaiseOnError;
  AskForConfirmation('terminate', ClientId);
  NtxTerminateThread(hxThread, STATUS_CANCELLED).RaiseOnError;
end;

procedure TUiLibThreads.ComboBoxMethodChange;
begin
  SnapshotMethod := TUiLibThreadSnapshotMethod(ComboBoxMethod.ItemIndex);
  SessionIdBox.Enabled := SnapshotMethod = tsSession;
  RefreshNoDiff;
end;

class function TUiLibThreads.Factory;
begin
  Result := function (AOwner: TComponent): TWinControl
    var
      ResultRef: TUiLibThreads absolute Result;
    begin
      try
        ResultRef := TUiLibThreads.Create(AOwner);
        ResultRef.ProcessId := ProcessId;
      except
        ResultRef.Free;
        raise;
      end;
    end;
end;

function TUiLibThreads.GetDefaultCaption;
begin
  Result := 'Threads of ' + Rttix.Format(FProcessId);
end;

function TUiLibThreads.GetModalResult;
begin
  Result := HighlightedClientId;
end;

function TUiLibThreads.GetModalResultType;
begin
  Result := TypeInfo(TClientId);
end;

function TUiLibThreads.HighlightedClientId;
begin
  Result := (Tree.HighlightedNode.Provider as IThreadNode).Thread.Basic.ClientID;
end;

procedure TUiLibThreads.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  HysteresisContainer := TUiLibHysteresisContainer<TNtxThreadEntry>.Initialize(
    Tree, TThreadNode, RtlxIsSameThread);
  HysteresisContainer.Core.TransitionTime := 1;
end;

procedure TUiLibThreads.PopupMenuPopup;
var
  HasHighlightedNode: Boolean;
begin
  HasHighlightedNode := Assigned(Tree.HighlightedNode);
  cmTerminate.Visible := HasHighlightedNode;
  cmSuspend.Visible := HasHighlightedNode;
  cmResume.Visible := HasHighlightedNode;
  cmAlert.Visible := HasHighlightedNode;
  cmAlertResume.Visible := HasHighlightedNode;
  cmCancelO.Visible := HasHighlightedNode;
end;

procedure TUiLibThreads.Refresh;
var
  Threads: TArray<TNtxThreadEntry>;
  ThreadType: TNtxObjectTypeInfo;
  Status: TNtxStatus;
  StartTime: TDateTime;
  DurationMillisec: Integer;
begin
  // Notify nodes we are starting an update sequence
  HysteresisContainer.PreUpdate;

  // Enumerate threads
  StartTime := Now;
  Status := Snapshot(Threads);
  DurationMillisec := Round((Now - StartTime) * 86400 * 1000);

  // Bruteforce method is not very fast. Detect if enumeration takes too long
  // and slow down the refresh rate accordingly to make UI resonsive.
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
    Threads := nil;
  end;

  // Give the snapshot to the hysteresis tree container which will compare it to
  // the previous state and issue necessary node transformation events
  HysteresisContainer.Update(Threads);
  SearchBox.ReapplySearch;

  // Refresh informational labels
  LabelCount.Caption := 'Displaying: ' + UiLibUIntToDec(Length(Threads));

  if RtlxFindKernelType('Thread', ThreadType, False).IsSuccess then
  begin
    LabelTotal.Caption := 'Total: ' + UiLibUIntToDec(
      ThreadType.Native.TotalNumberOfObjects);
    LabelPeak.Caption := 'Peak: ' + UiLibUIntToDec(
      ThreadType.Native.HighWaterNumberOfObjects);
  end
  else
  begin
    LabelTotal.Caption := 'Total: (unknown)';
    LabelPeak.Caption := 'Peak: (unknown)';
  end;
end;

procedure TUiLibThreads.RefreshNoDiff;
var
  TTL: Integer;
begin
  // Suppress transitions for one update
  TTL := HysteresisContainer.Core.TransitionTime;
  HysteresisContainer.Core.TransitionTime := 0;
  Refresh;
  HysteresisContainer.Core.TransitionTime := TTL;
end;

procedure TUiLibThreads.RefreshTimerTimer;
begin
  try
    Refresh;
  except
    // If something breaks, stop auto-refreshing to prevent spamming errors
    RefreshTimer.Enabled := False;
    raise;
  end;
end;

procedure TUiLibThreads.SessionIdBoxChange;
begin
  RefreshNoDiff;
end;

procedure TUiLibThreads.SetOnModalComplete;
begin
  FOnModalComplete := Event;
  Tree.OnMainAction := TreeMainAction;
  Tree.MainActionMenuText := 'Select';
end;

procedure TUiLibThreads.SetOnModalResultAvailabilityChange;
begin
  FOnModalResultAvailabilityChange := Event;
  TreeChange(nil, nil);
end;

function TUiLibThreads.Snapshot;
var
  Processes: TArray<TNtxProcessEntry>;
  Process: PNtxProcessEntry;
begin
  // Two method work directly with the process
  if SnapshotMethod in [tsGetNext, tsBruteforce] then
  begin
    case SnapshotMethod of
      tsGetNext:    Result := NtxEnumerateThreadsGetNext(FProcessId, Threads);
      tsBruteforce: Result := NtxEnumerateThreadsBruteforce(FProcessId, Threads);
    end;
    Exit;
  end;

  // Othre methods need to enumerate all processes first
  case SnapshotMethod of
    tsNormal:
      Result := NtxEnumerateProcesses(Processes);

    tsExtended:
      Result := NtxEnumerateProcessesEx(Processes);

    tsFull:
      Result := NtxEnumerateProcessesFull(Processes);

    tsSession:
      Result := NtxEnumerateProcessesSession(Processes, SessionIdBox.SessionID);
  else
    Result.Location := 'TUiLibThreads.Snapshot';
    Result.Status := STATUS_INVALID_PARAMETER;
  end;

  if not Result.IsSuccess then
    Exit;

  // Try to find our target process
  Process := RtlxFindProcessById(Processes, FProcessId);

  if Assigned(Process) then
    Threads := Process.Threads
  else
  begin
    Result.Location := 'Searching for process';
    Result.Status := STATUS_NOT_FOUND;
  end;
end;

procedure TUiLibThreads.TreeChange;
begin
  if Assigned(FOnModalResultAvailabilityChange) then
    FOnModalResultAvailabilityChange(Assigned(Tree.HighlightedNode));
end;

procedure TUiLibThreads.TreeMainAction;
begin
  if Assigned(FOnModalComplete) then
    FOnModalComplete(Self);
end;

{ TUiLibThreadModalCache }

class function TUiLibThreadModalCache.Factory;
begin
  Result := TUiLibThreadModalCache.Create;
end;

procedure TUiLibThreadModalCache.Save(const ModalResultImplementor: IInterface);
var
  ProcessModal: IModalResult<TProcessId>;
  Owner: TWinControl;
begin
  // This code is invoked at process's dialog modal completion; retrieve result
  ProcessModal := ModalResultImplementor as IModalResult<TProcessId>;
  VerifyGenericTypesMatch(TypeInfo(TProcessId), ProcessModal.ModalResultType);

  // Show a modal thread selection dialog relative to the selected process
  Owner := ModalResultImplementor as TWinControl;
  FModalResult := UiLibPickProcessThread(Owner, ProcessModal.ModalResult);

  // If the operation did not abort, mark it as complete
  FModalResultSet := True;
end;

initialization
  RttixRegisterClientIdFormatters;
  UiLibFactoryThread := TUiLibThreads.Factory;
  UiLibFactoryProcessToThread := TUiLibThreadModalCache.Factory;
end.
