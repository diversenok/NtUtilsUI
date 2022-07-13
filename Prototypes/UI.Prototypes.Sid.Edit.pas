unit UI.Prototypes.Sid.Edit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  VCL.ImgList, NtUtils;

type
  TSidEditor = class(TFrame)
    tbxSid: TEdit;
    btnDsPicker: TButton;
    btnCheatsheet: TButton;
    procedure btnCheatsheetClick(Sender: TObject);
    procedure btnDsPickerClick(Sender: TObject);
    procedure tbxSidChange(Sender: TObject);
  private
    FInitialized: Boolean;
    FImages: TImageList;
    FOnDsObjectPicked: TNotifyEvent;
    FOnSidChanged: TNotifyEvent;
    SidCache: ISid;
    function GetSid: ISid;
    procedure SetSid(const Sid: ISid);
  protected
    procedure Loaded; override;
  public
    function TryGetSid(out Sid: ISid): TNtxStatus;
    property Sid: ISid read GetSid write SetSid;
  published
    property OnDsObjectPicked: TNotifyEvent read FOnDsObjectPicked write FOnDsObjectPicked;
    property OnSidChanged: TNotifyEvent read FOnSidChanged write FOnSidChanged;
  end;

implementation

uses
  DelphiUtils.AutoObjects, NtUtils.Lsa.Sid, NtUiLib.Errors,
  NtUiLib.AutoCompletion.Sid, UI.Builtin.DsObjectPicker,
  UI.Prototypes.Sid.Cheatsheet, UI.Prototypes.Forms;

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

function TSidEditor.GetSid;
begin
  TryGetSid(Result).RaiseOnError;
end;

procedure TSidEditor.Loaded;
var
  Icon: TIcon;
begin
  inherited;

  if FInitialized then
    Exit;

  FInitialized := True;
  ShlxEnableSidSuggestions(tbxSid.Handle);

  // Add icons to the buttons
  FImages := TImageList.Create(Self);
  FImages.ColorDepth := cd32Bit;
  FImages.Width := 16 * CurrentPPI div 96;
  FImages.Height := 16 * CurrentPPI div 96;
  btnDsPicker.Images := FImages;
  btnCheatsheet.Images := FImages;

  try
    Icon := Auto.From(TIcon.Create).Self;
    Icon.LoadFromResourceName(HInstance, 'SidEditor.DsObjectPicker');
    btnDsPicker.ImageIndex := FImages.AddIcon(Icon);

    Icon := Auto.From(TIcon.Create).Self;
    Icon.LoadFromResourceName(HInstance, 'SidEditor.Cheatsheet');
    btnCheatsheet.ImageIndex := FImages.AddIcon(Icon);
  except
    ; // Missing icons should not prevent loading
  end;
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

function TSidEditor.TryGetSid;
begin
  if Assigned(SidCache) then
  begin
    // Use cached version
    Sid := SidCache;
    Result := Default(TNtxStatus);
  end
  else
  begin
    Result := LsaxLookupNameOrSddl(tbxSid.Text, Sid);

    // Cache successful lookups
    if Result.IsSuccess then
      SidCache := Sid;
  end;
end;

end.
