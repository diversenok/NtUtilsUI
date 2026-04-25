unit NtUtilsUI.DevirtualizedTree;

{
  This module contains a (stripped down) design-time component definition for
  TDevirtualizedTree.

  NOTE: Keep the published interface in sync with the runtime definition!
}

interface

uses
  System.Classes, Vcl.Controls, Vcl.Menus, VirtualTrees, VirtualTrees.Header,
  VirtualTrees.Types;

type
  INodeProvider = interface
  end;

  TNodeProviderEvent = procedure (Node: INodeProvider) of object;

  TDevirtualizedTreePopupMode = (pmOnItemsOnly, pmAnywhere);

  TDevirtualizedTreeOptions = class (TStringTreeOptions)
  strict private
    FAutoShowRoot: Boolean;
  public
    constructor Create(AOwner: TCustomControl); override;
    procedure AssignTo(Dest: TPersistent); override;
  published
    property AutoShowRoot: Boolean read FAutoShowRoot write FAutoShowRoot default True;
    property AutoOptions default [toAutoDropExpand, toAutoScrollOnExpand, toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale];
    property ExportMode default emSelected;
    property MiscOptions default [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning];
    property PaintOptions default [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toThemeAware, toUseBlendedImages, toUseExplorerTheme];
    property SelectionOptions default [toFullRowSelect, toMultiSelect, toRightClickSelect];
  end;

  TDevirtualizedTreeColumns = class (TVirtualTreeColumns)
  end;

  TDevirtualizedTreeHeader = class (TVTHeader)
  private
    function GetColumns: TDevirtualizedTreeColumns;
    procedure SetColumns(const Value: TDevirtualizedTreeColumns);
  protected
    function GetColumnsClass: TVirtualTreeColumnsClass; override;
  public
    constructor Create(AOwner: TCustomControl); override;
  published
    property Columns: TDevirtualizedTreeColumns read GetColumns write SetColumns stored False;
    property DefaultHeight default 24;
    property Height default 24;
    property Options default [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack, hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize, hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption];
  end;

  TDevirtualizedTree = class (TVirtualStringTree)
  private
    FPopupMenu: TPopupMenu;
    FPopupMode: TDevirtualizedTreePopupMode;
    FEmptyListMessage: String;
    FEmptyListMessageLines: TArray<String>;
    FMainActionMenuText: String;
    FOnMainAction: TNodeProviderEvent;
    procedure SetEmptyListMessage(Value: String);
    function GetTreeOptions: TDevirtualizedTreeOptions;
    procedure SetTreeOptions(Value: TDevirtualizedTreeOptions);
    function GetHeader: TDevirtualizedTreeHeader;
    procedure SetHeader(const Value: TDevirtualizedTreeHeader);
  protected
    procedure DoAfterPaint(Canvas: TCanvas); override;
    function GetHeaderClass: TVTHeaderClass; override;
    function GetOptionsClass: TTreeOptionsClass; override;
    property ClipboardFormats;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property DrawSelectionMode default smBlendedRectangle;
    property EmptyListMessage: String read FEmptyListMessage write SetEmptyListMessage;
    property Header: TDevirtualizedTreeHeader read GetHeader write SetHeader;
    property HintMode default hmHint;
    property IncrementalSearch default isAll;
    property MainActionMenuText: String read FMainActionMenuText write FMainActionMenuText;
    property PopupMenu: TPopupMenu read FPopupMenu write FPopupMenu;
    property PopupMode: TDevirtualizedTreePopupMode read FPopupMode write FPopupMode default pmOnItemsOnly;
    property SelectionBlendFactor default 64;
    property TreeOptions: TDevirtualizedTreeOptions read GetTreeOptions write SetTreeOptions;
    property OnMainAction: TNodeProviderEvent read FOnMainAction write FOnMainAction;
  end;

procedure Register;

implementation

uses
  System.Types, System.SysUtils, Vcl.Graphics, Vcl.Themes;

procedure Register;
begin
  RegisterComponents('NtUtilsUI', [TDevirtualizedTree]);
end;

{ TDevirtualizedTreeOptions }

