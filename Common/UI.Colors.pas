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
  end;

var
  ColorSettings: TColorSettings = (
    clEnabledModified: $C0F0C0;
    clEnabled: $E0F0E0;
    clDisabled: $E0E0F0;
    clDisabledModified: $D0D0F0;
    clRemoved: $E0E0E0;
  );

implementation

end.
