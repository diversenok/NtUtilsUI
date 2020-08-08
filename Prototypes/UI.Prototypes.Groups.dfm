object GroupsFrame: TGroupsFrame
  AlignWithMargins = True
  Left = 0
  Top = 0
  Width = 383
  Height = 253
  Align = alClient
  DoubleBuffered = True
  ParentDoubleBuffered = False
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object ListViewEx: TListViewEx
    Left = 0
    Top = 0
    Width = 383
    Height = 253
    Align = alClient
    Columns = <
      item
        Caption = 'SID'
        Width = 220
      end
      item
        Caption = 'State'
        Width = 110
      end
      item
        Caption = 'Flags'
        Width = 120
      end>
    GridLines = True
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
    ClipboardSourceColumn = 0
    ColoringItems = True
    PopupOnItemsOnly = True
  end
end
