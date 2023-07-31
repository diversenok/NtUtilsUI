object OwnerGroupSecurityFrame: TOwnerGroupSecurityFrame
  Left = 0
  Top = 0
  Width = 600
  Height = 77
  Constraints.MinHeight = 77
  Constraints.MinWidth = 260
  TabOrder = 0
  inline SidEditor: TSidEditor
    Left = 0
    Top = 0
    Width = 600
    Height = 25
    Align = alTop
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
  end
  object GroupBox: TGroupBox
    Left = 0
    Top = 29
    Width = 435
    Height = 48
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Control flags: '
    TabOrder = 1
    object cbxDefaulted: TCheckBox
      Left = 11
      Top = 20
      Width = 80
      Height = 17
      Caption = 'Defaulted'
      TabOrder = 0
    end
  end
  object btnRefresh: TButton
    Left = 441
    Top = 45
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Refresh'
    TabOrder = 2
    OnClick = btnRefreshClick
  end
  object btnApply: TButton
    Left = 522
    Top = 45
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Apply'
    TabOrder = 3
    OnClick = btnApplyClick
  end
  object ActionList: TActionList
    Left = 312
    Top = 24
    object ActionRefresh: TAction
      Caption = 'ActionRefresh'
      ShortCut = 116
      OnExecute = btnRefreshClick
    end
  end
end
