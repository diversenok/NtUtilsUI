object EnvironmentFrame: TEnvironmentFrame
  AlignWithMargins = True
  Left = 0
  Top = 0
  Width = 480
  Height = 320
  Align = alClient
  DoubleBuffered = True
  ParentDoubleBuffered = False
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  object ListViewEx: TListViewEx
    Left = 0
    Top = 0
    Width = 480
    Height = 320
    Align = alClient
    Columns = <
      item
        Caption = 'Name'
        Width = 168
      end
      item
        AutoSize = True
        Caption = 'Value'
      end>
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
