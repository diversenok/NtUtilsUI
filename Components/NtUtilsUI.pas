unit NtUtilsUI;

{
  This module provides base NtUtilsUI types.
}

interface

uses
  NtUtilsUI.Forms;

type
  TMainForm = NtUtilsUI.Forms.TMainForm;
  TChildForm = NtUtilsUI.Forms.TChildForm;

const
  cfmNormal = NtUtilsUI.Forms.cfmNormal;
  cfmApplication = NtUtilsUI.Forms.cfmApplication;
  cfmDesktop = NtUtilsUI.Forms.cfmDesktop;

implementation

uses
  NtUtilsUI.Exceptions;

end.
