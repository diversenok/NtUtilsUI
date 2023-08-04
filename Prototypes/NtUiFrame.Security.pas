unit NtUiFrame.Security;

{
  This module provides entrypoints for showing the object security dialog.
}

interface

uses
  NtUiCommon.Prototypes;

// Make an initializer for a security descriptor viewer frame
function NtUiLibMakeSecurityFrame(
  const Context: TNtUiLibSecurityContext
): TFrameInitializer;

implementation

uses
  NtUiFrame.Security.Acl, NtUiFrame.Security.OwnerGroup,
  System.SysUtils, System.Classes, Vcl.Forms;

function NtUiLibMakeSecurityFrame;
begin
  if not Assigned(NtUiLibHostPages) then
    raise ENotSupportedException.Create('Page Host frame not available.');

  Result := function (AOwner: TComponent): TFrame
    begin
      // Make a multi-page frame with ACLs and SIDs from the security descriptor
      Result := NtUiLibHostPages(AOwner, [
        NtUiLibAclSecurityFrameInitializer(aiDacl, Context),
        NtUiLibSidSecurityFrameInitializer(dsOwner, Context),
        NtUiLibAclSecurityFrameInitializer(aiLabel, Context),
        NtUiLibAclSecurityFrameInitializer(aiTrust, Context),
        NtUiLibAclSecurityFrameInitializer(aiFilter, Context),
        NtUiLibAclSecurityFrameInitializer(aiAttribute, Context),
        NtUiLibAclSecurityFrameInitializer(aiScope, Context),
        NtUiLibAclSecurityFrameInitializer(aiSacl, Context),
        NtUiLibSidSecurityFrameInitializer(dsPrimaryGroup, Context)
      ], 'Object Security');
    end;
end;

procedure NtUiLibShowSecurity(
  const Context: TNtUiLibSecurityContext
);
begin
  if not Assigned(NtUiLibHostFrameShow) then
    raise ENotSupportedException.Create('Frame host not available');

  NtUiLibHostFrameShow(NtUiLibMakeSecurityFrame(Context));
end;

initialization
  NtUiCommon.Prototypes.NtUiLibShowSecurity := NtUiLibShowSecurity;
end.
