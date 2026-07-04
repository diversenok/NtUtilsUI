unit NtUtilsUI.SearchBox;

{
  This module contains a (stripped down) design-time component definitions for
  the search box control.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, Vcl.ImgList, NtUtilsUI.StdCtrls, NtUtilsUI.Base;

type
  TUiLibSearchBox = class (TUiLibControl)
  private
    FEdit: TUiLibButtonedEdit;
    FImageList: TCustomImageList;
    FOnTypingChange, FOnChange, FOnSearch, FOnArrowUp, FOnArrowDown: TNotifyEvent;
    procedure ReloadIcons;
    function GetTypingTimeout: Cardinal;
    procedure SetTypingTimeout(Value: Cardinal);
  protected
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property TypingTimeout: Cardinal read GetTypingTimeout write SetTypingTimeout default 500;
    property OnTypingChange: TNotifyEvent read FOnTypingChange write FOnTypingChange;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnSearch: TNotifyEvent read FOnSearch write FOnSearch;
    property OnArrowUp: TNotifyEvent read FOnArrowUp write FOnArrowUp;
    property OnArrowDown: TNotifyEvent read FOnArrowDown write FOnArrowDown;
  end;

procedure Register;

implementation

uses
  Vcl.Controls;

{$R '..\Icons\SearchBox.res'}
{$R 'Icons\TUiLibSearchBox.res'}

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibSearchBox]);
end;

{ TUiLibSearchBox }

procedure TUiLibSearchBox.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;
  ReloadIcons;
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
  FEdit.Parent := Self;

  FImageList := TCustomImageList.Create(Self);
  FImageList.ColorDepth := cd32Bit;
  FEdit.Images := FImageList;
  FEdit.LeftButton.Visible := True;
  ReloadIcons;
end;

function TUiLibSearchBox.GetTypingTimeout;
begin
  Result := FEdit.TypingTimeout;
end;

procedure TUiLibSearchBox.ReloadIcons;
begin
  FImageList.Clear;
  FImageList.Width := 16 * CurrentPPI div 96;
  FImageList.Height := FImageList.Width;

  FEdit.LeftButton.ImageIndex := FImageList.AddIconFromResource(HInstance,
    'SearchBox.Search');
end;

procedure TUiLibSearchBox.SetTypingTimeout;
begin
  FEdit.TypingTimeout := Value;
end;

end.
