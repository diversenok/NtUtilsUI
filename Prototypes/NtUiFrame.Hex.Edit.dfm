object HexEditFrame: THexEditFrame
  Left = 0
  Top = 0
  Width = 600
  Height = 25
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object tbxHexString: TEdit
    AlignWithMargins = True
    Left = 0
    Top = 2
    Width = 600
    Height = 21
    Margins.Left = 0
    Margins.Top = 2
    Margins.Right = 0
    Margins.Bottom = 2
    Align = alClient
    TabOrder = 0
    TextHint = 'Binary data as hex: 00 80 FF ...'
    OnChange = tbxHexStringChange
    OnExit = tbxHexStringExit
  end
end
