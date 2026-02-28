unit NtUtilsUI.DevirtualizedTree;

{
  This module contains a (stripped down) design-time component definition for
  TDevirtualizedTree.

  NOTE: Keep the published interface in sync with the runtime definition!
}

interface

uses
  NtUtilsUI.VirtualTreeEx;

type
  TDevirtualizedTree = class(TVirtualStringTreeEx)
  end;

procedure Register;

implementation

uses
  System.Classes;

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TDevirtualizedTree]);
end;

end.
