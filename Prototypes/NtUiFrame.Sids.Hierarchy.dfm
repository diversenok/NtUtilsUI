object SidHierarchyFrame: TSidHierarchyFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 400
  Constraints.MinHeight = 120
  Constraints.MinWidth = 300
  TabOrder = 0
  object Tree: TUiLibTree
    AlignWithMargins = True
    Left = 0
    Top = 24
    Width = 640
    Height = 376
    Margins.Left = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    EmptyListMessage = 'Not initialized'
    Header.AutoSizeIndex = 0
    Header.Options = [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack, hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize, hoAutoColumnPopupMenu, hoAutoResizeInclCaption]
    TabOrder = 0
    TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toShowRoot, toShowTreeLines, toThemeAware, toUseBlendedImages, toUseExplorerTheme]
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
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
  object SearchBox: TUiLibTreeSearchBox
    Left = 0
    Top = 0
    Width = 640
    Height = 21
    Align = alTop
    TabOrder = 1
  end
end
