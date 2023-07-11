unit NtUiCommon.Prototypes;

{
  This unit provides entrypoints for common inspection/selection dialogs.
}

interface

uses
  Ntapi.WinNt, NtUtils, NtUtils.Profiles, NtUtils.Security.AppContainer,
  DevirtualizedTree, NtUiDialog.FrameHost, System.Classes;

type
  TFrameInitializer = NtUiDialog.FrameHost.TFrameInitializer;

var
  { Common: Frame Host }

  NtUiLibHostFrameShow: procedure (
    Initializer: TFrameInitializer
  );

  NtUiLibHostFramePick: function (
    AOwner: TComponent;
    Initializer: TFrameInitializer
  ): INodeProvider;

  { Bit Masks }

  NtUiLibShowBitMask: procedure (
    const Value: UInt64;
    ATypeInfo: Pointer
  );

  NtUiLibShowAccessMask: procedure (
    const Value: TAccessMask;
    ATypeInfo: Pointer;
    const GenericMapping: TGenericMapping
  );

  { User Profiles }

  NtUiLibShowUserProfiles: procedure;

  NtUiLibSelectUserProfile: function (
    Owner: TComponent
  ): TProfileInfo;

  { AppContainer Profiles }

  NtUiLibShowAppContainer: procedure(
    const Info: TAppContainerInfo
  );

  NtUiLibShowAppContainers: procedure(
    const User: ISid
  );

  NtUiLibShowAppContainersAllUsers: procedure(
    [opt] const DefaultUser: ISid = nil
  );

  NtUiLibSelectAppContainer: function (
    Owner: TComponent;
    const User: ISid
  ): TAppContainerInfo;

  NtUiLibSelectAppContainerAllUsers: function (
    Owner: TComponent;
    [opt] const DefaultUser: ISid = nil
  ): TAppContainerInfo;

implementation

end.
