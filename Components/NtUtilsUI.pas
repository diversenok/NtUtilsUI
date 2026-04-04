unit NtUtilsUI;

{
  This module provides base NtUtilsUI types.
}

interface

uses
  NtUtilsUI.Forms;

type
  TUiLibMainForm = NtUtilsUI.Forms.TUiLibMainForm;
  TUiLibChildForm = NtUtilsUI.Forms.TUiLibChildForm;

const
  cfmNormal = NtUtilsUI.Forms.cfmNormal;
  cfmApplication = NtUtilsUI.Forms.cfmApplication;
  cfmDesktop = NtUtilsUI.Forms.cfmDesktop;

implementation

uses
  NtUtilsUI.Exceptions;

end.
