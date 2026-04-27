object AppContainerListFrame: TAppContainerListFrame
  Left = 0
  Top = 0
  Width = 600
  Height = 407
  Constraints.MinHeight = 150
  Constraints.MinWidth = 300
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object SearchBox: TUiLibTreeSearchBox
    Left = 0
    Top = 0
    Width = 600
    Height = 21
    Align = alTop
    TabOrder = 1
  end
  object Tree: TUiLibTree
    AlignWithMargins = True
    Left = 0
    Top = 26
    Width = 600
    Height = 381
    Margins.Left = 0
    Margins.Top = 5
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    EmptyListMessage = 'No items to display'
    Header.AutoSizeIndex = 0
    TabOrder = 0
    TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toShowTreeLines, toThemeAware, toUseBlendedImages, toUseExplorerTheme]
    OnNodeDblClick = TreeNodeDblClick
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 0
        Text = 'Friendly Name'
        Width = 260
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 1
        Text = 'Display Name'
        Width = 340
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 2
        Text = 'Moniker'
        Width = 220
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus, coEditable, coStyleColor]
        Position = 3
        Text = 'Package'
        Width = 80
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 4
        Text = 'SID'
        Width = 400
      end>
  end
  object PopupMenu: TPopupMenu
    Left = 72
    Top = 112
    object cmInspect: TMenuItem
      Caption = 'Inspect...'
      Default = True
      ShortCut = 13
      OnClick = cmInspectClick
    end
  end
end
