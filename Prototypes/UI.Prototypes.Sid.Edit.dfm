object SidEditor: TSidEditor
  Left = 0
  Top = 0
  Width = 600
  Height = 27
  Anchors = [akLeft, akTop, akRight]
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object tbxSid: TEdit
    Left = 3
    Top = 3
    Width = 537
    Height = 21
    Hint = 'Start typing or press DOWN to show suggestions'
    Anchors = [akLeft, akRight]
    TabOrder = 0
    TextHint = 'Start typing or press DOWN to show suggestions'
    OnChange = tbxSidChange
  end
  object btnDsPicker: TButton
    Left = 572
    Top = 1
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
    Left = 544
    Top = 1
    Width = 25
    Height = 25
    Hint = 'Show SID abbreviation cheatsheet'
    Anchors = [akRight]
    ImageAlignment = iaCenter
    TabOrder = 1
    OnClick = btnCheatsheetClick
  end
end
