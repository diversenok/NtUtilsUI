unit NtUtilsUI.SearchBox;

{
  This module contains the full runtime component definition for the search box
  control.

  NOTE: Keep the published interface in sync with the design-time definitions!
}

interface

uses
  System.Classes, Vcl.ImgList, NtUtilsUI, NtUtilsUI.StdCtrls;

type
  TUiLibSearchBox = class (TUiLibControl)
  private
    FEdit: TUiLibButtonedEdit;
    FImageList: TCustomImageList;
    FLeftImageIndex: array [Boolean] of Integer;
    FFocusShortCut: TUiLibShortCut;
    FEscShortCut: TUiLibShortCut;
    FOnSearch, FOnArrowUp, FOnArrowDown: TNotifyEvent;
    procedure OnFocusShortCut(Sender: TUiLibShortCut; var Handled: Boolean);
    procedure OnEscapeShortCut(Sender: TUiLibShortCut; var Handled: Boolean);
    function GetHasQuery: Boolean;
    function GetQuery: String;
    procedure ReloadIcons;
    procedure RefreshLeftIcon;
    procedure QueryChanged(Sender: TObject);
    procedure RightButtonClick(Sender: TObject);
    procedure TypingChange(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  protected
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ClearQuery;
    property HasQuery: Boolean read GetHasQuery;
    property Query: String read GetQuery;
  published
    property OnSearch: TNotifyEvent read FOnSearch write FOnSearch;
    property OnArrowUp: TNotifyEvent read FOnArrowUp write FOnArrowUp;
    property OnArrowDown: TNotifyEvent read FOnArrowDown write FOnArrowDown;
  end;

implementation

uses
  Winapi.Windows, Vcl.Controls;

{$R '..\Icons\SearchBox.res'}

{ TUiLibSearchBox }

procedure TUiLibSearchBox.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;
  ReloadIcons;
end;

procedure TUiLibSearchBox.ClearQuery;
begin
  // This will also re-apply the search
  FEdit.Text := '';
end;

constructor TUiLibSearchBox.Create;
begin
  inherited;

  Width := 270;
  Height := 21;
  Constraints.MinWidth := 110;

  FEdit := TUiLibButtonedEdit.Create(Self);
  FEdit.Width := Width;
  FEdit.Height := Height;
  FEdit.Align := alClient;
  FEdit.TextHint := 'Search';
  FEdit.OnDelayedChange := QueryChanged;
  FEdit.OnRightButtonClick := RightButtonClick;
  FEdit.OnTypingChange := TypingChange;
  FEdit.OnKeyDown := EditKeyDown;
  FEdit.Parent := Self;

  FImageList := TCustomImageList.Create(Self);
  FImageList.ColorDepth := cd32Bit;
  FEdit.Images := FImageList;
  ReloadIcons;

  FFocusShortCut := TUiLibShortCut.Create(Self);
  FFocusShortCut.ShortCut := scCtrl or Ord('F');
  FFocusShortCut.OnExecute := OnFocusShortCut;

  FEscShortCut := TUiLibShortCut.Create(Self);
  FEscShortCut.ShortCut := VK_ESCAPE;
  FEscShortCut.OnExecute := OnEscapeShortCut;
end;

procedure TUiLibSearchBox.EditKeyDown;
begin
  case Key of
    VK_UP, VK_PRIOR:
      if Assigned(FOnArrowUp) then
        FOnArrowUp(Self);

    VK_DOWN, VK_NEXT:
      if Assigned(FOnArrowDown) then
        FOnArrowDown(Self);
  end;
end;

function TUiLibSearchBox.GetHasQuery;
begin
  Result := FEdit.Text <> '';
end;

function TUiLibSearchBox.GetQuery;
begin
  Result := FEdit.Text;
end;

procedure TUiLibSearchBox.OnEscapeShortCut;
begin
  if FEdit.Focused and HasQuery then
  begin
    ClearQuery;
    Handled := True;
  end;
end;

procedure TUiLibSearchBox.OnFocusShortCut;
begin
  if CanFocus then
  begin
    FEdit.SetFocus;
    Handled := True;
  end;
end;

procedure TUiLibSearchBox.QueryChanged;
begin
  FEdit.RightButton.Visible := HasQuery;

  if Assigned(FOnSearch) then
    FOnSearch(Self);
end;

procedure TUiLibSearchBox.RefreshLeftIcon;
begin
  FEdit.LeftButton.ImageIndex := FLeftImageIndex[FEdit.Typing];
  FEdit.LeftButton.Visible := FEdit.LeftButton.ImageIndex >= 0;
end;

procedure TUiLibSearchBox.ReloadIcons;
begin
  FImageList.Clear;
  FImageList.Width := 16 * CurrentPPI div 96;
  FImageList.Height := FImageList.Width;

  // The right icon is static
  FEdit.RightButton.ImageIndex := FImageList.AddIconFromResource(HInstance,
    'SearchBox.Clear');

  // The left icon changes with the typing state
  FLeftImageIndex[False] := FImageList.AddIconFromResource(HInstance,
    'SearchBox.Search');
  FLeftImageIndex[True] := FImageList.AddIconFromResource(HInstance,
    'SearchBox.Typing');
  RefreshLeftIcon;
end;

procedure TUiLibSearchBox.RightButtonClick;
begin
  ClearQuery;
end;

procedure TUiLibSearchBox.TypingChange;
begin
  RefreshLeftIcon;
end;

end.
