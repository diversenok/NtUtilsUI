unit NtUiFrame.AppContainer.View;

{
  This module provides a dialog for viewing an AppContainer profile.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, VirtualTrees, NtUtilsUI.VirtualTreeEx,
  NtUtilsUI.DevirtualizedTree, NtUiBackend.AppContainers,
  NtUiCommon.Interfaces;

type
  TAppContainerViewFrame = class(TFrame, IHasDefaultCaption)
    Tree: TDevirtualizedTree;
  private
    FInfo: TRtlxAppContainerInfo;
    procedure InspectMenu(Node: PVirtualNode);
  protected
    procedure Loaded; override;
  public
    function GetDefaultCaption: String;
    procedure LoadFor(const Info: TRtlxAppContainerInfo);
  end;

implementation

uses
  NtUiCommon.Prototypes;

{$R *.dfm}

{ TAppContainerViewFrame }

function TAppContainerViewFrame.GetDefaultCaption;
begin
  Result := 'AppContainer Information';
end;

procedure TAppContainerViewFrame.InspectMenu;
begin
  if FInfo.IsChild and Assigned(Tree.FocusedNode) then
    UiLibInspectAppContainerProperty(FInfo, Tree.FocusedNode.Index);
end;

procedure TAppContainerViewFrame.Loaded;
begin
  inherited;
  Tree.OnMainAction := InspectMenu;
end;

procedure TAppContainerViewFrame.LoadFor;
begin
  FInfo := Info;
  UiLibMakeAppContainerPropertyNodes(Tree, Info);
end;

{ Integration }

function Initializer(const Info: TRtlxAppContainerInfo): TFrameInitializer;
begin
  Result := function (AOwner: TComponent): TFrame
    var
      Frame: TAppContainerViewFrame absolute Result;
    begin
      Frame := TAppContainerViewFrame.Create(AOwner);
      try
        Frame.LoadFor(Info);
      except
        Frame.Free;
        raise;
      end;
    end;
end;

procedure NtUiLibShowAppContainer(const Info: TRtlxAppContainerInfo);
begin
  if not Assigned(NtUiLibHostFramePick) then
    raise ENotSupportedException.Create('Frame host not available');

  NtUiLibHostFrameShow(Initializer(Info));
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowAppContainer := NtUiLibShowAppContainer;
end.
