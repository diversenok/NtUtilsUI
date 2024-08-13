unit NtUiFrame.Ace.Condition;

{
  This module includes a control for selecting callback ACE conditions.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, NtUtils,
  NtUiFrame;

type
  TAceConditionFrame = class(TBaseFrame)
    tbxCondition: TEdit;
    btnNormalize: TButton;
    procedure tbxConditionChange(Sender: TObject);
    procedure btnNormalizeClick(Sender: TObject);
  private
    FOnConditionChanged: TNotifyEvent;
    FCondition: IMemory;
    function GetCondition: IMemory;
    procedure SetCondition(const Value: IMemory);
    procedure NormalizeIconChanged(ImageList: TImageList; ImageIndex: Integer);
  protected
    procedure LoadedOnce; override;
    procedure FrameEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    function TryGetCondition([MayReturnNil] out Value: IMemory): TNtxStatus;
    function TrySetCondition([opt] const Value: IMemory): TNtxStatus;
    [MayReturnNil] property Condition: IMemory read GetCondition write SetCondition;
    property OnConditionChange: TNotifyEvent read FOnConditionChanged write FOnConditionChanged;
  end;

implementation

uses
  UI.Colors, NtUtils.Security, Vcl.ImgList, Resources.Icon.Verify;

{$R *.dfm}

procedure TAceConditionFrame.btnNormalizeClick;
begin
  // Do a round trip of parsing and representing
  SetCondition(GetCondition);
end;

procedure TAceConditionFrame.FrameEnabledChanged;
begin
  inherited;
  tbxCondition.Enabled := Enabled;
  btnNormalize.Enabled := Enabled;
end;

function TAceConditionFrame.GetCondition;
begin
  TryGetCondition(Result).RaiseOnError;
end;

procedure TAceConditionFrame.LoadedOnce;
begin
  inherited;
  RegisterResourceIcon(RESOURCES_ICON_VERIFY, NormalizeIconChanged);
end;

procedure TAceConditionFrame.NormalizeIconChanged;
begin
  btnNormalize.Images := ImageList;
  btnNormalize.ImageIndex := ImageIndex;
end;

procedure TAceConditionFrame.SetCondition;
begin
  TrySetCondition(Value).RaiseOnError;
end;

procedure TAceConditionFrame.tbxConditionChange;
begin
  // Refresh the cached condition
  FCondition := nil;
  TryGetCondition(FCondition);

  if Assigned(FOnConditionChanged) then
    FOnConditionChanged(Self);
end;

function TAceConditionFrame.TryGetCondition;
begin
  // Use the cache when available
  if Assigned(FCondition) then
  begin
    Value := FCondition;
    Exit(NtxSuccess);
  end;

  // Parse the condition and cache the result
  Result := AdvxAceConditionFromSddl(tbxCondition.Text, FCondition);

  if Result.IsSuccess then
  begin
    Value := FCondition;
    tbxCondition.Color := clWindow;
  end
  else
  begin
    FCondition := nil;
    tbxCondition.Color := ColorSettings.clBackgroundError;
  end;
end;

function TAceConditionFrame.TrySetCondition;
var
  SDDL: String;
begin
  FCondition := nil;
  SDDL := '';

  if Assigned(Value) then
  begin
    // Convert the condition to string
    Result := AdvxAceConditionToSddl(Value, SDDL);

    if Result.IsSuccess then
      FCondition := Value;
  end
  else
    Result := NtxSuccess;

  // Suppress recursive invocation
  tbxCondition.OnChange := nil;
  Auto.Delay(
    procedure
    begin
      tbxCondition.OnChange := tbxConditionChange;
    end
  );

  // Update the text
  tbxCondition.Text := SDDL;
  tbxCondition.Color := clWindow;
end;

end.
