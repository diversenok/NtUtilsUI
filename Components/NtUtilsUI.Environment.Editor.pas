unit NtUtilsUI.Environment.Editor;

{
  This module provides a frame for editing or creating an environment variable.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  NtUtilsUI.StdCtrls, NtUtilsUI.Base, NtUtilsUI.Components.Factories,
  NtUtils.Environment;

type
  [DefaultCaption('Environment variable')]
  TUiLibEnvVarEditor = class (TFrame, IModalResult<TRtlxEnvVariable>,
    IModalResultControl)
    lblName: TLabel;
    lblValue: TLabel;
    tbxName: TUiLibEdit;
    tbxValue: TUiLibMemo;
    lblPathMode: TLabel;
    procedure tbxNameChange(Sender: TObject);
  private
    FOnModalAvailability: TOnModalResultAvailabilityChange;
    function GetModalResult: TRtlxEnvVariable;
    function GetModalResultType: Pointer;
    procedure SetOnModalResultAvailabilityChange(Event: TOnModalResultAvailabilityChange);
    procedure SetOnModalComplete(Event: TNotifyEvent);
    procedure SetTemplate(const Template: TRtlxEnvVariable);
  public
    class function FactoryNew: TWinControlFactory; static;
    class function FactoryEdit(const Variable: TRtlxEnvVariable): TWinControlFactory; static;
  end;

implementation

uses
  NtUtils.SysUtils;

{$R *.dfm}

class function TUiLibEnvVarEditor.FactoryEdit;
begin
  Result := function (AOwner: TComponent): TWinControl
    begin
      Result := TUiLibEnvVarEditor.Create(AOwner);
      TUiLibEnvVarEditor(Result).SetTemplate(Variable);
    end;
end;

class function TUiLibEnvVarEditor.FactoryNew;
begin
  Result := function (AOwner: TComponent): TWinControl
    begin
      Result := TUiLibEnvVarEditor.Create(AOwner);
    end;
end;

function TUiLibEnvVarEditor.GetModalResult;
begin
  Result.Name := tbxName.Text;

  if lblPathMode.Visible then
  begin
    Result.Value := String.Join(';', tbxValue.Lines.ToStringArray);

    if (Length(Result.Value) > 0) and
      (Result.Value[High(Result.Value)] <> ';') then
      Result.Value := Result.Value + ';';
  end
  else
    Result.Value := tbxValue.Text;
end;

function TUiLibEnvVarEditor.GetModalResultType;
begin
  Result := TypeInfo(TRtlxEnvVariable);
end;

procedure TUiLibEnvVarEditor.SetOnModalComplete;
begin
  ;
end;

procedure TUiLibEnvVarEditor.SetOnModalResultAvailabilityChange;
begin
  FOnModalAvailability := Event;
  tbxNameChange(Self);
end;

procedure TUiLibEnvVarEditor.SetTemplate;
begin
  tbxName.Text := Template.Name;
  tbxName.ReadOnly := True;
  tbxName.Color := clBtnFace;

  if lblPathMode.Visible then
    tbxValue.Text := Template.Value.Replace(';', #$D#$A)
  else
    tbxValue.Text := Template.Value;
end;

procedure TUiLibEnvVarEditor.tbxNameChange;
begin
  lblPathMode.Visible := RtlxEqualStrings(tbxName.Text, 'Path');

  if Assigned(FOnModalAvailability) then
    FOnModalAvailability(tbxName.Text <> '');
end;

initialization
  UiLibFactoryEnvVariableNew := TUiLibEnvVarEditor.FactoryNew;
  UiLibFactoryEnvVariableEdit := TUiLibEnvVarEditor.FactoryEdit;
end.
