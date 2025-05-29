unit UI.Colors;

interface

uses
  Vcl.Graphics;

type
  TColorSettings = record
    // Text background
    clBackgroundAllow: TColor;
    clBackgroundAllowAccent: TColor;
    clBackgroundDeny: TColor;
    clBackgroundDenyAccent: TColor;
    clBackgroundAlter: TColor;
    clBackgroundAlterAccent: TColor;
    clBackgroundError: TColor;
    clBackgroundInactive: TColor;
    clBackgroundUnsaved: TColor;
    clBackgroundSystem: TColor;
    clBackgroundUser: TColor;
    clBackgroundGuiThread: TColor;

    // Text foreground
    clForegroundError: TColor;
    clForegroundInactive: TColor;
    clForegroundLink: TColor;
  end;

var
  ColorSettings: TColorSettings = (
    clBackgroundAllow: $E0F0E0;               // Light green
    clBackgroundAllowAccent: $C0F0C0;          // Medium-light green
    clBackgroundDeny: $E0E0F0;                 // Light red
    clBackgroundDenyAccent: $D0D0F0;           // Medium-light red
    clBackgroundAlter: $F0E0E0;                // Light blue-gray
    clBackgroundAlterAccent: $F0C0C0;          // Medium blue-gray
    clBackgroundError: $D0D0F0;                // Medium-light red
    clBackgroundInactive: $E0E0E0;             // Light gray
    clBackgroundUnsaved: $F5DCC2;              // Light blue
    clBackgroundSystem: $FFDDBB;               // Light blue
    clBackgroundUser: $AAFFFF;                 // Light yellow
    clBackgroundGuiThread: $77FFFF;            // Light yellow
    clForegroundError: $0000F0;                // Red
    clForegroundInactive: $808080;             // Gray
    clForegroundLink: $D77800;                 // Blue
  );

implementation

end.
