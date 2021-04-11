object FrameGroups: TFrameGroups
  Left = 0
  Top = 0
  Width = 493
  Height = 304
  DoubleBuffered = True
  ParentDoubleBuffered = False
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object VST: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 493
    Height = 304
    Align = alClient
    ClipboardFormats.Strings = (
      'CSV'
      'Plain text'
      'Unicode text')
    DrawSelectionMode = smBlendedRectangle
    Header.AutoSizeIndex = 0
    Header.DefaultHeight = 24
    Header.Height = 24
    Header.Options = [hoColumnResize, hoDblClickResize, hoDrag, hoHotTrack, hoRestrictDrag, hoShowSortGlyphs, hoVisible, hoDisableAnimatedResize, hoHeaderClickAutoSort, hoAutoColumnPopupMenu, hoAutoResizeInclCaption]
    HintMode = hmHint
    SelectionBlendFactor = 64
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoTristateTracking, toAutoDeleteMovedNodes, toAutoChangeScale]
    TreeOptions.ExportMode = emSelected
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning]
    TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toThemeAware, toUseBlendedImages, toUseExplorerTheme]
    TreeOptions.SelectionOptions = [toFullRowSelect, toMultiSelect, toRightClickSelect]
    OnBeforeItemErase = VSTBeforeItemErase
    OnCompareNodes = VSTCompareNodes
    OnDblClick = cmInspectClick
    OnFreeNode = VSTFreeNode
    OnGetCellText = VSTGetCellText
    OnGetHint = VSTGetHint
    OnGetPopupMenu = VSTGetPopupMenu
    OnInitNode = VSTInitNode
    OnKeyDown = VSTKeyDown
    Columns = <
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 0
        Text = 'Friendly Name'
        Width = 220
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 1
        Text = 'SID'
        Width = 280
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 2
        Text = 'SID Type'
        Width = 110
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 3
        Text = 'State'
        Width = 100
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
        Position = 4
        Text = 'Flags'
        Width = 120
      end>
  end
  object DefaultPopupMenu: TPopupMenu
    Left = 96
    Top = 104
    object cmInspect: TMenuItem
      Caption = 'Inspect'
      Default = True
      ShortCut = 13
      Visible = False
      OnClick = cmInspectClick
    end
    object cmSeparator: TMenuItem
      Caption = '-'
      Visible = False
    end
    object cmCopy: TMenuItem
      Caption = 'Copy'
      ShortCut = 16451
      OnClick = cmCopyClick
    end
    object cmCopyColumn: TMenuItem
      Caption = 'Copy "%s"'
      OnClick = cmCopyColumnClick
    end
  end
end
