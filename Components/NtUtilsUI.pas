unit NtUtilsUI;

{
  This module aggregates the base NtUtilsUI types.
}

interface

uses
  System.Classes, NtUtilsUI.Forms, NtUtilsUI.Base,
  NtUtilsUI.Components.Factories, NtUtilsUI.Colors, NtUtils;

const
  // Forward child form modes
  cfmNormal = NtUtilsUI.Forms.cfmNormal;
  cfmApplication = NtUtilsUI.Forms.cfmApplication;
  cfmDesktop = NtUtilsUI.Forms.cfmDesktop;

var
  // Choose the default color settings
  ColorSettings: PColorSettings = @DefaultColorSettings;

type
  // Forward known base classes and interfaces
  TUiLibMainForm = NtUtilsUI.Forms.TUiLibMainForm;
  TUiLibChildForm = NtUtilsUI.Forms.TUiLibChildForm;
  TUiLibShortCut = NtUtilsUI.Base.TUiLibShortCut;
  TUiLibControl = NtUtilsUI.Base.TUiLibControl;
  IHasDefaultCaption = NtUtilsUI.Base.IHasDefaultCaption;
  TWinControlFactory = NtUtilsUI.Components.Factories.TWinControlFactory;

  TCollectionHelper = class helper for TCollection
    function BeginUpdateAuto: IAutoReleasable;
  end;

  TStringsHelper = class helper for TStrings
    function BeginUpdateAuto: IAutoReleasable;
  end;

implementation

uses
  NtUtilsUI.Exceptions;

{ TCollectionHelper }

function TCollectionHelper.BeginUpdateAuto;
begin
  BeginUpdate;

  Result := Auto.Defer(
    procedure
    begin
      EndUpdate;
    end
  );
end;

{ TStringsHelper }

function TStringsHelper.BeginUpdateAuto;
begin
  BeginUpdate;

  Result := Auto.Defer(
    procedure
    begin
      EndUpdate;
    end
  );
end;

end.
