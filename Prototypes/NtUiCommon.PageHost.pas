unit NtUiCommon.PageHost;

{
  This module provides a component for hosting frames in a page control.
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  NtUiCommon.Prototypes, NtUiCommon.Interfaces, NtUtilsUI;

type
  TFramePages = class(TFrame, IDefaultCaption)
    PageControl: TPageControl;
    procedure PageControlChange(Sender: TObject);
  private
    FTabs: TArray<TTabSheet>;
    FFrames: TArray<TWinControl>;
    FShortCuts: TArray<TUiLibShortCut>;
    FDelayLoaded: TArray<Boolean>;
    FDefaultCaption: String;
    procedure OnTabShortCut(Sender: TUiLibShortCut; var Handled: Boolean);
    function GetDefaultCaption: String;
    procedure NotifyDelayedLoading(Index: Integer);
  protected
    procedure FrameEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    procedure LoadPages(
      const Frames: TArray<TWinControlFactory>;
      const DefaultCaption: String
    );
  end;

implementation

uses
  NtUtils.Errors;

{$R *.dfm}

{ TFramePages }

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
  SetLength(FShortCuts, Length(Frames));
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
    FTabs[i].Caption := QueryDefaultCaption(FFrames[i]);

    // Attach the frame
    FFrames[i].Parent := FTabs[i];
    FFrames[i].Align := alClient;
    FDelayLoaded[i] := False;

    if i < 9 then
    begin
      // Handle page switching on Ctrl+<number>
      FShortCuts[i] := TUiLibShortCut.Create(Self);
      FShortCuts[i].ShortCut := scCtrl or (Ord('1') + i);
      FShortCuts[i].OnExecute := OnTabShortCut;
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

procedure TFramePages.OnTabShortCut;
var
  i: Integer;
begin
  if not CanFocus then
    Exit;

  for i := 0 to High(FShortCuts) do
    if Sender = FShortCuts[i] then
    begin
      PageControl.ActivePageIndex := i;
      PageControlChange(Sender);
      Handled := True;
      Break;
    end;
end;


procedure TFramePages.PageControlChange;
begin
  // Initiate delayed loading for the newly visible frame
  NotifyDelayedLoading(PageControl.ActivePageIndex);
end;

{ Integration }

function NtUiLibHostPages(
  AOwner: TComponent;
  Pages: TArray<TWinControlFactory>;
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
