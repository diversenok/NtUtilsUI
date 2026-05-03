unit UI.Prototypes.Sid.Edit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  NtUtils, NtUiLib.AutoCompletion, NtUtilsUI.StdCtrls;

type
  TSidChoice = (
    scNone,
    scIntegrity,
    scTrust
  );

  TSidEditor = class(TFrame)
    tbxSid: TUiLibEdit;
    btnDsPicker: TUiLibButton;
    btnCheatsheet: TUiLibButton;
    btnChoice: TUiLibButton;
    procedure btnCheatsheetClick(Sender: TObject);
    procedure btnDsPickerClick(Sender: TObject);
    procedure tbxSidChange(Sender: TObject);
    procedure tbxSidEnter(Sender: TObject);
    procedure btnChoiceClick(Sender: TObject);
  private
    FSuggestions: IAutoCompletionSuggestions;
    FOnSidChanged: TNotifyEvent;
    SidCache: ISid;
    FSidChoice: TSidChoice;
    function GetSid: ISid;
    procedure SetSid(const Sid: ISid);
    procedure SetSidChoice(const Value: TSidChoice);
  protected
    procedure CreateWnd; override;
    procedure FrameEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    function TryGetSid(out Sid: ISid): TNtxStatus;
    property Sid: ISid read GetSid write SetSid;
  published
    property OnSidChanged: TNotifyEvent read FOnSidChanged write FOnSidChanged;
    property SidChoice: TSidChoice read FSidChoice write SetSidChoice;
  end;

implementation

uses
  Ntapi.ntstatus, Ntapi.WinNt, NtUtils.Lsa.Sid, NtUiLib.AutoCompletion.Sid,
  NtUtils.Security.Sid, Resources.Icon.Catalogue, Resources.Icon.UserPicker,
  Resources.Icon.Choose, NtUiCommon.Prototypes, NtUiFrame.Sids.Abbreviations,
  NtUtilsUI, NtUtilsUI.Components, NtUtilsUI.Components.Factories;

{$R *.dfm}

{ TSidFrame }

procedure TSidEditor.btnCheatsheetClick;
begin
  if tbxSid.CanFocus then
    tbxSid.SetFocus;

  UiLibHost.Show(
    function (AOwner: TComponent): TWinControl
    begin
      Result := TSidAbbreviationFrame.Create(AOwner);
    end
  );
end;

procedure TSidEditor.btnChoiceClick;
var
  Current: ISid;
begin
  if not TryGetSid(Current).IsSuccess then
    Current := nil;

  case FSidChoice of
    scIntegrity:
      Sid := UiLibPickIntegritySid(Self, Current);

    scTrust:
      Sid := UiLibPickTrustSid(Self, Current);
  end;
end;

procedure TSidEditor.btnDsPickerClick;
begin
  if tbxSid.CanFocus then
    tbxSid.SetFocus;

  tbxSid.Text := NtUiLibSelectDsObject(Handle);
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

procedure TSidEditor.CreateWnd;
begin
  inherited;
  btnDsPicker.Visible := Assigned(NtUiLibSelectDsObject);
end;

procedure TSidEditor.SetSid;
var
  OnCheckedReverter: IDeferredOperation;
begin
  tbxSid.OnChange := nil;
  OnCheckedReverter := Auto.Defer(
    procedure
    begin
      tbxSid.OnChange := tbxSidChange;
    end
  );

  SidCache := Sid;

  if Assigned(Sid) then
    tbxSid.Text := LsaxSidToString(Sid)
  else
    tbxSid.Text := '';

  if Assigned(FOnSidChanged) then
    FOnSidChanged(Self);
end;

procedure TSidEditor.SetSidChoice;
begin
  FSidChoice := Value;

  case Value of
    scIntegrity:
    begin
      btnChoice.Visible := Assigned(UiLibFactoryIntegritySid);
      btnChoice.Hint := 'Choose Integrity Level';
    end;

    scTrust:
    begin
      btnChoice.Visible := Assigned(UiLibFactoryTrustSid);
      btnChoice.Hint := 'Choose Trust Level';
    end;
  else
    btnChoice.Visible := False;
    btnChoice.Hint := '';
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
  if not Assigned(FSuggestions) then
  begin
    FSuggestions := ShlxPrepareeSidSuggestions;
    ShlxEnableSuggestions(tbxSid.Handle, FSuggestions);
  end;
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
