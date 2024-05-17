unit UI.Prototypes.Sid.Edit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  NtUtils, NtUiFrame;

type
  TSidChoice = (
    scNone,
    scIntegrity,
    scTrust
  );

  TSidEditor = class(TBaseFrame)
    tbxSid: TEdit;
    btnDsPicker: TButton;
    btnCheatsheet: TButton;
    btnChoice: TButton;
    procedure btnCheatsheetClick(Sender: TObject);
    procedure btnDsPickerClick(Sender: TObject);
    procedure tbxSidChange(Sender: TObject);
    procedure tbxSidEnter(Sender: TObject);
    procedure btnChoiceClick(Sender: TObject);
  private
    FSuggestionsInitialized: Boolean;
    FOnSidChanged: TNotifyEvent;
    SidCache: ISid;
    FSidChoice: TSidChoice;
    function GetSid: ISid;
    procedure SetSid(const Sid: ISid);
    procedure DsPickerIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure CheatsheetIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure ChoiceIconChanged(ImageList: TImageList; ImageIndex: Integer);
    procedure SetSidChoice(const Value: TSidChoice);
  protected
    procedure LoadedOnce; override;
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
  NtUtils.Security.Sid, UI.Prototypes.Forms, Resources.Icon.Catalogue,
  Resources.Icon.UserPicker, Resources.Icon.Choose, NtUiCommon.Prototypes,
  NtUiFrame.Sids.Abbreviations;

{$R *.dfm}

{ TSidFrame }

procedure TSidEditor.btnCheatsheetClick;
begin
  tbxSid.SetFocus;
  NtUiLibHostFrameShow(
    function (AOwner: TComponent): TFrame
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
      if Assigned(NtUiLibSelectIntegrity) then
        Sid := NtUiLibSelectIntegrity(Self, Current);

    scTrust:
      if Assigned(NtUiLibSelectTrust) then
        Sid := NtUiLibSelectTrust(Self, Current);
  end;
end;

procedure TSidEditor.btnDsPickerClick;
begin
  tbxSid.SetFocus;
  tbxSid.Text := NtUiLibSelectDsObject(Handle);
end;

procedure TSidEditor.CheatsheetIconChanged;
begin
  btnCheatsheet.Images := ImageList;
  btnCheatsheet.ImageIndex := ImageIndex;
end;

procedure TSidEditor.ChoiceIconChanged;
begin
  btnChoice.Images := ImageList;
  btnChoice.ImageIndex := ImageIndex;
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
  RegisterResourceIcon(RESOURCES_ICON_USER_PICKER, DsPickerIconChanged);
  RegisterResourceIcon(RESOURCES_ICON_CATALOGUE, CheatsheetIconChanged);
  RegisterResourceIcon(RESOURCES_ICON_CHOOSE, ChoiceIconChanged);
  btnDsPicker.Visible := Assigned(NtUiLibSelectDsObject);
end;

procedure TSidEditor.SetSid;
begin
  tbxSid.OnChange := nil;
  Auto.Delay(
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
      btnChoice.Visible := Assigned(NtUiLibSelectIntegrity);
      btnChoice.Hint := 'Choose Integrity Level';
    end;

    scTrust:
    begin
      btnChoice.Visible := Assigned(NtUiLibSelectTrust);
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
  if FSuggestionsInitialized then
    Exit;

  FSuggestionsInitialized := True;
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
