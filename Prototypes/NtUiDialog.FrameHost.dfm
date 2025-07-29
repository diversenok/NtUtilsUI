object FrameHostDialog: TFrameHostDialog
  Left = 0
  Top = 0
  ClientHeight = 473
  ClientWidth = 614
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  Position = poOwnerFormCenter
  ShowHint = True
  OnKeyDown = FormKeyDown
  TextHeight = 13
  object btnClose: TButton
    Left = 3
    Top = 445
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Cancel'
    ModalResult = 8
    TabOrder = 0
    OnClick = btnCloseClick
  end
  object btnSelect: TButton
    Left = 536
    Top = 445
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Select'
    Default = True
    TabOrder = 1
    OnClick = btnSelectClick
  end
end
