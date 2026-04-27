object UserProfilesFrame: TUserProfilesFrame
  Left = 0
  Top = 0
  Width = 700
  Height = 250
  Constraints.MinHeight = 180
  Constraints.MinWidth = 370
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object Tree: TUiLibTree
    Left = 0
    Top = 26
    Width = 700
    Height = 224
    Align = alClient
    EmptyListMessage = ''
    Header.AutoSizeIndex = 0
    TabOrder = 0
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 0
        Text = 'User Name'
        Width = 200
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 1
        Text = 'SID'
        Width = 240
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 2
        Text = 'Profile Path'
        Width = 240
      end
      item
        Alignment = taCenter
        CaptionAlignment = taCenter
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coUseCaptionAlignment, coEditable, coStyleColor]
        Position = 3
        Text = 'Full Profile'
        Width = 70
      end
      item
        Alignment = taCenter
        CaptionAlignment = taCenter
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coUseCaptionAlignment, coEditable, coStyleColor]
        Position = 4
        Text = 'Loaded'
        Width = 70
      end>
  end
  object SearchBox: TUiLibTreeSearchBox
    AlignWithMargins = True
    Left = 0
    Top = 0
    Width = 700
    Height = 21
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 5
    Align = alTop
    TabOrder = 1
  end
end
