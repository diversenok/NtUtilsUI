object FrameIntegrity: TFrameIntegrity
  Left = 0
  Top = 0
  Width = 268
  Height = 110
  Constraints.MinHeight = 110
  Constraints.MinWidth = 200
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object lblUntrusted: TLabel
    Left = 0
    Top = 91
    Width = 48
    Height = 13
    Caption = 'Untrusted'
  end
  object lblSystem: TLabel
    Left = 233
    Top = 91
    Width = 35
    Height = 13
    Alignment = taRightJustify
    Anchors = [akTop, akRight]
    Caption = 'System'
  end
  object lblMedium: TLabel
    Left = 116
    Top = 91
    Width = 36
    Height = 13
    Alignment = taCenter
    Anchors = [akTop]
    Caption = 'Medium'
  end
  object lblHigh: TLabel
    Left = 186
    Top = 31
    Width = 21
    Height = 13
    Alignment = taCenter
    Anchors = [akTop]
    Caption = 'High'
  end
  object lblLow: TLabel
    Left = 64
    Top = 31
    Width = 19
    Height = 13
    Alignment = taCenter
    Anchors = [akTop]
    Caption = 'Low'
  end
  object ComboBox: TComboBox
    Left = 0
    Top = 0
    Width = 268
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    ItemIndex = 2
    TabOrder = 1
    Text = 'Medium (0x2000)'
    OnChange = ComboBoxChange
    Items.Strings = (
      'Untrusted (0x0000)'
      'Low (0x1000)'
      'Medium (0x2000)'
      'Medium Plus (0x2100)'
      'High (0x3000)'
      'System (0x4000)'
      'Protected (0x5000)')
  end
  object TrackBar: TTrackBar
    Left = 0
    Top = 50
    Width = 268
    Height = 35
    Anchors = [akLeft, akTop, akRight]
    LineSize = 512
    Max = 16384
    PageSize = 4096
    Frequency = 4096
    Position = 8192
    ShowSelRange = False
    TabOrder = 0
    TickMarks = tmBoth
    OnChange = TrackBarChange
  end
end
