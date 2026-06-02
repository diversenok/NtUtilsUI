object UiLibProcesses: TUiLibProcesses
  Left = 0
  Top = 0
  Width = 550
  Height = 550
  Constraints.MinHeight = 240
  Constraints.MinWidth = 300
  TabOrder = 0
  object LabelMethod: TLabel
    Left = 3
    Top = 30
    Width = 45
    Height = 15
    Caption = 'Method:'
  end
  object LabelSession: TLabel
    Left = 3
    Top = 59
    Width = 45
    Height = 15
    Caption = 'Session: '
  end
  object LabelCount: TLabel
    Left = 3
    Top = 532
    Width = 67
    Height = 15
    Anchors = [akLeft, akBottom]
    Caption = 'Displaying: 0'
  end
  object LabelTotal: TLabel
    Left = 231
    Top = 532
    Width = 90
    Height = 15
    Alignment = taCenter
    Anchors = [akBottom]
    Caption = 'Total: (unknown)'
  end
  object LabelPeak: TLabel
    Left = 456
    Top = 532
    Width = 89
    Height = 15
    Alignment = taRightJustify
    Anchors = [akRight, akBottom]
    Caption = 'Peak: (unknown)'
  end
  object ComboBoxMethod: TComboBox
    Left = 64
    Top = 27
    Width = 486
    Height = 22
    Style = csOwnerDrawFixed
    Anchors = [akLeft, akTop, akRight]
    ItemIndex = 0
    TabOrder = 2
    Text = 'Basic (SystemProcessInformation)'
    OnChange = ComboBoxMethodChange
    Items.Strings = (
      'Basic (SystemProcessInformation)'
      'Extended (SystemExtendedProcessInformation)'
      'Full (SystemFullProcessInformation)'
      'Per-session (SystemSessionProcessInformation)'
      'Accessible (NtGetNextProcess)'
      'Ntdll usage (FileProcessIdsUsingFileInformation)'
      'Brute-force (SystemProcessIdInformation)')
  end
  object SessionIdBox: TUiLibSessionIdBox
    Left = 64
    Top = 55
    Width = 486
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    Enabled = False
    TabOrder = 3
    OnChange = SessionIdBoxChange
  end
  object SearchBox: TUiLibTreeSearchBox
    Left = 0
    Top = 0
    Width = 550
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
  end
  object Tree: TUiLibTree
    Left = 0
    Top = 80
    Width = 550
    Height = 448
    Alignment = taCenter
    Anchors = [akLeft, akTop, akRight, akBottom]
    EmptyListMessage = 'No items to display'
    Header.AutoSizeIndex = 0
    Header.TriStateAutoSort = True
    TabOrder = 0
    TreeOptions.PaintOptions = [toHideFocusRect, toHotTrack, toShowButtons, toShowDropmark, toShowTreeLines, toThemeAware, toUseBlendedImages, toUseExplorerTheme]
    OnChange = TreeChange
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    OnMainAction = TreeMainAction
    OnSortChange = TreeSortChange
    Columns = <
      item
        MinWidth = 50
        Position = 0
        Text = 'Image Name'
        Width = 400
      end
      item
        Alignment = taRightJustify
        MinWidth = 40
        Position = 1
        Text = 'PID'
        Width = 60
      end
      item
        Alignment = taRightJustify
        MinWidth = 40
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus, coEditable, coStyleColor]
        Position = 2
        Text = 'PID (hex)'
        Width = 60
      end
      item
        MinWidth = 50
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus, coEditable, coStyleColor]
        Position = 3
        Text = 'Image Path'
        Width = 800
      end>
  end
  object RefreshTimer: TTimer
    OnTimer = RefreshTimerTimer
    Left = 368
    Top = 176
  end
end
