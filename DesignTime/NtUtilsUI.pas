unit NtUtilsUI;

{
  This module contains (stripped down) design-time component base definitions.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  Winapi.Messages, Vcl.Controls;

type
  // A base class for composite visual controls
  TUiLibControl = class abstract (TWinControl)
  private
    FLoaded: Boolean;
  protected
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure Loaded; override;
    procedure LoadedOnce; virtual;
  published
    property Align;
    property Anchors;
    property Enabled;
    property TabOrder;
    property TabStop;
    property Visible;
  end;

implementation

{ TUiLibControl }

procedure TUiLibControl.CMEnabledChanged;
var
  i: Integer;
begin
  inherited;

  // Notify all children of the enabled state change
  for i := 0 to ControlCount - 1 do
    if (Controls[i].Owner = Self) and (Controls[i] is TWinControl) then
      TWinControl(Controls[i]).Enabled := Enabled;
end;

procedure TUiLibControl.Loaded;
begin
  inherited;

  if not FLoaded then
  begin
    FLoaded := True;
    LoadedOnce;
  end;
end;

procedure TUiLibControl.LoadedOnce;
begin
  ; // To be overriden
end;

end.
