object FramePages: TFramePages
  Left = 0
  Top = 0
  Width = 320
  Height = 240
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 320
    Height = 240
    Align = alClient
    MultiLine = True
    TabOrder = 0
    OnChange = PageControlChange
  end
  object ActionList: TActionList
    Left = 112
    Top = 96
  end
end
