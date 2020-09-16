object AccessMaskFrame: TAccessMaskFrame
  AlignWithMargins = True
  Left = 0
  Top = 0
  Width = 230
  Height = 260
  Align = alClient
  Constraints.MinHeight = 200
  Constraints.MinWidth = 180
  DoubleBuffered = True
  ParentDoubleBuffered = False
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object ListViewEx: TListViewEx
    Left = 0
    Top = 0
    Width = 230
    Height = 231
    Align = alClient
    Checkboxes = True
    Columns = <
      item
        AutoSize = True
        WidthType = (
          -1)
      end>
    Groups = <
      item
        Header = 'Read'
        GroupID = 0
        State = [lgsNormal, lgsCollapsible]
        HeaderAlign = taLeftJustify
        FooterAlign = taLeftJustify
        TitleImage = -1
      end
      item
        Header = 'Write'
        GroupID = 1
        State = [lgsNormal, lgsCollapsible]
        HeaderAlign = taLeftJustify
        FooterAlign = taLeftJustify
        TitleImage = -1
      end
      item
        Header = 'Execute'
        GroupID = 2
        State = [lgsNormal, lgsCollapsible]
        HeaderAlign = taLeftJustify
        FooterAlign = taLeftJustify
        TitleImage = -1
      end
      item
        Header = 'Specific'
        GroupID = 3
        State = [lgsNormal, lgsCollapsible]
        HeaderAlign = taLeftJustify
        FooterAlign = taLeftJustify
        TitleImage = -1
      end
      item
        Header = 'Standard'
        GroupID = 4
        State = [lgsNormal, lgsCollapsible]
        HeaderAlign = taLeftJustify
        FooterAlign = taLeftJustify
        TitleImage = -1
      end
      item
        Header = 'Generic'
        GroupID = 5
        State = [lgsNormal, lgsCollapsible]
        HeaderAlign = taLeftJustify
        FooterAlign = taLeftJustify
        TitleImage = -1
      end
      item
        Header = 'Miscellaneous'
        GroupID = 6
        State = [lgsNormal, lgsCollapsible]
        HeaderAlign = taLeftJustify
        FooterAlign = taLeftJustify
        TitleImage = -1
      end>
    MultiSelect = True
    GroupView = True
    ReadOnly = True
    RowSelect = True
    ShowColumnHeaders = False
    TabOrder = 0
    ViewStyle = vsReport
    OnItemChecked = ListViewExItemChecked
  end
  object Panel: TPanel
    Left = 0
    Top = 231
    Width = 230
    Height = 29
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'Panel'
    TabOrder = 1
    object ButtonClear: TButton
      AlignWithMargins = True
      Left = 0
      Top = 4
      Width = 70
      Height = 25
      Margins.Left = 0
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 0
      Align = alLeft
      Caption = 'Clear'
      TabOrder = 1
      OnClick = ButtonClearClick
    end
    object ButtonFull: TButton
      AlignWithMargins = True
      Left = 160
      Top = 4
      Width = 70
      Height = 25
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alRight
      Caption = 'Full Access'
      TabOrder = 2
      OnClick = ButtonFullClick
    end
    object EditMask: TEdit
      AlignWithMargins = True
      Left = 74
      Top = 6
      Width = 82
      Height = 21
      Margins.Left = 0
      Margins.Top = 6
      Margins.Right = 0
      Margins.Bottom = 2
      Align = alClient
      Constraints.MinWidth = 80
      TabOrder = 0
      TextHint = '0x0000 0000'
      OnChange = EditMaskChange
    end
  end
end
