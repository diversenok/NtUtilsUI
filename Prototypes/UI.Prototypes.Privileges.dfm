object PrivilegesFrame: TPrivilegesFrame
  AlignWithMargins = True
  Left = 0
  Top = 0
  Width = 320
  Height = 240
  Align = alClient
  DoubleBuffered = True
  ParentDoubleBuffered = False
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object ListViewEx: TListViewEx
    Left = 0
    Top = 0
    Width = 320
    Height = 240
    Align = alClient
    Columns = <
      item
        Caption = 'Privilege Name'
        Width = 200
      end
      item
        Caption = 'State'
        Width = 90
      end
      item
        Caption = 'Description'
        Width = 200
      end>
    GridLines = True
    Groups = <
      item
        Header = 'Sensitive (high integrity)'
        GroupID = 0
        State = [lgsNormal, lgsCollapsible]
        HeaderAlign = taLeftJustify
        FooterAlign = taLeftJustify
        TitleImage = -1
      end
      item
        Header = 'Normal (medium integrity)'
        GroupID = 1
        State = [lgsNormal, lgsCollapsible]
        HeaderAlign = taLeftJustify
        FooterAlign = taLeftJustify
        TitleImage = -1
      end
      item
        Header = 'Non-sensitive (no integrity)'
        GroupID = 2
        State = [lgsNormal, lgsCollapsible]
        HeaderAlign = taLeftJustify
        FooterAlign = taLeftJustify
        TitleImage = -1
      end>
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
    OnItemChecked = ListViewExItemChecked
    ClipboardSourceColumn = 0
    ColoringItems = True
    PopupOnItemsOnly = True
  end
end
