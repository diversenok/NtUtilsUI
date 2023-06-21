object AppContainerListAllUsersFrame: TAppContainerListAllUsersFrame
  Left = 0
  Top = 0
  Width = 600
  Height = 440
  Constraints.MinHeight = 230
  Constraints.MinWidth = 300
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object lblUsers: TLabel
    Left = 3
    Top = 5
    Width = 59
    Height = 13
    Caption = 'User profile:'
  end
  object tbxUser: TEdit
    Left = 72
    Top = 2
    Width = 447
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 1
    Text = '(not selected)'
  end
  object btnSelectUser: TButton
    Left = 525
    Top = 0
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Change...'
    TabOrder = 2
    OnClick = btnSelectUserClick
  end
  inline AppContainersFrame: TAppContainerListFrame
    AlignWithMargins = True
    Left = 0
    Top = 29
    Width = 600
    Height = 411
    Margins.Left = 0
    Margins.Top = 29
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alClient
    Constraints.MinHeight = 150
    Constraints.MinWidth = 300
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    inherited Tree: TDevirtualizedTree
      Height = 385
    end
  end
end
