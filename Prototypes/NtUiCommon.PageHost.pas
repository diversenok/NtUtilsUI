unit NtUiCommon.PageHost;

{
  This module provides a component for hosting frames in a page control.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  NtUiCommon.Prototypes, NtUiCommon.Interfaces, System.Actions, Vcl.ActnList;

type
  TFramePages = class(TFrame, ICanConsumeEscape, IHasDefaultCaption)
    PageControl: TPageControl;
    ActionList: TActionList;
    procedure PageControlChange(Sender: TObject);
  private
    FTabs: TArray<TTabSheet>;
    FFrames: TArray<TFrame>;
    FActions: TArray<TAction>;
    FDelayLoaded: TArray<Boolean>;
    FDefaultCaption: String;
    function ConsumesEscape: Boolean;
    procedure SwitchToTabAction(Sender: TObject);
    function GetDefaultCaption: String;
    procedure NotifyDelayedLoading(Index: Integer);
  protected
    procedure FrameEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    procedure LoadPages(
      const Frames: TArray<TFrameInitializer>;
      const DefaultCaption: String
    );
  end;

implementation

uses
  NtUtils.Errors;

{$R *.dfm}

{ TFramePages }

function TFramePages.ConsumesEscape;
var
  ForwardedImpl: ICanConsumeEscape;
  i: Integer;
begin
  i := PageControl.ActivePageIndex;

  // Forward the request to the frame from the active page
  Result := (i >= 0) and (i <= High(FFrames)) and
    IUnknown(FFrames[i]).QueryInterface(ICanConsumeEscape,
    ForwardedImpl).IsSuccess and ForwardedImpl.ConsumesEscape;
end;

procedure TFramePages.FrameEnabledChanged;
begin
  inherited;
  // Notify the visible page about activation/disactivation
  PageControlChange(Self);
end;

function TFramePages.GetDefaultCaption;
begin
  Result := FDefaultCaption;
end;

procedure TFramePages.LoadPages;
var
  i: Integer;
  CaptionImpl: IHasDefaultCaption;
  RequiredWidth, RequiredHeight: Integer;
begin
  // Instantiate frames
  SetLength(FFrames, Length(Frames));

  RequiredWidth := 0;
  RequiredHeight := 0;

  for i := 0 to High(Frames) do
  begin
    FFrames[i] := Frames[i](Self);
    FFrames[i].Name := FFrames[i].Name + IntToStr(i);

    // Select the default page dimensions
    if FFrames[i].Width > RequiredWidth then
      RequiredWidth := FFrames[i].Width;

    if FFrames[i].Height > RequiredHeight then
      RequiredHeight := FFrames[i].Height;
  end;

  SetLength(FTabs, Length(Frames));
  SetLength(FActions, Length(Frames));
  SetLength(FDelayLoaded, Length(Frames));

  for i := 0 to High(Frames) do
  begin
    // Make a new page
    FTabs[i] := TTabSheet.Create(PageControl);
    FTabs[i].PageControl := PageControl;

    if i = 0 then
    begin
      // Resize to the dimensions of the biggest page
      Width := RequiredWidth + Width - FTabs[i].Width;
      Height := RequiredHeight + Height - FTabs[i].Height;
    end;

    // Adjust page caption
    if IUnknown(FFrames[i]).QueryInterface(IHasDefaultCaption,
      CaptionImpl).IsSuccess then
      FTabs[i].Caption := CaptionImpl.GetDefaultCaption
    else
      FTabs[i].Caption := FFrames[i].ClassName;

    // Attach the frame
    FFrames[i].Parent := FTabs[i];
    FFrames[i].Align := alClient;
    FDelayLoaded[i] := False;

    if i < 9 then
    begin
      // Handle page switching on Ctrl+<number>
      FActions[i] := TAction.Create(ActionList);
      FActions[i].ShortCut := scCtrl or (Ord('1') + i);
      FActions[i].Tag := i;
      FActions[i].OnExecute := SwitchToTabAction;
      FActions[i].ActionList := ActionList;
    end;
  end;

  FDefaultCaption := DefaultCaption;
  NotifyDelayedLoading(0);
end;

procedure TFramePages.NotifyDelayedLoading;
var
  DelayedLoader: IDelayedLoad;
begin
  // Invoke the delayed loading callback on the frame
  if (Index >= 0) and (Index <= High(FFrames)) and not FDelayLoaded[Index] then
  begin
    if IUnknown(FFrames[Index]).QueryInterface(IDelayedLoad,
      DelayedLoader).IsSuccess then
      DelayedLoader.DelayedLoad;

    FDelayLoaded[Index] := True;
  end;
end;

procedure TFramePages.PageControlChange;
var
  Observer: IObservesActivation;
  i: Integer;
begin
  // Adjust active state for all frames to allow handling conflicting shortcuts
  for i := 0 to High(FFrames) do
    if IUnknown(FFrames[i]).QueryInterface(IObservesActivation,
      Observer).IsSuccess then
      Observer.SetActive((i = PageControl.ActivePageIndex) and Enabled);

  // Initiate delayed loading for the newly visible frame
  NotifyDelayedLoading(PageControl.ActivePageIndex);
end;

procedure TFramePages.SwitchToTabAction;
begin
  if Sender is TAction then
  begin
    PageControl.ActivePageIndex := Word(TAction(Sender).Tag);
    PageControlChange(Sender);
  end;
end;

{ Integration }

function NtUiLibHostPages(
  AOwner: TComponent;
  Pages: TArray<TFrameInitializer>;
  const DefaultCaption: String
): TFrame;
var
  Frame: TFramePages absolute Result;
begin
  Frame := TFramePages.Create(AOwner);
  try
    Frame.LoadPages(Pages, DefaultCaption);
  except
    Frame.Free;
    raise;
  end;
end;

initialization
  NtUiCommon.Prototypes.NtUiLibHostPages := NtUiLibHostPages;
end.
