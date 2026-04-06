inherited SidEditor: TSidEditor
  Width = 600
  Height = 25
  Anchors = [akLeft, akTop, akRight]
  ExplicitWidth = 600
  ExplicitHeight = 25
  object tbxSid: TEdit
    AlignWithMargins = True
    Left = 0
    Top = 2
    Width = 513
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
  object btnDsPicker: TUiLibButton
    AlignWithMargins = True
    Left = 575
    Top = 0
    Width = 25
    Height = 25
    Hint = 'Use the built-in dialog for selecting accounts'
    Margins.Left = 4
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alRight
    ImageAlignment = iaCenter
    ImageMargins.Left = 2
    TabOrder = 3
    OnClick = btnDsPickerClick
    ImageResource = 'Resources.Icon.UserPicker'
  end
  object btnCheatsheet: TUiLibButton
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
    TabOrder = 2
    OnClick = btnCheatsheetClick
    ImageResource = 'Resources.Icon.Catalogue'
  end
  object btnChoice: TUiLibButton
    AlignWithMargins = True
    Left = 517
    Top = 0
    Width = 25
    Height = 25
    Margins.Left = 4
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alRight
    ImageAlignment = iaCenter
    TabOrder = 1
    Visible = False
    OnClick = btnChoiceClick
    ImageResource = 'Resources.Icon.Choose'
  end
end
