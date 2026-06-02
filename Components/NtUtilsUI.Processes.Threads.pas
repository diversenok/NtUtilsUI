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
  Vcl.ExtCtrls, NtUtils, Ntapi.ntdef, Ntapi.WinNt, NtUtilsUI;

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
    procedure ComboBoxMethodChange(Sender: TObject);
    procedure RefreshTimerTimer(Sender: TObject);
    procedure SessionIdBoxChange(Sender: TObject);
    procedure TreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeMainAction(Node: INodeProvider);
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
  protected
    procedure Loaded; override;
  public
    property ProcessId: TProcessId read FProcessId write FProcessId;
    class function Factory(ProcessId: TProcessId): TWinControlFactory; static;
  end;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntstatus, NtUtils.Threads, NtUtils.Objects,
  NtUtils.Objects.Snapshots, NtUiLib.Errors, DelphiUiLib.LiteReflection,
  DelphiUiLib.LiteReflection.Types, DelphiUiLib.HysteresisTree,
  DelphiUiLib.Strings, NtUtilsUI.Components, NtUtilsUI.Components.Factories;

{$R *.dfm}

const
  colName = 0;
  colTid = 1;
  colTidHex = 2;
  colCreateTime = 3;
  colMax = 4;

type
  IThreadNode = interface (IHysteresisNodeProvider<TNtxThreadEntry>)
    ['{D0A97EED-DB91-49E4-8709-82F0A6FFC936}']
    function GetThread: PNtxThreadEntry;
    property Thread: PNtxThreadEntry read GetThread;
  end;

  TThreadNode = class (THysteresisNodeProvider<TNtxThreadEntry>, IThreadNode)
  private
    hxThread: IHandle;
    FHandleCached, FNameCached, FCreationTimeCached: Boolean;
    function GetThread: PNtxThreadEntry;
    procedure EnsureHandleCached;
    procedure EnsureNameCached;
    procedure EnsureTimesCached;
  protected
    procedure PreUpdate; override;
    procedure PostUpdate; override;
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
  if FCreationTimeCached then
    Exit;

  FNameCached := True;
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

procedure TThreadNode.EnsureHandleCached;
begin
  if FHandleCached then
    Exit;

  FHandleCached := True;

  if Assigned(Thread.hxThread) then
  begin
    hxThread := Thread.hxThread;
    Thread.hxThread := nil;
  end
  else if not Assigned(hxThread) then
    NtxOpenThread(hxThread, Thread.Basic.ClientID.UniqueThread,
     THREAD_QUERY_LIMITED_INFORMATION, 0, Thread.Basic.ClientID.UniqueProcess);
end;

procedure TThreadNode.EnsureNameCached;
begin
  if FNameCached then
    Exit;

  FNameCached := True;
  EnsureHandleCached;

  if Assigned(hxThread) then
    NtxQueryNameThread(hxThread, FColumnText[colName])
  else
    FColumnText[colName] := '';
end;

function TThreadNode.GetColor;
begin
  if HysteresisNode.TransitionState <> hntNormal then
  begin
    Result := inherited;
    Exit;
  end;

  Result := False;
end;

function TThreadNode.GetColumnText;
begin
  case Column of
    colName:       EnsureNameCached;
    colCreateTime: EnsureTimesCached;
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
begin
  FHandleCached := False;
  FNameCached := False;
  FCreationTimeCached := False;
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
  else
    Result := False;
end;

{ TUiLibThreads }

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
  Result := (Tree.HighlightedNode.Provider as IThreadNode).Thread.Basic.ClientID;
end;

function TUiLibThreads.GetModalResultType;
begin
  Result := TypeInfo(TClientId);
end;

procedure TUiLibThreads.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  HysteresisContainer := TUiLibHysteresisContainer<TNtxThreadEntry>.Initialize(
    Tree, TThreadNode, RtlxIsSameThread);
  HysteresisContainer.Core.TransitionTime := 1;
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
