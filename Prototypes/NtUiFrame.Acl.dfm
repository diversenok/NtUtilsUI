inherited AclFrame: TAclFrame
  Width = 785
  Height = 265
  Constraints.MinHeight = 145
  ParentShowHint = False
  ShowHint = True
  object Tree: TDevirtualizedTree
    Left = 0
    Top = 24
    Width = 757
    Height = 241
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
        Width = 100
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
        Text = 'Access'
        Width = 200
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 3
        Text = 'Access (numeric)'
        Width = 100
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 4
        Text = 'SID'
        Width = 220
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 5
        Text = 'SID (raw)'
        Width = 280
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 6
        Text = 'Server SID'
        Width = 220
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 7
        Text = 'Server SID (raw)'
        Width = 280
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 8
        Text = 'Condition'
        Width = 180
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 9
        Text = 'Flags'
        Width = 200
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
    Left = 760
    Top = 24
    Width = 25
    Height = 241
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alRight
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    object btnAdd: TButton
      Left = 0
      Top = 58
      Width = 25
      Height = 25
      Hint = 'Add a new ACE (Ctrl+N)'
      Anchors = [akRight]
      ImageAlignment = iaCenter
      TabOrder = 1
      OnClick = btnAddClick
    end
    object btnCanonicalize: TButton
      Left = 0
      Top = 108
      Width = 25
      Height = 25
      Hint = 'Canonicalize/normalize the ACL (Ctrl+Shift+N)'
      Anchors = [akRight]
      Enabled = False
      ImageAlignment = iaCenter
      TabOrder = 2
      OnClick = btnCanonicalizeClick
    end
    object btnDelete: TButton
      Left = 0
      Top = 157
      Width = 25
      Height = 25
      Hint = 'Delete selected items'
      Anchors = [akRight]
      Enabled = False
      ImageAlignment = iaCenter
      TabOrder = 3
      OnClick = btnDeleteClick
    end
    object btnDown: TButton
      Left = 0
      Top = 216
      Width = 25
      Height = 25
      Hint = 'Move selected items down'
      Anchors = [akRight, akBottom]
      Enabled = False
      ImageAlignment = iaCenter
      TabOrder = 4
      OnClick = btnDownClick
    end
    object btnUp: TButton
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
    end
  end
  inline Search: TSearchFrame
    AlignWithMargins = True
    Left = 0
    Top = 0
    Width = 785
    Height = 21
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Align = alTop
    Constraints.MinHeight = 21
    Constraints.MinWidth = 240
    TabOrder = 2
    inherited Splitter: TSplitter
      Left = 619
    end
    inherited tbxSearchBox: TButtonedEdit
      Width = 619
    end
    inherited cbxColumn: TComboBox
      Left = 625
    end
  end
  object PopupMenu: TPopupMenu
    Left = 232
    Top = 88
    object cmEdit: TMenuItem
      Caption = 'Edit...'
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
  object ActionList: TActionList
    Left = 152
    Top = 88
    object alxNew: TAction
      ShortCut = 16462
      OnExecute = btnAddClick
    end
    object alxCanonicalize: TAction
      ShortCut = 24654
      OnExecute = btnCanonicalizeClick
    end
    object alxEdit: TAction
      ShortCut = 16453
      OnExecute = cmEditClick
    end
  end
end
