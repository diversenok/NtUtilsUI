unit UI.Colors;

interface

uses
  Vcl.Graphics;

type
  TColorSettings = record
    clEnabledModified: TColor;
    clEnabled: TColor;
    clDisabled: TColor;
    clDisabledModified: TColor;
    clRemoved: TColor;
    clStale: TColor;
    clIntegrity: TColor;
    clSuspended: TColor;
    clGuiThread: TColor;
  end;

var
  ColorSettings: TColorSettings = (
    clEnabledModified: $C0F0C0;
    clEnabled: $E0F0E0;
    clDisabled: $E0E0F0;
    clDisabledModified: $D0D0F0;
    clRemoved: $E0E0E0;
    clStale: $F5DCC2;
    clIntegrity: $F0E0E0;
    clSuspended: $AAAAAA;
    clGuiThread: $77FFFF;
  );

implementation

end.
