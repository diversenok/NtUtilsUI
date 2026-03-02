unit NtUtilsUI.ListView;

{
  This module contains a (stripped down) design-time component definition for
  TListViewEx.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, Vcl.ComCtrls;

type
  TListViewEx = class(TListView)
  private
    FColoringItems: Boolean;
    FPopupOnItemsOnly: Boolean;
    FClipboardColumn: Integer;
    FOnEditingEnd: TNotifyEvent;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ClipboardSourceColumn: Integer read FClipboardColumn write FClipboardColumn default -1;
    property ColoringItems: Boolean read FColoringItems write FColoringItems default False;
    property PopupOnItemsOnly: Boolean read FPopupOnItemsOnly write FPopupOnItemsOnly default False;
    property OnEditingEnd: TNotifyEvent read FOnEditingEnd write FOnEditingEnd;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TListViewEx]);
end;

{ TListViewEx }

constructor TListViewEx.Create;
begin
  inherited;
  FClipboardColumn := -1;
end;

end.
