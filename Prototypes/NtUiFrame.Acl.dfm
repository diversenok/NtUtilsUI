inherited AclFrame: TAclFrame
  Width = 785
  Height = 265
  Constraints.MinHeight = 145
  ParentShowHint = False
  ShowHint = True
  object Tree: TDevirtualizedTree
    AlignWithMargins = True
    Left = 0
    Top = 0
    Width = 757
    Height = 265
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 28
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
    TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toThemeAware, toUseBlendedImages, toUseExplorerTheme]
    TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect, toRightClickSelect]
    OnAddToSelection = SelectionChanged
    OnRemoveFromSelection = SelectionChanged
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
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
  object btnUp: TButton
    Left = 760
    Top = 0
    Width = 25
    Height = 25
    Hint = 'Move selected items up'
    Anchors = [akTop, akRight]
    Enabled = False
    ImageAlignment = iaCenter
    TabOrder = 1
    OnClick = btnUpClick
  end
  object btnDown: TButton
    Left = 760
    Top = 240
    Width = 25
    Height = 25
    Hint = 'Move selected items down'
    Anchors = [akRight, akBottom]
    Enabled = False
    ImageAlignment = iaCenter
    TabOrder = 2
    OnClick = btnDownClick
  end
  object btnCanonicalize: TButton
    Left = 760
    Top = 120
    Width = 25
    Height = 25
    Hint = 'Canonicalize ACL'
    Anchors = [akRight]
    Enabled = False
    ImageAlignment = iaCenter
    TabOrder = 3
    OnClick = btnCanonicalizeClick
  end
  object btnAdd: TButton
    Left = 760
    Top = 65
    Width = 25
    Height = 25
    Hint = 'Add a new ACE'
    Anchors = [akRight]
    ImageAlignment = iaCenter
    TabOrder = 4
  end
  object btnDelete: TButton
    Left = 760
    Top = 174
    Width = 25
    Height = 25
    Hint = 'Delete selected items'
    Anchors = [akRight]
    Enabled = False
    ImageAlignment = iaCenter
    TabOrder = 5
    OnClick = btnDeleteClick
  end
end
