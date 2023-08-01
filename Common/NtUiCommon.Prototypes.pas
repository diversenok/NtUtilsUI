unit NtUiCommon.Prototypes;

{
  This unit provides entrypoints for common inspection/selection dialogs.
}

interface

uses
  Ntapi.WinNt, NtUtils, NtUtils.Profiles, NtUtils.Security.AppContainer,
  NtUtils.Security, NtUtils.Security.Acl, DevirtualizedTree,
  NtUiDialog.FrameHost, System.Classes, Vcl.Forms;

type
  TFrameInitializer = NtUiDialog.FrameHost.TFrameInitializer;

var
  { Common: Frame Hosting }

  NtUiLibHostFrameShow: procedure (
    Initializer: TFrameInitializer
  );

  NtUiLibHostFramePick: function (
    AOwner: TComponent;
    Initializer: TFrameInitializer
  ): IInterface;

  NtUiLibHostPages: function (
    AOwner: TComponent;
    Pages: TArray<TFrameInitializer>;
    const DefaultCaption: String
  ): TFrame;

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

  { ACE }

  NtUiLibCreateAce: function (
    Owner: TComponent;
    AccessMaskType: Pointer;
    const GenericMapping: TGenericMapping
  ): TAceData;

  NtUiLibEditAce: function (
    Owner: TComponent;
    AccessMaskType: Pointer;
    const GenericMapping: TGenericMapping;
    const Ace: TAceData
  ): TAceData;

  { Security }

type
  TNtUiLibHandleProvider = reference to function (
    out Handle: IHandle;
    DesiredAccess: TAccessMask
  ): TNtxStatus;

  TNtUiLibSecurityContext = record
    HandleProvider: TNtUiLibHandleProvider;
    AccessMaskType: Pointer; // TypeInfo(...)
    GenericMapping: TGenericMapping;
    QueryFunction: TSecurityQueryFunction;
    SetFunction: TSecuritySetFunction;
  end;

var
  NtUiLibShowSecurity: procedure (
    const Context: TNtUiLibSecurityContext
  );

implementation

end.
