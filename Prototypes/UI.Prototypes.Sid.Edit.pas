unit UI.Prototypes.Sid.Edit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  VCL.ImgList;

type
  TSidEditor = class(TFrame)
    tbxSid: TEdit;
    btnDsPicker: TButton;
    btnCheatsheet: TButton;
    procedure btnCheatsheetClick(Sender: TObject);
    procedure btnDsPickerClick(Sender: TObject);
    procedure tbxSidChange(Sender: TObject);
  private
    FImages: TImageList;
    FOnDsObjectPicked: TNotifyEvent;
    FOnSidChanged: TNotifyEvent;
  protected
    procedure Loaded; override;
  published
    property OnDsObjectPicked: TNotifyEvent read FOnDsObjectPicked write FOnDsObjectPicked;
    property OnSidChanged: TNotifyEvent read FOnSidChanged write FOnSidChanged;
  end;

implementation

uses
  DelphiUtils.AutoObjects, NtUiLib.Errors, NtUiLib.AutoCompletion.Sid,
  UI.Builtin.DsObjectPicker, UI.Prototypes.Sid.Cheatsheet, UI.Prototypes.Forms;

{$R *.dfm}
{$R '..\Icons\DsObjectPicker.res'}
{$R '..\Icons\SidCheatsheet.res'}

{ TSidFrame }

procedure TSidEditor.btnCheatsheetClick;
begin
  tbxSid.SetFocus;
  TSidCheatsheet.CreateChild(Self, cfmDesktop).Show;
end;

procedure TSidEditor.btnDsPickerClick;
var
  AccountName: String;
begin
  with ComxCallDsObjectPicker(Handle, AccountName) do
    if IsHResult and (HResult = S_FALSE) then
      Abort
    else
      RaiseOnError;

  tbxSid.Text := AccountName;
  tbxSid.SetFocus;

  if Assigned(FOnDsObjectPicked) then
    FOnDsObjectPicked(Self);
end;

procedure TSidEditor.Loaded;
var
  Icon: TIcon;
begin
  inherited;

  // Enable SID suggestions
  ShlxEnableSidSuggestions(tbxSid.Handle);

  // Add icons to the buttons
  FImages := TImageList.Create(Self);
  FImages.ColorDepth := cd32Bit;
  FImages.Width := 16 * CurrentPPI div 96;
  FImages.Height := 16 * CurrentPPI div 96;
  btnDsPicker.Images := FImages;
  btnCheatsheet.Images := FImages;

  try
    Icon := Auto.From(TIcon.Create).Data;
    Icon.LoadFromResourceName(HInstance, 'DsObjectPicker');
    btnDsPicker.ImageIndex := FImages.AddIcon(Icon);
  except
    ; // Missing icons should not prevent loading
  end;

  try
    Icon := Auto.From(TIcon.Create).Data;
    Icon.LoadFromResourceName(HInstance, 'SidCheatsheet');
    btnCheatsheet.ImageIndex := FImages.AddIcon(Icon);
  except
    ;
  end;
end;

procedure TSidEditor.tbxSidChange;
begin
  if Assigned(FOnSidChanged) then
    FOnSidChanged(Self);
end;

end.
