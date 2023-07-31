object AclSecurityFrame: TAclSecurityFrame
  Left = 0
  Top = 0
  Width = 620
  Height = 300
  Constraints.MinHeight = 235
  Constraints.MinWidth = 400
  TabOrder = 0
  inline AclFrame: TAclFrame
    Left = 0
    Top = 0
    Width = 620
    Height = 230
    Anchors = [akLeft, akTop, akRight, akBottom]
    Constraints.MinHeight = 165
    Constraints.MinWidth = 320
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
  end
  object btnRefresh: TButton
    Left = 545
    Top = 241
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Refresh'
    TabOrder = 2
    OnClick = btnRefreshClick
  end
  object btnApply: TButton
    Left = 545
    Top = 272
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Apply'
    TabOrder = 3
    OnClick = btnApplyClick
  end
  object GroupBox: TGroupBox
    Left = 0
    Top = 234
    Width = 539
    Height = 66
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Control flags: '
    TabOrder = 1
    object cbxInherited: TCheckBox
      Left = 224
      Top = 20
      Width = 140
      Height = 17
      Anchors = [akTop]
      Caption = 'Auto-inherited'
      TabOrder = 2
    end
    object cbxProtected: TCheckBox
      Left = 447
      Top = 20
      Width = 80
      Height = 17
      Anchors = [akTop, akRight]
      Caption = 'Protected'
      TabOrder = 4
    end
    object cbxInheritReq: TCheckBox
      Left = 224
      Top = 41
      Width = 140
      Height = 17
      Anchors = [akTop]
      Caption = 'Auto-inherit required'
      TabOrder = 3
    end
    object cbxDefaulted: TCheckBox
      Left = 8
      Top = 20
      Width = 80
      Height = 17
      Caption = 'Defaulted'
      TabOrder = 0
    end
    object cbxPresent: TCheckBox
      Left = 8
      Top = 41
      Width = 80
      Height = 17
      Caption = 'Present'
      TabOrder = 1
    end
  end
  object ActionList: TActionList
    Left = 440
    Top = 104
    object ActionRefresh: TAction
      ShortCut = 116
      OnExecute = btnRefreshClick
    end
  end
end
