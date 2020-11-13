object BitMaskFrame: TBitMaskFrame
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
    Checkboxes = True
    Columns = <
      item
        AutoSize = True
      end>
    MultiSelect = True
    GroupView = True
    ReadOnly = True
    RowSelect = True
    ShowColumnHeaders = False
    TabOrder = 0
    ViewStyle = vsReport
    ColoringItems = True
  end
end
