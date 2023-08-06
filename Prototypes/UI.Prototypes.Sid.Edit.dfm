inherited SidEditor: TSidEditor
  Width = 600
  Height = 25
  Anchors = [akLeft, akTop, akRight]
  ParentShowHint = False
  ShowHint = True
  object tbxSid: TEdit
    AlignWithMargins = True
    Left = 0
    Top = 2
    Width = 542
    Height = 21
    Hint = 'Enter SID or press DOWN to show suggestions'
    Margins.Left = 0
    Margins.Top = 2
    Margins.Right = 0
    Margins.Bottom = 2
    Align = alClient
    TabOrder = 0
    TextHint = 'Enter SID or press DOWN to show suggestions'
    OnChange = tbxSidChange
    OnEnter = tbxSidEnter
  end
  object btnDsPicker: TButton
    AlignWithMargins = True
    Left = 575
    Top = 0
    Width = 25
    Height = 25
    Hint = 'Use the built-in dialog for slecting accounts'
    Margins.Left = 4
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alRight
    ImageAlignment = iaCenter
    ImageMargins.Left = 2
    TabOrder = 2
    OnClick = btnDsPickerClick
  end
  object btnCheatsheet: TButton
    AlignWithMargins = True
    Left = 546
    Top = 0
    Width = 25
    Height = 25
    Hint = 'Show SID abbreviation cheatsheet'
    Margins.Left = 4
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alRight
    ImageAlignment = iaCenter
    TabOrder = 1
    OnClick = btnCheatsheetClick
  end
end
