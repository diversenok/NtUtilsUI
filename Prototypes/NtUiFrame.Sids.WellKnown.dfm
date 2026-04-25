object WellKnownSidsFrame: TWellKnownSidsFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 400
  Constraints.MinHeight = 120
  Constraints.MinWidth = 300
  TabOrder = 0
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
    EmptyListMessage = 'Unable to enumerate'
    Header.AutoSizeIndex = 0
    Header.MainColumn = 1
    TabOrder = 0
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 0
        Text = 'Index'
        Width = 46
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 1
        Text = 'Enum Name'
        Width = 200
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 2
        Text = 'Friendly Name'
        Width = 250
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 3
        Text = 'SID'
        Width = 110
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 4
        Text = 'SID Type'
        Width = 110
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
