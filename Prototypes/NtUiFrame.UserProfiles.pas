unit NtUiFrame.UserProfiles;

{
  This module provides a frame for listing user profiles.
}

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, VirtualTrees, VirtualTreesEx, DevirtualizedTree,
  NtUiFrame.Search, NtUiCommon.Interfaces, NtUiBackend.UserProfiles;

type
  IProfileNode = NtUiBackend.UserProfiles.IProfileNode;

  TUserProfilesFrame = class(TFrame, IHasSearch, ICanConsumeEscape,
    IGetFocusedNode, IOnNodeSelection, IHasDefaultCaption)
  published
    Tree: TDevirtualizedTree;
    SearchBox: TSearchFrame;
  private
    Backend: TTreeNodeInterfaceProvider;
    BackendRef: IUnknown;
    property BackendImpl: TTreeNodeInterfaceProvider read Backend implements IGetFocusedNode, IOnNodeSelection;
    property SearchImpl: TSearchFrame read SearchBox implements IHasSearch, ICanConsumeEscape;
    function DefaultCaption: String;
  protected
    procedure Loaded; override;
  public
    procedure LoadAllUsers;
  end;

implementation

uses
  NtUtils;

{$R *.dfm}

{ TUserProfilesFrame }

function TUserProfilesFrame.DefaultCaption;
begin
  Result := 'Select User Profile...';
end;

procedure TUserProfilesFrame.LoadAllUsers;
var
  Providers: TArray<IProfileNode>;
  Provider: IProfileNode;
  Status: TNtxStatus;
begin
  Status := UiLibEnumerateProfiles(Providers);
  Backend.SetStatus(Status);

  if not Status.IsSuccess then
    Exit;

  Backend.BeginUpdateAuto;
  Backend.ClearItems;

  for Provider in Providers do
    Backend.AddItem(Provider);
end;

procedure TUserProfilesFrame.Loaded;
begin
  inherited;
  SearchBox.AttachToTree(Tree);
  Backend := TTreeNodeInterfaceProvider.Create(Tree, [teSelectionChange]);
  BackendRef := Backend; // Make an owning reference
end;

end.
