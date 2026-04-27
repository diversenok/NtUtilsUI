object CapabilityListFrame: TCapabilityListFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 480
  TabOrder = 0
  object SearchBox: TUiLibTreeSearchBox
    Left = 0
    Top = 0
    Width = 640
    Height = 21
    Align = alTop
    TabOrder = 1
  end
  object Tree: TUiLibTree
    AlignWithMargins = True
    Left = 0
    Top = 26
    Width = 640
    Height = 454
    Margins.Left = 0
    Margins.Top = 5
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    EmptyListMessage = 'Not initialized'
    Header.AutoSizeIndex = 0
    TabOrder = 0
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toCheckSupport, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning]
    TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toShowTreeLines, toThemeAware, toUseBlendedImages, toUseExplorerTheme]
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 0
        Text = 'Name'
        Width = 300
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 1
        Text = 'Capability SID'
        Width = 300
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 2
        Text = 'Group Capability SID'
        Width = 300
      end>
  end
end
