object AclFrame: TAclFrame
  Left = 0
  Top = 0
  Width = 620
  Height = 230
  Constraints.MinHeight = 165
  Constraints.MinWidth = 320
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object Tree: TDevirtualizedTree
    Left = 0
    Top = 25
    Width = 592
    Height = 205
    AccessibleName = 'PopupMenu'
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
    TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toThemeAware, toUseBlendedImages, toUseExplorerTheme]
    TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect, toRightClickSelect]
    OnAddToSelection = SelectionChanged
    OnDblClick = cmEditClick
    OnGetPopupMenu = TreeGetPopupMenu
    OnRemoveFromSelection = SelectionChanged
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    PopupMenuEx = PopupMenu
    NoItemsText = 'No items to display'
    Columns = <
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 0
        Text = 'Use'
        Width = 110
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 1
        Text = 'ACE Type'
        Width = 200
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 2
        Text = 'SID'
        Width = 220
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 3
        Text = 'SID (raw)'
        Width = 280
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 4
        Text = 'Server SID'
        Width = 220
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 5
        Text = 'Server SID (raw)'
        Width = 280
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 6
        Text = 'Condition'
        Width = 180
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 7
        Text = 'Access'
        Width = 230
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 8
        Text = 'Access (numeric)'
        Width = 100
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 9
        Text = 'Flags'
        Width = 220
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 10
        Text = 'Object Type'
        Width = 240
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 11
        Text = 'Inherited Object Type'
        Width = 240
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 12
        Text = 'SDDL'
        Width = 200
      end>
  end
  object RightPanel: TPanel
    AlignWithMargins = True
    Left = 595
    Top = 25
    Width = 25
    Height = 205
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alRight
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    object btnAdd: TUiLibButton
      Left = 0
      Top = 48
      Width = 25
      Height = 25
      Hint = 'Add a new ACE (Ctrl+N)'
      Anchors = [akRight]
      ImageAlignment = iaCenter
      TabOrder = 1
      OnClick = btnAddClick
      ImageResource = 'Resources.Icon.Add'
    end
    object btnCanonicalize: TUiLibButton
      Left = 0
      Top = 90
      Width = 25
      Height = 25
      Hint = 'Canonicalize/normalize the ACL (Ctrl+Shift+N)'
      Anchors = [akRight]
      Enabled = False
      ImageAlignment = iaCenter
      TabOrder = 2
      OnClick = btnCanonicalizeClick
      ImageResource = 'Resources.Icon.Verify'
    end
    object btnDelete: TUiLibButton
      Left = 0
      Top = 132
      Width = 25
      Height = 25
      Hint = 'Delete selected items'
      Anchors = [akRight]
      Enabled = False
      ImageAlignment = iaCenter
      TabOrder = 3
      OnClick = btnDeleteClick
      ImageResource = 'Resources.Icon.Delete'
    end
    object btnDown: TUiLibButton
      Left = 0
      Top = 180
      Width = 25
      Height = 25
      Hint = 'Move selected items down'
      Anchors = [akRight, akBottom]
      Enabled = False
      ImageAlignment = iaCenter
      TabOrder = 4
      OnClick = btnDownClick
      ImageResource = 'Resources.Icon.Down'
    end
    object btnUp: TUiLibButton
      Left = 0
      Top = 0
      Width = 25
      Height = 25
      Hint = 'Move selected items up'
      Anchors = [akTop, akRight]
      Enabled = False
      ImageAlignment = iaCenter
      TabOrder = 0
      OnClick = btnUpClick
      ImageResource = 'Resources.Icon.Up'
    end
  end
  inline Search: TSearchFrame
    AlignWithMargins = True
    Left = 0
    Top = 0
    Width = 620
    Height = 21
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 4
    Align = alTop
    Constraints.MinHeight = 21
    Constraints.MinWidth = 240
    DoubleBuffered = True
    ParentDoubleBuffered = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    inherited Splitter: TSplitter
      Left = 454
      Height = 21
    end
    inherited SearchBox: TUiLibSearchBox
      Width = 454
      Height = 21
    end
    inherited cbxColumn: TComboBox
      Left = 460
    end
  end
  object PopupMenu: TPopupMenu
    Left = 232
    Top = 88
    object cmEdit: TMenuItem
      Caption = 'Edit...'
      Default = True
      ShortCut = 113
      OnClick = cmEditClick
    end
    object cmDelete: TMenuItem
      Caption = 'Delete'
      ShortCut = 46
      OnClick = btnDeleteClick
    end
    object cmUp: TMenuItem
      Caption = 'Move Up'
      ShortCut = 32806
      OnClick = btnUpClick
    end
    object cmDown: TMenuItem
      Caption = 'Move Down'
      ShortCut = 32808
      OnClick = btnDownClick
    end
  end
end
