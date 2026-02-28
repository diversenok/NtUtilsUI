unit NtUtilsUI.VirtualTreeEx;

{
  This module contains a (stripped down) design-time component definition for
  TVirtualStringTreeEx.

  NOTE: Keep the published interface in sync with the runtime definition!
}

interface

uses
  System.Classes, System.Types, Vcl.Menus, VirtualTrees;

type
  TNodeEvent = procedure (Node: PVirtualNode) of object;
  TPopupMode = (pmOnItemsOnly, pmAnywhere);

  TVirtualStringTreeEx = class(TVirtualStringTree)
  private
    FPopupMenuEx: TPopupMenu;
    FNoItemsText: String;
    FNoItemsTextLines: TArray<String>;
    FPopupMode: TPopupMode;
    FOnMainAction: TNodeEvent;
    procedure SetNoItemsText(const Value: String);
  protected
    procedure DoAfterPaint(Canvas: TCanvas); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property DrawSelectionMode default smBlendedRectangle;
    property HintMode default hmHint;
    property IncrementalSearch default isAll;
    property SelectionBlendFactor default 64;
    property OnMainAction: TNodeEvent read FOnMainAction write FOnMainAction;
    property PopupMenuEx: TPopupMenu read FPopupMenuEx write FPopupMenuEx;
    property PopupMode: TPopupMode read FPopupMode write FPopupMode default pmOnItemsOnly;
    property NoItemsText: String read FNoItemsText write SetNoItemsText;
  end;

procedure Register;

implementation

uses
  System.SysUtils, Vcl.Graphics, Vcl.Themes, VirtualTrees.Types,
  VirtualTrees.Header;

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TVirtualStringTreeEx]);
end;

{ TVirtualStringTreeEx }

constructor TVirtualStringTreeEx.Create(AOwner: TComponent);
begin
  inherited;

  DrawSelectionMode := smBlendedRectangle;
  HintMode := hmHint;
  IncrementalSearch := isAll;
  SelectionBlendFactor := 64;
  TreeOptions.AutoOptions := [toAutoDropExpand, toAutoScrollOnExpand,
    toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale];
  TreeOptions.ExportMode := emSelected;
  TreeOptions.MiscOptions := [toAcceptOLEDrop, toFullRepaintOnResize,
    toInitOnSave, toToggleOnDblClick, toWheelPanning];
  TreeOptions.PaintOptions := [toHideFocusRect, toHotTrack, toShowButtons,
    toShowDropmark, toThemeAware, toUseBlendedImages, toUseExplorerTheme];
  TreeOptions.SelectionOptions := [toFullRowSelect, toMultiSelect,
    toRightClickSelect];
  Header.DefaultHeight := 24;
  Header.Height := 24;
  Header.Options := [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack,
    hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize,
    hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption];
end;

procedure TVirtualStringTreeEx.DoAfterPaint;
var
  Sizes: TArray<TSize>;
  TotalHeight, Offset: Integer;
  i: Integer;
begin
  // Draw the no-items text
  if (VisibleCount = 0) and (Length(FNoItemsTextLines) > 0) then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := StyleServices.GetStyleFontColor(sfListItemTextDisabled);

    // Compute the sizes of each line
    SetLength(Sizes, Length(FNoItemsTextLines));
    TotalHeight := 0;

    for i := 0 to High(FNoItemsTextLines) do
    begin
      Sizes[i] := Canvas.TextExtent(FNoItemsTextLines[i]);
      Inc(TotalHeight, Sizes[i].Height);
    end;

    Offset := 0;

    // Draw the static text in the middle of an empty tree
    for i := 0 to High(FNoItemsTextLines) do
    begin
      Canvas.TextOut(
        (ClientWidth - Sizes[i].Width) div 2,
        (ClientHeight - Sizes[i].Height - TotalHeight) div 2 + Offset,
        FNoItemsTextLines[i]);
      Inc(Offset, Sizes[i].Height);
    end;
  end;
  inherited DoAfterPaint(Canvas);
end;

procedure TVirtualStringTreeEx.SetNoItemsText;
begin
  FNoItemsText := Value;
  FNoItemsTextLines := FNoItemsText.Split([#$D#$A]);
  Invalidate;
end;

end.
