object AppContainersExFrame: TAppContainersExFrame
  Left = 0
  Top = 0
  Width = 600
  Height = 439
  Constraints.MinHeight = 230
  Constraints.MinWidth = 300
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object lblUsers: TLabel
    Left = 3
    Top = 8
    Width = 59
    Height = 13
    Caption = 'User profile:'
  end
  object tbxUser: TEdit
    Left = 72
    Top = 5
    Width = 447
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 0
    Text = '(not selected)'
  end
  object btnSelectUser: TButton
    Left = 525
    Top = 3
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Change...'
    TabOrder = 1
    OnClick = btnSelectUserClick
  end
  inline AppContainersFrame: TAppContainersFrame
    AlignWithMargins = True
    Left = 0
    Top = 32
    Width = 600
    Height = 407
    Margins.Left = 0
    Margins.Top = 32
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    Constraints.MinHeight = 150
    Constraints.MinWidth = 300
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
  end
end
