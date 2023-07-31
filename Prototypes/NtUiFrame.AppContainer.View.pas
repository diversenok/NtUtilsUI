unit NtUiFrame.AppContainer.View;

{
  This module provides a dialog for viewing an AppContainer profile.
}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, VirtualTrees, VirtualTreesEx, DevirtualizedTree,
  NtUiBackend.AppContainers, NtUiCommon.Interfaces;

type
  TAppContainerViewFrame = class(TFrame, IHasDefaultCaption)
    Tree: TDevirtualizedTree;
  private
    FInfo: TAppContainerInfo;
    procedure InspectMenu(Node: PVirtualNode);
  protected
    procedure Loaded; override;
  public
    function GetDefaultCaption: String;
    procedure LoadFor(const Info: TAppContainerInfo);
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

function Initializer(const Info: TAppContainerInfo): TFrameInitializer;
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

procedure NtUiLibShowAppContainer(const Info: TAppContainerInfo);
begin
  if not Assigned(NtUiLibHostFramePick) then
    raise ENotSupportedException.Create('Frame host not available');

  NtUiLibHostFrameShow(Initializer(Info));
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowAppContainer := NtUiLibShowAppContainer;
end.
