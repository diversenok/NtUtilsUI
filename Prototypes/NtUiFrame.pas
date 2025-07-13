unit NtUiFrame;

{
  This file defines the base class for frames with extended functionality.
}

interface

uses
  Vcl.Forms, Vcl.Controls;

type
  TResourceIconChange = procedure (ImageList: TImageList; ImageIndex: Integer) of object;

  TResourceIcon = record
    IconName: String;
    Callback: TResourceIconChange;
  end;

  TBaseFrame = class (TFrame)
  private
    FLoaded: Boolean;
    FResourceIcons: TArray<TResourceIcon>;
  protected
    FImages: TImageList;
    procedure Loaded; override;
    procedure LoadedOnce; virtual;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    procedure ReloadResourceIcons;
    procedure RegisterResourceIcon(const IconName: String; Callback: TResourceIconChange);
  end;

implementation

uses
  Vcl.Graphics, Vcl.ImgList, DelphiUtils.AutoObjects;

{$R *.dfm}

{ TBaseFrame }

procedure TBaseFrame.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;

  if isDpiChange and FLoaded then
    ReloadResourceIcons;
end;

procedure TBaseFrame.Loaded;
begin
  inherited;

  if FLoaded then
    Exit;

  FLoaded := True;
  FImages := TImageList.Create(Self);
  FImages.ColorDepth := cd32Bit;

  LoadedOnce;
  ReloadResourceIcons;
end;

procedure TBaseFrame.LoadedOnce;
begin
  ;
end;

procedure TBaseFrame.RegisterResourceIcon;
begin
  SetLength(FResourceIcons, Length(FResourceIcons) + 1);
  FResourceIcons[High(FResourceIcons)].IconName := IconName;
  FResourceIcons[High(FResourceIcons)].Callback := Callback;
end;

procedure TBaseFrame.ReloadResourceIcons;
var
  i: Integer;
  Icon: TIcon;
  IconIndex: Integer;
begin
  // Reset all icons on subscribers
  for i := 0 to High(FResourceIcons) do
    FResourceIcons[i].Callback(nil, -1);

  // Adjust the desired resolution
  FImages.Clear;
  FImages.Width := 16 * CurrentPPI div 96;
  FImages.Height := 16 * CurrentPPI div 96;

  for i := 0 to High(FResourceIcons) do
  begin
    Icon := Auto.CaptureObject(TIcon.Create).Self;
    Icon.LoadFromResourceName(HInstance, FResourceIcons[i].IconName);
    IconIndex := FImages.AddIcon(Icon);

    if IconIndex >= 0 then
      FResourceIcons[i].Callback(FImages, IconIndex);
  end;
end;

end.
