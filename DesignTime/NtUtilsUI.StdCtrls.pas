unit NtUtilsUI.StdCtrls;

{
  This module contains a (stripped down) design-time component definitions for
  the improved standard controls.

  NOTE: Keep the published interface in sync with the runtime definitions!
}

interface

uses
  System.Classes, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ImgList;

type
  TUiLibEdit = class(TEdit)
  private
    FOnDelayedChange: TNotifyEvent;
    FOnTypingChange: TNotifyEvent;
    FTypingTimeout: Cardinal;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property TypingTimeout: Cardinal read FTypingTimeout write FTypingTimeout default 500;
    property OnDelayedChange: TNotifyEvent read FOnDelayedChange write FOnDelayedChange;
    property OnTypingChange: TNotifyEvent read FOnTypingChange write FOnTypingChange;
  end;

  TUiLibButtonedEdit = class(TButtonedEdit)
  private
    FOnDelayedChange: TNotifyEvent;
    FOnTypingChange: TNotifyEvent;
    FTypingTimeout: Cardinal;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property TypingTimeout: Cardinal read FTypingTimeout write FTypingTimeout default 500;
    property OnDelayedChange: TNotifyEvent read FOnDelayedChange write FOnDelayedChange;
    property OnTypingChange: TNotifyEvent read FOnTypingChange write FOnTypingChange;
  end;

  TUiLibComboBox = class(TComboBox)
  public
    constructor Create(AOwner: TComponent); override;
  published
    property DropDownCount default 24;
  end;

  TUiLibMemo = class (TMemo)
  end;

  TUiLibButton = class(TButton)
  private
    FImageResource: String;
  published
    property ImageResource: String read FImageResource write FImageResource;
  end;

  TUiLibImageListHelper = class helper for TCustomImageList
    function AddIconFromResource(Instance: THandle; const ResourceName: String): Integer;
  end;

procedure Register;

implementation

uses
  Winapi.Windows, Winapi.CommCtrl;

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TUiLibEdit, TUiLibButtonedEdit,
    TUiLibComboBox, TUiLibMemo, TUiLibButton]);
end;

{ TUiLibEdit }

constructor TUiLibEdit.Create;
begin
  inherited;
  FTypingTimeout := 500;
end;

{ TUiLibButtonedEdit }

constructor TUiLibButtonedEdit.Create;
begin
  inherited;
  FTypingTimeout := 500;
end;

{ TUiLibComboBox }

constructor TUiLibComboBox.Create;
begin
  inherited;

  // Adjust defaults
  DropDownCount := 24;
end;

{ TUiLibImageListHelper }

function TUiLibImageListHelper.AddIconFromResource;
begin
  Result := ImageList_AddIcon(Handle, LoadIcon(Instance, PChar(ResourceName)));
  Change;
end;

end.
