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
  TWinControlFactory = NtUtilsUI.Components.Factories.TWinControlFactory;
  DefaultCaptionAttribute = NtUtilsUI.Base.DefaultCaptionAttribute;
  IDefaultCaption = NtUtilsUI.Base.IDefaultCaption;

  TCollectionHelper = class helper for TCollection
    function BeginUpdateAuto: IAutoReleasable;
  end;

  TStringsHelper = class helper for TStrings
    function BeginUpdateAuto: IAutoReleasable;
  end;

// Determine a default caption
function QueryDefaultCaption(Component: TComponent): String;

implementation

uses
  NtUtilsUI.Exceptions, DelphiUtils.LiteRTTI.Base;

{ Functions }

function QueryDefaultCaption(Component: TComponent): String;
var
  DynamicCaption: IDefaultCaption;
  AType: PLiteRttiTypeInfo;
  Attribute: PLiteRttiAttribute;
begin
  // Try to resolve a dynamic caption via interface first
  if IUnknown(Component).QueryInterface(IDefaultCaption,
    DynamicCaption) = S_OK then
    Result := DynamicCaption.GetDefaultCaption
  else
  begin
    // Otherwise, try to find the static caption attribute
    AType := Component.ClassType.ClassInfo;

    for Attribute in AType.Attributes do
      if Attribute.AttrubuteType = TypeInfo(DefaultCaptionAttribute) then
      begin
        Result := ReadUTF8String(Attribute.Arguments);
        Exit;
      end;

    // Or fall back to the class name
    Result := Component.ClassName;
  end;
end;

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
