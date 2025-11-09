inherited SearchFrame: TSearchFrame
  Left = 0
  Top = 0
  Width = 436
  Height = 23
  Anchors = [akLeft, akTop, akRight]
  Constraints.MinHeight = 21
  Constraints.MinWidth = 240
  TabOrder = 0
  DoubleBuffered = True
  ParentDoubleBuffered = False
  object Splitter: TSplitter
    Left = 270
    Top = 0
    Width = 6
    Height = 23
    Align = alRight
    AutoSnap = False
    MinSize = 110
    ResizeStyle = rsUpdate
  end
  object tbxSearchBox: TButtonedEditEx
    Left = 0
    Top = 0
    Width = 270
    Height = 23
    Align = alClient
    TabOrder = 0
    TextHint = 'Search'
    OnKeyDown = tbxSearchBoxKeyDown
    OnKeyPress = tbxSearchBoxKeyPress
    OnRightButtonClick = tbxSearchBoxRightButtonClick
    OnDelayedChange = tbxSearchBoxChange
    OnTypingChange = tbxSearchBoxTypingChange
  end
  object cbxColumn: TComboBox
    Left = 276
    Top = 0
    Width = 160
    Height = 23
    Align = alRight
    Style = csDropDownList
    ExtendedUI = True
    ItemIndex = 0
    TabOrder = 1
    Text = 'All visible columns'
    OnChange = cbxColumnChange
    Items.Strings = (
      'All visible columns')
  end
  object ActionList: TActionList
    Left = 168
    object ActionSetFocus: TAction
      ShortCut = 16454
      OnExecute = ActionSetFocusExecute
    end
  end
end
