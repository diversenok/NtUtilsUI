inherited AceConditionFrame: TAceConditionFrame
  Width = 600
  Height = 25
  Constraints.MinHeight = 25
  Constraints.MinWidth = 200
  ParentShowHint = False
  ShowHint = True
  object tbxCondition: TEdit
    AlignWithMargins = True
    Left = 0
    Top = 2
    Width = 571
    Height = 21
    Margins.Left = 0
    Margins.Top = 2
    Margins.Right = 0
    Margins.Bottom = 2
    Align = alClient
    TabOrder = 0
    TextHint = 
      'Example: (Exists WIN://NOALLAPPPKG) || (APPID://PATH Contains "%' +
      'WINDIR%\*")'
    OnChange = tbxConditionChange
  end
  object btnNormalize: TButton
    AlignWithMargins = True
    Left = 575
    Top = 0
    Width = 25
    Height = 25
    Hint = 'Normalize the condition'
    Margins.Left = 4
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alRight
    ImageAlignment = iaCenter
    TabOrder = 1
    OnClick = btnNormalizeClick
  end
end
