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
    FDefaultCaption: String;
    function ConsumesEscape: Boolean;
    procedure SwitchToTab(Sender: TObject);
    function GetDefaultCaption: String;
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
begin
  // Forward the request to the frame from the active page
  Result := (PageControl.TabIndex > 0) and
    (PageControl.TabIndex <= High(FFrames)) and
    IUnknown(FFrames[PageControl.TabIndex]).QueryInterface(ICanConsumeEscape,
    ForwardedImpl).IsSuccess and ForwardedImpl.ConsumesEscape;
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

  for i := 0 to High(Frames) do
  begin
    // Make a new page
    FTabs[i] := TTabSheet.Create(PageControl);
    FTabs[i].PageControl := PageControl;

    if i = 0 then
    begin
      // Resize the frame to the biggest default size
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

    if i < 9 then
    begin
      // Handle page switching on Ctrl+<number>
      FActions[i] := TAction.Create(ActionList);
      FActions[i].ShortCut := scCtrl or (Ord('1') + i);
      FActions[i].Tag := i;
      FActions[i].OnExecute := SwitchToTab;
      FActions[i].ActionList := ActionList;
    end;
  end;

  FDefaultCaption := DefaultCaption;
end;

procedure TFramePages.PageControlChange;
var
  Observer: IObservesActivation;
  i: Integer;
begin
  // Adjust active state for all frames to handle conflicting shorcuts
  // correctly
  for i := 0 to High(FFrames) do
    if IUnknown(FFrames[i]).QueryInterface(IObservesActivation,
      Observer).IsSuccess then
      Observer.SetActive(i = PageControl.TabIndex);
end;

procedure TFramePages.SwitchToTab;
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
