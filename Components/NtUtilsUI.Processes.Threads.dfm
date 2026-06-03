object UiLibThreads: TUiLibThreads
  Left = 0
  Top = 0
  Width = 470
  Height = 550
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
    Left = 191
    Top = 532
    Width = 90
    Height = 15
    Alignment = taCenter
    Anchors = [akBottom]
    Caption = 'Total: (unknown)'
  end
  object LabelPeak: TLabel
    Left = 376
    Top = 532
    Width = 89
    Height = 15
    Alignment = taRightJustify
    Anchors = [akRight, akBottom]
    Caption = 'Peak: (unknown)'
  end
  object SearchBox: TUiLibTreeSearchBox
    Left = 0
    Top = 0
    Width = 470
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
  end
  object ComboBoxMethod: TComboBox
    Left = 64
    Top = 27
    Width = 406
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
      'Accessible (NtGetNextThread)'
      'Brute-force (NtOpenThread)')
  end
  object SessionIdBox: TUiLibSessionIdBox
    Left = 64
    Top = 55
    Width = 406
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    Enabled = False
    TabOrder = 3
    OnChange = SessionIdBoxChange
  end
  object Tree: TUiLibTree
    Left = 0
    Top = 80
    Width = 470
    Height = 448
    Alignment = taCenter
    Anchors = [akLeft, akTop, akRight, akBottom]
    Constraints.MinHeight = 240
    EmptyListMessage = 'No items to display'
    Header.AutoSizeIndex = 0
    PopupMenu = PopupMenu
    TabOrder = 0
    OnChange = TreeChange
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <
      item
        Position = 0
        Text = 'Thread name'
        Width = 150
      end
      item
        Alignment = taRightJustify
        Position = 1
        Text = 'TID'
        Width = 60
      end
      item
        Alignment = taRightJustify
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus, coEditable, coStyleColor]
        Position = 2
        Text = 'TID (hex)'
        Width = 60
      end
      item
        Position = 3
        Text = 'Creation time'
        Width = 130
      end
      item
        Position = 4
        Text = 'Wait reason'
        Width = 100
      end
      item
        Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coShowDropMark, coAllowFocus, coEditable, coStyleColor]
        Position = 5
        Text = 'Suspend count'
        Width = 90
      end>
  end
  object RefreshTimer: TTimer
    OnTimer = RefreshTimerTimer
    Left = 368
    Top = 176
  end
  object PopupMenu: TPopupMenu
    OnPopup = PopupMenuPopup
    Left = 64
    Top = 216
    object cmTerminate: TMenuItem
      Caption = 'Terminate'
      ShortCut = 46
      OnClick = cmTerminateClick
    end
    object cmSuspend: TMenuItem
      Caption = 'Suspend'
      OnClick = cmSuspendClick
    end
    object cmResume: TMenuItem
      Caption = 'Resume'
      OnClick = cmResumeClick
    end
    object cmAlert: TMenuItem
      Caption = 'Alert'
      OnClick = cmAlertClick
    end
    object cmAlertResume: TMenuItem
      Caption = 'Alert && Resume'
      OnClick = cmAlertResumeClick
    end
    object cmCancelO: TMenuItem
      Caption = 'Cancel I/O'
      OnClick = cmCancelOClick
    end
  end
end
