object FrameTrustSid: TFrameTrustSid
  Left = 0
  Top = 0
  Width = 400
  Height = 185
  Constraints.MinHeight = 185
  Constraints.MinWidth = 330
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object lblNoneType: TLabel
    Left = 3
    Top = 27
    Width = 25
    Height = 13
    Caption = 'None'
  end
  object lblLight: TLabel
    Left = 190
    Top = 27
    Width = 23
    Height = 13
    Alignment = taCenter
    Anchors = [akTop]
    Caption = 'Light'
  end
  object lblFull: TLabel
    Left = 381
    Top = 27
    Width = 16
    Height = 13
    Alignment = taRightJustify
    Anchors = [akTop, akRight]
    Caption = 'Full'
  end
  object lblNoneLevel: TLabel
    Left = 3
    Top = 167
    Width = 25
    Height = 13
    Caption = 'None'
  end
  object lblAntimalware: TLabel
    Left = 53
    Top = 167
    Width = 59
    Height = 13
    Anchors = [akTop]
    Caption = 'Antimalware'
  end
  object lblWindows: TLabel
    Left = 180
    Top = 167
    Width = 43
    Height = 13
    Alignment = taCenter
    Anchors = [akTop]
    Caption = 'Windows'
  end
  object lblWinTcb: TLabel
    Left = 360
    Top = 167
    Width = 37
    Height = 13
    Anchors = [akTop, akRight]
    Caption = 'WinTCB'
  end
  object TrackBarType: TTrackBar
    Left = 0
    Top = 47
    Width = 400
    Height = 35
    Anchors = [akLeft, akTop, akRight]
    LineSize = 128
    Max = 1024
    PageSize = 512
    Frequency = 512
    Position = 512
    ShowSelRange = False
    TabOrder = 0
    TickMarks = tmBoth
    OnChange = TrackBarTypeChange
  end
  object TrackBarLevel: TTrackBar
    Left = 0
    Top = 126
    Width = 400
    Height = 35
    Anchors = [akLeft, akTop, akRight]
    LineSize = 256
    Max = 8192
    PageSize = 512
    Frequency = 512
    Position = 1536
    ShowSelRange = False
    TabOrder = 1
    TickMarks = tmBoth
    OnChange = TrackBarLevelChange
  end
  object cbxType: TComboBox
    Left = 0
    Top = 0
    Width = 400
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    ItemIndex = 1
    TabOrder = 2
    Text = 'Light (0x200)'
    OnChange = cbxTypeChange
    Items.Strings = (
      'None (0x000)'
      'Light (0x200)'
      'Full (0x400)')
  end
  object cbxLevel: TComboBox
    Left = 0
    Top = 99
    Width = 400
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    ItemIndex = 2
    TabOrder = 3
    Text = 'Antimalware (0x0600)'
    OnChange = cbxLevelChange
    Items.Strings = (
      'None (0x0000)'
      'Authenticode (0x0400)'
      'Antimalware (0x0600)'
      'Store App (0x0800)'
      'Windows (0x1000)'
      'WinTcb (0x2000)')
  end
end
