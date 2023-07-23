object BitsFrame: TBitsFrame
  Left = 0
  Top = 0
  Width = 320
  Height = 317
  Constraints.MinHeight = 100
  Constraints.MinWidth = 200
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object Tree: TDevirtualizedTree
    Left = 0
    Top = 0
    Width = 320
    Height = 289
    Align = alClient
    ClipboardFormats.Strings = (
      'CSV'
      'Plain text'
      'Unicode text')
    Header.AutoSizeIndex = 0
    Header.DefaultHeight = 24
    Header.Height = 24
    Header.Options = [hoAutoResize, hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack, hoRestrictDrag, hoShowSortGlyphs, hoDisableAnimatedResize, hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption]
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale]
    TreeOptions.ExportMode = emSelected
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toCheckSupport, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning]
    TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toShowTreeLines, toThemeAware, toUseBlendedImages, toUseExplorerTheme]
    TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect, toRightClickSelect]
    OnChecked = TreeChecked
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    NoItemsText = 'No flags to display'
    Columns = <
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 0
        Text = 'Name'
        Width = 320
      end>
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 289
    Width = 320
    Height = 28
    Align = alBottom
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    object tbxValue: TEdit
      AlignWithMargins = True
      Left = 73
      Top = 5
      Width = 174
      Height = 21
      Margins.Left = 0
      Margins.Top = 5
      Margins.Right = 0
      Margins.Bottom = 2
      Align = alClient
      MaxLength = 30
      TabOrder = 0
      OnChange = tbxValueChange
    end
    object btnClear: TButton
      AlignWithMargins = True
      Left = 0
      Top = 3
      Width = 70
      Height = 25
      Margins.Left = 0
      Margins.Bottom = 0
      Align = alLeft
      Caption = 'Clear'
      TabOrder = 1
      OnClick = btnClearClick
    end
    object btnAll: TButton
      AlignWithMargins = True
      Left = 250
      Top = 3
      Width = 70
      Height = 25
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alRight
      Caption = 'All'
      TabOrder = 2
      OnClick = btnAllClick
    end
  end
end
