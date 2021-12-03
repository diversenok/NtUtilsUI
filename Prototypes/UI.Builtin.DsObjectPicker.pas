unit UI.Builtin.DsObjectPicker;

{
  This module adds support for Directory Services Object Picker - the built-in
  dialog for selecting user accounts.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinUser, DelphiApi.Reflection, NtUtils;

// Show the dialog and retieve the selected account name
function ComxCallDsObjectPicker(
  ParentWindow: THwnd;
  out AccountName: String
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ObjBase, NtUtils.Com.Dispatch,
  DelphiUtils.AutoObjects;

const
  // SDK::wtypes.h
  DVASPECT_CONTENT = 1;
  DVASPECT_THUMBNAIL = 2;
  DVASPECT_ICON	= 4;
  DVASPECT_DOCPRINT	= 8;

  // SDK::objidl.h
  TYMED_HGLOBAL	= 1;
  TYMED_FILE = 2;
  TYMED_ISTREAM	= 4;
  TYMED_ISTORAGE= 8;
  TYMED_GDI	= 16;
  TYMED_MFPICT = 32;
  TYMED_ENHMF	= 64;
  TYMED_NULL = 0;

  // SDK::ObjSel.h, type of the scope
  DSOP_SCOPE_TYPE_TARGET_COMPUTER = $00000001;
  DSOP_SCOPE_TYPE_UPLEVEL_JOINED_DOMAIN = $00000002;
  DSOP_SCOPE_TYPE_DOWNLEVEL_JOINED_DOMAIN = $00000004;
  DSOP_SCOPE_TYPE_ENTERPRISE_DOMAIN = $00000008;
  DSOP_SCOPE_TYPE_GLOBAL_CATALOG = $00000010;
  DSOP_SCOPE_TYPE_EXTERNAL_UPLEVEL_DOMAIN = $00000020;
  DSOP_SCOPE_TYPE_EXTERNAL_DOWNLEVEL_DOMAIN = $00000040;
  DSOP_SCOPE_TYPE_WORKGROUP = $00000080;
  DSOP_SCOPE_TYPE_USER_ENTERED_UPLEVEL_SCOPE = $00000100;
  DSOP_SCOPE_TYPE_USER_ENTERED_DOWNLEVEL_SCOPE = $00000200;
  DSOP_SCOPE_TYPE_ANY = $000003FF;

  // SDK::ObjSel.h, scope flags
  DSOP_SCOPE_FLAG_STARTING_SCOPE = $00000001;
  DSOP_SCOPE_FLAG_WANT_PROVIDER_WINNT = $00000002;
  DSOP_SCOPE_FLAG_WANT_PROVIDER_LDAP = $00000004;
  DSOP_SCOPE_FLAG_WANT_PROVIDER_GC = $00000008;
  DSOP_SCOPE_FLAG_WANT_SID_PATH = $00000010;
  DSOP_SCOPE_FLAG_WANT_DOWNLEVEL_BUILTIN_PATH = $00000020;
  DSOP_SCOPE_FLAG_DEFAULT_FILTER_USERS = $00000040;
  DSOP_SCOPE_FLAG_DEFAULT_FILTER_GROUPS = $00000080;
  DSOP_SCOPE_FLAG_DEFAULT_FILTER_COMPUTERS = $00000100;
  DSOP_SCOPE_FLAG_DEFAULT_FILTER_CONTACTS = $00000200;
  DSOP_SCOPE_FLAG_DEFAULT_FILTER_SERVICE_ACCOUNTS = $00000400;
  DSOP_SCOPE_FLAG_DEFAULT_FILTER_PASSWORDSETTINGS_OBJECTS = $00000800;

  // SDK::ObjSel.h, uplevel filters
  DSOP_FILTER_INCLUDE_ADVANCED_VIEW = $00000001;
  DSOP_FILTER_USERS = $00000002;
  DSOP_FILTER_BUILTIN_GROUPS = $00000004;
  DSOP_FILTER_WELL_KNOWN_PRINCIPALS = $00000008;
  DSOP_FILTER_UNIVERSAL_GROUPS_DL = $00000010;
  DSOP_FILTER_UNIVERSAL_GROUPS_SE = $00000020;
  DSOP_FILTER_GLOBAL_GROUPS_DL = $00000040;
  DSOP_FILTER_GLOBAL_GROUPS_SE = $00000080;
  DSOP_FILTER_DOMAIN_LOCAL_GROUPS_DL = $00000100;
  DSOP_FILTER_DOMAIN_LOCAL_GROUPS_SE = $00000200;
  DSOP_FILTER_CONTACTS = $00000400;
  DSOP_FILTER_COMPUTERS = $00000800;
  DSOP_FILTER_SERVICE_ACCOUNTS = $00001000;
  DSOP_FILTER_PASSWORDSETTINGS_OBJECTS = $00002000;
  DSOP_FILTER_ALL = $3FFF;

  // SDK::ObjSel.h, downlevel filters
  DSOP_DOWNLEVEL_FILTER_USERS = $80000001;
  DSOP_DOWNLEVEL_FILTER_LOCAL_GROUPS = $80000002;
  DSOP_DOWNLEVEL_FILTER_GLOBAL_GROUPS = $80000004;
  DSOP_DOWNLEVEL_FILTER_COMPUTERS = $80000008;
  DSOP_DOWNLEVEL_FILTER_WORLD = $80000010;
  DSOP_DOWNLEVEL_FILTER_AUTHENTICATED_USER = $80000020;
  DSOP_DOWNLEVEL_FILTER_ANONYMOUS = $80000040;
  DSOP_DOWNLEVEL_FILTER_BATCH = $80000080;
  DSOP_DOWNLEVEL_FILTER_CREATOR_OWNER = $80000100;
  DSOP_DOWNLEVEL_FILTER_CREATOR_GROUP = $80000200;
  DSOP_DOWNLEVEL_FILTER_DIALUP = $80000400;
  DSOP_DOWNLEVEL_FILTER_INTERACTIVE = $80000800;
  DSOP_DOWNLEVEL_FILTER_NETWORK = $80001000;
  DSOP_DOWNLEVEL_FILTER_SERVICE = $80002000;
  DSOP_DOWNLEVEL_FILTER_SYSTEM = $80004000;
  DSOP_DOWNLEVEL_FILTER_EXCLUDE_BUILTIN_GROUPS = $80008000;
  DSOP_DOWNLEVEL_FILTER_TERMINAL_SERVER = $80010000;
  DSOP_DOWNLEVEL_FILTER_ALL_WELLKNOWN_SIDS = $80020000;
  DSOP_DOWNLEVEL_FILTER_LOCAL_SERVICE = $80040000;
  DSOP_DOWNLEVEL_FILTER_NETWORK_SERVICE = $80080000;
  DSOP_DOWNLEVEL_FILTER_REMOTE_LOGON = $80100000;
  DSOP_DOWNLEVEL_FILTER_INTERNET_USER = $80200000;
  DSOP_DOWNLEVEL_FILTER_OWNER_RIGHTS = $80400000;
  DSOP_DOWNLEVEL_FILTER_SERVICES = $80800000;
  DSOP_DOWNLEVEL_FILTER_LOCAL_LOGON = $81000000;
  DSOP_DOWNLEVEL_FILTER_THIS_ORG_CERT = $82000000;
  DSOP_DOWNLEVEL_FILTER_IIS_APP_POOL = $84000000;
  DSOP_DOWNLEVEL_FILTER_ALL_APP_PACKAGES = $88000000;
  DSOP_DOWNLEVEL_FILTER_LOCAL_ACCOUNTS = $90000000;
  DSOP_DOWNLEVEL_FILTER_ALL = $9FFF7FFF;

  // SDK::ObjSel.h, DS Object Picker flags
  DSOP_FLAG_MULTISELECT = $00000001;
  DSOP_FLAG_SKIP_TARGET_COMPUTER_DC_CHECK = $00000002;

  // SDK::ObjSel.h
  CLSID_DsObjectPicker: TGuid = '{17D6CCD8-3B7B-11D2-B9E0-00C04FD8DBF7}';
  IID_IDsObjectPicker: TGuid = '{0C87E64E-3B7A-11D2-B9E0-00C04FD8DBF7}';

  // SDK::ObjSel.h
  CFSTR_DSOP_DS_SELECTION_LIST = 'CFSTR_DSOP_DS_SELECTION_LIST';

type
  // SDK::minwindef.h
  THGlobal = type NativeUInt;

  // SDK::ole.h
  [SDKName('CLIPFORMAT')]
  TClipFormat = type Word;

  // SDK::wtypes.h
  [SDKName('DVASPECT')]
  TDvAspect = type Cardinal; // DVASPECT_*

  // SDK::objidl.h
  [SDKName('TYMED')]
  TTymed = type Cardinal; // TYMED_*

  // SDK::objidl.h
  [SDKName('FORMATETC')]
  TFormatEtc = record
    Format: TClipFormat;
    ptd: Pointer; // DVTARGETDEVICE
    Aspect: TDvAspect;
    Index: Int32;
    Tymed: TTymed;
  end;

  // SDK::objidl.h
  [SDKName('uSTGMEDIUM')]
  TStgMedium = record
    tymed: Longint;
  case Integer of
    0: (hBitmap: UIntPtr; unkForRelease: Pointer{IUnknown});
    1: (hMetaFilePict: THandle);
    2: (hEnhMetaFile: THandle);
    3: (hGlobal: HGlobal);
    4: (lpszFileName: PWideChar);
    5: (stm: Pointer{IStream});
    6: (stg: Pointer{IStorage});
  end;

  IEnumFormatEtc = IUnknown;
  IAdviseSink = IUnknown;
  IEnumStatData = IUnknown;

  // SDK::objidl.h
  IDataObject = interface(IUnknown)
    ['{0000010E-0000-0000-C000-000000000046}']
    function GetData(const formatetcIn: TFormatEtc; out medium: TStgMedium): HResult; stdcall;
    function GetDataHere(const formatetc: TFormatEtc; out medium: TStgMedium): HResult; stdcall;
    function QueryGetData(const formatetc: TFormatEtc): HResult; stdcall;
    function GetCanonicalFormatEtc(const formatetc: TFormatEtc; out formatetcOut: TFormatEtc): HResult; stdcall;
    function SetData(const formatetc: TFormatEtc; var medium: TStgMedium; fRelease: LongBool): HResult; stdcall;
    function EnumFormatEtc(dwDirection: Longint; out enumFormatEtc: IEnumFormatEtc): HResult; stdcall;
    function DAdvise(const formatetc: TFormatEtc; advf: Longint; const advSink: IAdviseSink; out dwConnection: Longint): HResult; stdcall;
    function DUnadvise(dwConnection: Longint): HResult; stdcall;
    function EnumDAdvise(out enumAdvise: IEnumStatData): HResult; stdcall;
  end;

  [Hex] TDsScopeTypes = type Cardinal;       // DSOP_SCOPE_TYPE_*
  [Hex] TDsScopeFlags = type Cardinal;       // DSOP_SCOPE_FLAG_*
  [Hex] TDsDownlevelFilters = type Cardinal; // DSOP_DOWNLEVEL_FILTER_*
  [Hex] TDsFilters = type Cardinal;          // DSOP_FILTER_*
  [Hex] TDsFlags = type Cardinal;            // DSOP_FLAG_*

  // SDK::ObjSel.h
  [SDKName('DSOP_UPLEVEL_FILTER_FLAGS')]
  TDsOpUpLevelFilterFlags = record
    BothModes: TDsFilters;
    MixedModeOnly: TDsFilters;
    NativeModeOnly: TDsFilters;
  end;

  // SDK::ObjSel.h
  [SDKName('DSOP_FILTER_FLAGS')]
  TDsOpFilterFlags = record
    Uplevel: TDsOpUpLevelFilterFlags;
    Downlevel: TDsDownlevelFilters;
  end;

  // SDK::ObjSel.h
  [SDKName('DSOP_SCOPE_INIT_INFO')]
  TDsOpScopeInitInfo = record
    Size: Cardinal;
    ScopeType: TDsScopeTypes;
    ScopeFlags: TDsScopeFlags;
    FilterFlags: TDsOpFilterFlags;
    [opt] DcName: PWideChar;
    [opt] ADsPath: PWideChar;
    Result: HResult;
  end;

  // SDK::ObjSel.h
  [SDKName('DSOP_INIT_INFO')]
  TDsOpInitInfo = record
    Size: Cardinal;
    [opt] TargetComputer: PWideChar;
    DsScopeInfosCount: Cardinal;
    DsScopeInfos: ^TAnysizeArray<TDsOpScopeInitInfo>;
    Options: TDsFlags;
    AttributesToFetch: Cardinal;
    AttributeNames: ^TAnysizeArray<PWideChar>;
  end;

  // SDK::ObjSel.h
  IDsObjectPicker = interface (IUnknown)
    ['{0C87E64E-3B7A-11D2-B9E0-00C04FD8DBF7}']

    function Initialize(
      const InitInfo: TDsOpInitInfo
    ): HResult; stdcall;

    function InvokeDialog(
      hwndParent: THwnd;
      out Selections: IDataObject
    ): HResult; stdcall;
  end;

  // SDK::ObjSel.h
  [SDKName('DS_SELECTION')]
  TDsSelection = record
    Name: PWideChar;
    ADsPath: PWideChar;
    ClassString: PWideChar;
    UPN: PWideChar;
    FetchedAttributes: POleVariant;
    ScopeType: Cardinal;
  end;

  // SDK::ObjSel.h
  [SDKName('DS_SELECTION_LIST')]
  TDsSelectionList = record
    Items: Integer;
    FetchedAttributes: Cardinal;
    DsSelection: TAnysizeArray<TDsSelection>;
  end;
  PDSSelectionList = ^TDsSelectionList;

// SDK::WinBase.h
function GlobalLock(
  hMem: THGlobal
): Pointer; stdcall; external kernel32;

// SDK::WinBase.h
function GlobalUnlock(
  hMem: THGlobal
): LongBool; stdcall; external kernel32;

// SDK::ole2.h
procedure ReleaseStgMedium(
  const Medium: TStgMedium
); stdcall; external ole32;

// SDK::WinUser.h
function RegisterClipboardFormatW(
  Format: PWideChar
): Cardinal; stdcall; external user32;

{ Custom functions }

function GlobalLockAuto(
  hMem: THGlobal;
  out Memory: Pointer;
  out Lock: IAutoReleasable
): TNtxStatus;
begin
  Result.Location := 'GlobalLock';
  Memory := GlobalLock(hMem);
  Result.Win32Result := Assigned(Memory);

  if Result.IsSuccess then
    Lock := Auto.Delay(
      procedure
      begin
        GlobalUnlock(hMem);
      end
    );
end;

function ReleaseStgMediumAuto(
  const Medium: TStgMedium
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      ReleaseStgMedium(Medium);
    end
  );
end;

function ComxCallDsObjectPicker;
var
  ComInit: IAutoReleasable;
  Picker: IDsObjectPicker;
  InitInfo: TDsOpInitInfo;
  ScopeInfo: TDsOpScopeInitInfo;
  DatObj: IDataObject;
  FormatEtc: TFormatEtc;
  Medium: TStgMedium;
  SelList: PDSSelectionList;
  Lock: IAutoReleasable;
begin
  Result := ComxInitialize(ComInit, COINIT_APARTMENTTHREADED);

  if not Result.IsSuccess then
    Exit;

  Result := ComxCreateInstance(CLSID_DsObjectPicker, IID_IDsObjectPicker,
    Picker, CLSCTX_INPROC_SERVER);

  if not Result.IsSuccess then
    Exit;

  // Configure the dialog to show as much as possible
  ScopeInfo := Default(TDsOpScopeInitInfo);
  ScopeInfo.Size := SizeOf(ScopeInfo);
  ScopeInfo.ScopeType := DSOP_SCOPE_TYPE_ANY;
  ScopeInfo.ScopeFlags := DSOP_SCOPE_FLAG_STARTING_SCOPE or
    DSOP_SCOPE_FLAG_DEFAULT_FILTER_USERS or
    DSOP_SCOPE_FLAG_DEFAULT_FILTER_GROUPS or
    DSOP_SCOPE_FLAG_DEFAULT_FILTER_COMPUTERS;
  ScopeInfo.FilterFlags.Uplevel.BothModes := DSOP_FILTER_ALL;
  ScopeInfo.FilterFlags.Downlevel := DSOP_DOWNLEVEL_FILTER_ALL;

  InitInfo := Default(TDsOpInitInfo);
  InitInfo.Size := SizeOf(InitInfo);
  InitInfo.DsScopeInfosCount := 1;
  InitInfo.DsScopeInfos := Pointer(@ScopeInfo);
  InitInfo.Options := DSOP_FLAG_SKIP_TARGET_COMPUTER_DC_CHECK;

  Result.Location := 'IDsObjectPicker::Initialize';
  Result.HResult := Picker.Initialize(InitInfo);

  if not Result.IsSuccess then
    Exit;

  // Show the dialog
  Result.Location := 'IDsObjectPicker::InvokeDialog';
  Result.HResultAllowFalse := Picker.InvokeDialog(ParentWindow, DatObj);

  if not Result.IsSuccess or (Result.HResult = S_FALSE) then
    Exit;

  // Prepare for retrieving the content
  Result.Location := 'RegisterClipboardFormatW';
  FormatEtc.Format := RegisterClipboardFormatW(CFSTR_DSOP_DS_SELECTION_LIST);
  Result.Win32Result := FormatEtc.Format <> 0;

  if not Result.IsSuccess then
    Exit;

  FormatEtc.ptd := nil;
  FormatEtc.Aspect := DVASPECT_CONTENT;
  FormatEtc.Index := -1;
  FormatEtc.Tymed := TYMED_HGLOBAL;

  Result.Location := 'IDataObject::GetData';
  Result.HResult := DatObj.GetData(FormatEtc, Medium);

  if not Result.IsSuccess then
    Exit;

  ReleaseStgMediumAuto(Medium);
  Result := GlobalLockAuto(Medium.hGlobal, Pointer(SelList), Lock);

  if not Result.IsSuccess then
    Exit;

  if SelList.Items = 0 then
  begin
    Result.Location := 'ComxCallDsObjectPicker';
    Result.Status := STATUS_CANCELLED;
    Exit;
  end;

  AccountName := String(SelList.DsSelection[0].Name);
end;

end.
