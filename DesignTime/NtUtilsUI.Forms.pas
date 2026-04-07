unit NtUtilsUI.Forms;

{
  This module contains the (stripped down) design-time component definitions for
  the improved base form classes.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  Vcl.Forms;

type
  TUiLibForm = class abstract (TForm)
  private
    FCloseOnEscape: Boolean;
  published
    property CloseOnEscape: Boolean read FCloseOnEscape write FCloseOnEscape default False;
  end;

  TUiLibMainForm = class abstract (TUiLibForm)
  end;

  TUiLibChildForm = class abstract (TUiLibForm)
  end;

procedure Register;

implementation

uses
  System.Classes, DesignIntf, DesignEditors;

procedure Register;
begin
  RegisterNoIcon([TUiLibMainForm, TUiLibChildForm]);
  RegisterCustomModule(TUiLibMainForm, TCustomModule);
  RegisterCustomModule(TUiLibChildForm, TCustomModule);
end;

end.
