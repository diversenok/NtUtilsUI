unit UI.Prototypes.Sid.Edit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  NtUtils, NtUiFrame;

type
  TSidEditor = class(TBaseFrame)
    tbxSid: TEdit;
    btnDsPicker: TButton;
    btnCheatsheet: TButton;
    procedure btnCheatsheetClick(Sender: TObject);
    procedure btnDsPickerClick(Sender: TObject);
    procedure tbxSidChange(Sender: TObject);
    procedure tbxSidEnter(Sender: TObject);
  private
    FInitialized: Boolean;
    FOnDsObjectPicked: TNotifyEvent;
    FOnSidChanged: TNotifyEvent;
    SidCache: ISid;
    function GetSid: ISid;
    procedure SetSid(const Sid: ISid);
    procedure DsPickerIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure CheatsheetIconChanged(ImageList: TImageList; ImageIndex: Integer);
  protected
    procedure LoadedOnce; override;
    procedure FrameEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    function TryGetSid(out Sid: ISid): TNtxStatus;
    property Sid: ISid read GetSid write SetSid;
  published
    property OnDsObjectPicked: TNotifyEvent read FOnDsObjectPicked write FOnDsObjectPicked;
    property OnSidChanged: TNotifyEvent read FOnSidChanged write FOnSidChanged;
  end;

implementation

uses
  Ntapi.ntstatus, NtUtils.Lsa.Sid, NtUiLib.AutoCompletion.Sid,
  UI.Builtin.DsObjectPicker, UI.Prototypes.Sid.Cheatsheet, UI.Prototypes.Forms;

{$R *.dfm}
{$R '..\Icons\SidEditor.res'}

{ TSidFrame }

procedure TSidEditor.btnCheatsheetClick;
begin
  tbxSid.SetFocus;
  TSidCheatsheet.CreateChild(Application, cfmDesktop).Show;
end;

procedure TSidEditor.btnDsPickerClick;
var
  AccountName: String;
begin
  tbxSid.SetFocus;

  with ComxCallDsObjectPicker(Handle, AccountName) do
    if IsHResult and (HResult = S_FALSE) then
      Abort
    else
      RaiseOnError;

  tbxSid.Text := AccountName;

  if Assigned(FOnDsObjectPicked) then
    FOnDsObjectPicked(Self);
end;

procedure TSidEditor.CheatsheetIconChanged;
begin
  btnCheatsheet.Images := ImageList;
  btnCheatsheet.ImageIndex := ImageIndex;
end;

procedure TSidEditor.DsPickerIconChanged;
begin
  btnDsPicker.Images := ImageList;
  btnDsPicker.ImageIndex := ImageIndex;
end;

procedure TSidEditor.FrameEnabledChanged;
begin
  inherited;
  tbxSid.Enabled := Enabled;
  btnCheatsheet.Enabled := Enabled;
  btnDsPicker.Enabled := Enabled;
end;

function TSidEditor.GetSid;
begin
  TryGetSid(Result).RaiseOnError;
end;

procedure TSidEditor.LoadedOnce;
begin
  inherited;
  RegisterResourceIcon('SidEditor.DsObjectPicker', DsPickerIconChanged);
  RegisterResourceIcon('SidEditor.Cheatsheet', CheatsheetIconChanged);
end;

procedure TSidEditor.SetSid;
begin
  tbxSid.OnChange := nil;
  try
    SidCache := Sid;

    if Assigned(Sid) then
      tbxSid.Text := LsaxSidToString(Sid)
    else
      tbxSid.Text := '';

    if Assigned(FOnSidChanged) then
      FOnSidChanged(Self);
  finally
    tbxSid.OnChange := tbxSidChange;
  end;
end;

procedure TSidEditor.tbxSidChange;
begin
  SidCache := nil;

  if Assigned(FOnSidChanged) then
    FOnSidChanged(Self);
end;

procedure TSidEditor.tbxSidEnter;
begin
  if FInitialized then
    Exit;

  FInitialized := True;
  ShlxEnableSidSuggestions(tbxSid.Handle);
end;

function TSidEditor.TryGetSid;
begin
  // Use cache when available
  if Assigned(SidCache) then
  begin
    Sid := SidCache;
    Result := Default(TNtxStatus);
    Exit;
  end;

  // Workaround empty lookups that give confusing results
  if (tbxSid.Text = '') or (tbxSid.Text = '\') then
  begin
    Result.Location := 'TSidEditor.TryGetSid';
    Result.Status := STATUS_NONE_MAPPED;
    Exit;
  end;

  Result := LsaxLookupNameOrSddl(tbxSid.Text, Sid);

  // Cache successful lookups
  if Result.IsSuccess then
    SidCache := Sid;
end;

end.
