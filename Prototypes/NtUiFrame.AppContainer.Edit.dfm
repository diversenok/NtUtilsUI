object AppContainerFieldFrame: TAppContainerFieldFrame
  Left = 0
  Top = 0
  Width = 375
  Height = 25
  Constraints.MinHeight = 25
  Constraints.MinWidth = 180
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object tbxMoniker: TEdit
    Left = 0
    Top = 2
    Width = 289
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    TextHint = 'Moniker or SID'
    OnChange = tbxMonikerChange
  end
  object btnSelect: TButton
    Left = 295
    Top = 0
    Width = 80
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Select...'
    DropDownMenu = pmMenu
    PopupMenu = pmMenu
    Style = bsSplitButton
    TabOrder = 1
    OnClick = btnSelectClick
  end
  object pmMenu: TPopupMenu
    Left = 200
    Top = 8
    object cmClear: TMenuItem
      Caption = 'Clear'
      OnClick = cmClearClick
    end
  end
end
