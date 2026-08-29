object UiLibEnvVarEditor: TUiLibEnvVarEditor
  Left = 0
  Top = 0
  Width = 600
  Height = 400
  TabOrder = 0
  object lblName: TLabel
    Left = 0
    Top = 0
    Width = 35
    Height = 15
    Caption = 'Name:'
  end
  object lblValue: TLabel
    Left = 0
    Top = 50
    Width = 31
    Height = 15
    Caption = 'Value:'
  end
  object lblPathMode: TLabel
    Left = 363
    Top = 49
    Width = 233
    Height = 15
    Alignment = taRightJustify
    Anchors = [akTop, akRight]
    Caption = 'Line breaks will be replaced with semicolons'
    Visible = False
  end
  object tbxName: TUiLibEdit
    Left = 0
    Top = 20
    Width = 600
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    OnChange = tbxNameChange
  end
  object tbxValue: TUiLibMemo
    Left = 0
    Top = 70
    Width = 600
    Height = 330
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
end
