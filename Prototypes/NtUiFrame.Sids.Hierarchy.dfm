inherited SidHierarchyFrame: TSidHierarchyFrame
  Width = 640
  Height = 400
  Constraints.MinHeight = 120
  Constraints.MinWidth = 300
  object Tree: TDevirtualizedTree
    AlignWithMargins = True
    Left = 0
    Top = 24
    Width = 640
    Height = 376
    Margins.Left = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    ClipboardFormats.Strings = (
      'CSV'
      'Plain text'
      'Unicode text')
    Header.AutoSizeIndex = 0
    Header.DefaultHeight = 24
    Header.Height = 24
    Header.Options = [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack, hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize, hoAutoColumnPopupMenu, hoAutoResizeInclCaption]
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale]
    TreeOptions.ExportMode = emSelected
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning]
    TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toShowRoot, toShowTreeLines, toThemeAware, toUseBlendedImages, toUseExplorerTheme]
    TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect, toRightClickSelect]
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    NoItemsText = 'Not initialized'
    Columns = <
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 0
        Text = 'SID'
        Width = 210
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 1
        Text = 'Friendly Name'
        Width = 290
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 2
        Text = 'SID Type'
        Width = 110
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 3
        Text = 'Definition'
        Width = 440
      end>
  end
  inline SearchBox: TSearchFrame
    Left = 0
    Top = 0
    Width = 640
    Height = 21
    Align = alTop
    Constraints.MinHeight = 21
    Constraints.MinWidth = 240
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
    inherited Splitter: TSplitter
      Left = 474
    end
    inherited tbxSearchBox: TButtonedEditEx
      Width = 474
    end
    inherited cbxColumn: TComboBox
      Left = 480
    end
  end
end
