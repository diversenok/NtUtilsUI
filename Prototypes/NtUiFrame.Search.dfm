object SearchFrame: TSearchFrame
  Left = 0
  Top = 0
  Width = 436
  Height = 21
  Anchors = [akLeft, akTop, akRight]
  Constraints.MinHeight = 21
  Constraints.MinWidth = 240
  TabOrder = 0
  object Splitter: TSplitter
    Left = 270
    Top = 0
    Width = 6
    Height = 21
    Align = alRight
    AutoSnap = False
    MinSize = 110
    ResizeStyle = rsUpdate
  end
  object tbxSearchBox: TButtonedEdit
    Left = 0
    Top = 0
    Width = 270
    Height = 21
    Align = alClient
    TabOrder = 0
    TextHint = 'Search'
    OnChange = tbxSearchBoxChange
    OnKeyDown = tbxSearchBoxKeyDown
    OnKeyPress = tbxSearchBoxKeyPress
    OnRightButtonClick = tbxSearchBoxRightButtonClick
  end
  object cbxColumn: TComboBox
    Left = 276
    Top = 0
    Width = 160
    Height = 21
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
end