procedure TDevirtualizedTreeOptions.AssignTo;
begin
  if Dest is TDevirtualizedTreeOptions then
    TDevirtualizedTreeOptions(Dest).FAutoShowRoot := FAutoShowRoot;

  inherited;
end;

constructor TDevirtualizedTreeOptions.Create;
begin
  inherited Create(AOwner);

  // Adjust existing defaults
  AutoOptions := [toAutoDropExpand, toAutoScrollOnExpand,
    toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale];
  ExportMode := emSelected;
  MiscOptions := [toAcceptOLEDrop, toFullRepaintOnResize,
    toInitOnSave, toToggleOnDblClick, toWheelPanning];
  PaintOptions := [toHideFocusRect, toHotTrack, toShowButtons,
    toShowDropmark, toThemeAware, toUseBlendedImages, toUseExplorerTheme];
  SelectionOptions := [toFullRowSelect, toMultiSelect,
    toRightClickSelect];

  // Choose new option defaults
  FAutoShowRoot := True;
end;

{ TDevirtualizedTreeHeader }

constructor TDevirtualizedTreeHeader.Create;
begin
  inherited;

  // Adjust defaults
  DefaultHeight := 24;
  Height := 24;
  Options := [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack,
    hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize,
    hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption];
end;

function TDevirtualizedTreeHeader.GetColumns;
begin
  Result := TDevirtualizedTreeColumns(inherited Columns);
end;

function TDevirtualizedTreeHeader.GetColumnsClass;
begin
  Result := TDevirtualizedTreeColumns;
end;

procedure TDevirtualizedTreeHeader.SetColumns;
begin
  inherited Columns := Value;
end;

{ TDevirtualizedTree }

constructor TDevirtualizedTree.Create;
begin
  inherited;

  // Adjust defaults
  DrawSelectionMode := smBlendedRectangle;
  HintMode := hmHint;
  IncrementalSearch := isAll;
  SelectionBlendFactor := 64;
  ClipboardFormats.Add('CSV');
  ClipboardFormats.Add('Plain text');
  ClipboardFormats.Add('Unicode text');
end;

procedure TDevirtualizedTree.DoAfterPaint;
var
  Sizes: TArray<TSize>;
  TotalHeight, Offset: Integer;
  i: Integer;
begin
  // Draw the no-items text
  if (VisibleCount = 0) and (Length(FEmptyListMessageLines) > 0) then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := StyleServices.GetStyleFontColor(sfListItemTextDisabled);

    // Compute the sizes of each line
    SetLength(Sizes, Length(FEmptyListMessageLines));
    TotalHeight := 0;

    for i := 0 to High(FEmptyListMessageLines) do
    begin
      Sizes[i] := Canvas.TextExtent(FEmptyListMessageLines[i]);
      Inc(TotalHeight, Sizes[i].Height);
    end;

    Offset := 0;

    // Draw the static text in the middle of an empty tree
    for i := 0 to High(FEmptyListMessageLines) do
    begin
      Canvas.TextOut(
        (ClientWidth - Sizes[i].Width) div 2,
        (ClientHeight - Sizes[i].Height - TotalHeight) div 2 + Offset,
        FEmptyListMessageLines[i]);
      Inc(Offset, Sizes[i].Height);
    end;
  end;

  inherited DoAfterPaint(Canvas);
end;

function TDevirtualizedTree.GetHeader;
begin
  Result := TDevirtualizedTreeHeader(inherited Header);
end;

function TDevirtualizedTree.GetHeaderClass;
begin
  Result := TDevirtualizedTreeHeader;
end;

function TDevirtualizedTree.GetOptionsClass;
begin
  Result := TDevirtualizedTreeOptions;
end;

function TDevirtualizedTree.GetTreeOptions;
begin
  Result := TDevirtualizedTreeOptions(inherited TreeOptions);
end;

procedure TDevirtualizedTree.SetEmptyListMessage;
begin
  if FEmptyListMessage <> Value then
  begin
    FEmptyListMessage := Value;
    FEmptyListMessageLines := Value.Split([#$D#$A]);
    Invalidate;
  end;
end;

procedure TDevirtualizedTree.SetHeader;
begin
  inherited Header := Value;
end;

procedure TDevirtualizedTree.SetTreeOptions;
begin
  inherited TreeOptions := Value;
end;

end.
