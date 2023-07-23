object GuidFrame: TGuidFrame
  Left = 0
  Top = 0
  Width = 600
  Height = 21
  Constraints.MinWidth = 224
  TabOrder = 0
  object tbxGuid: TEdit
    Left = 0
    Top = 0
    Width = 600
    Height = 21
    Align = alClient
    Enabled = False
    TabOrder = 0
    Text = '{00000000-0000-0000-0000-000000000000}'
    OnChange = tbxGuidChange
    OnExit = tbxGuidExit
  end
end
