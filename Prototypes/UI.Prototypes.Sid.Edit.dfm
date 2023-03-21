object SidEditor: TSidEditor
  Left = 0
  Top = 0
  Width = 600
  Height = 25
  Anchors = [akLeft, akTop, akRight]
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object tbxSid: TEdit
    Left = 0
    Top = 2
    Width = 543
    Height = 21
    Hint = 'Start typing or press DOWN to show suggestions'
    Anchors = [akLeft, akRight]
    TabOrder = 0
    TextHint = 'Start typing or press DOWN to show suggestions'
    OnChange = tbxSidChange
    OnEnter = tbxSidEnter
  end
  object btnDsPicker: TButton
    Left = 575
    Top = 0
    Width = 25
    Height = 25
    Hint = 'Use builtin account selection dialog'
    Anchors = [akRight]
    ImageAlignment = iaCenter
    ImageMargins.Left = 2
    TabOrder = 2
    OnClick = btnDsPickerClick
  end
  object btnCheatsheet: TButton
    Left = 547
    Top = 0
    Width = 25
    Height = 25
    Hint = 'Show SID abbreviation cheatsheet'
    Anchors = [akRight]
    ImageAlignment = iaCenter
    TabOrder = 1
    OnClick = btnCheatsheetClick
  end
end
