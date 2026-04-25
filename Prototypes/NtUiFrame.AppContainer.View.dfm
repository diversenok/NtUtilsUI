object AppContainerViewFrame: TAppContainerViewFrame
  Left = 0
  Top = 0
  Width = 620
  Height = 200
  Constraints.MinHeight = 200
  Constraints.MinWidth = 300
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object Tree: TDevirtualizedTree
    Left = 0
    Top = 0
    Width = 620
    Height = 200
    Align = alClient
    ClipboardFormats.Strings = (
      'CSV'
      'Plain text'
      'Unicode text')
    EmptyListMessage = ''
    Header.AutoSizeIndex = 1
    Header.MainColumn = 1
    Header.Options = [hoAutoResize, hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack, hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize, hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption]
    HintMode = hmTooltip
    TabOrder = 0
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 0
        Text = 'Property'
        Width = 120
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 1
        Text = 'Value'
        Width = 496
      end>
  end
end
