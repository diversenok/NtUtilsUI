object AppContainersForm: TAppContainersForm
  Left = 0
  Top = 0
  Caption = 'AppContainer Profiles'
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
  OldCreateOrder = False
  ShowHint = True
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  DesignSize = (
    614
    473)
  PixelsPerInch = 96
  TextHeight = 13
  object lblUsers: TLabel
    Left = 7
    Top = 8
    Width = 59
    Height = 13
    Caption = 'User profile:'
  end
  object btnSelect: TButton
    Left = 534
    Top = 445
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Select'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnClose: TButton
    Left = 5
    Top = 445
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Close'
    ModalResult = 8
    TabOrder = 2
    OnClick = btnCloseClick
  end
  object tbxUser: TEdit
    Left = 78
    Top = 5
    Width = 531
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 3
    Text = '(not selected)'
  end
  inline AppContainersFrame: TAppContainersFrame
    AlignWithMargins = True
    Left = 5
    Top = 32
    Width = 604
    Height = 409
    Margins.Left = 5
    Margins.Top = 32
    Margins.Right = 5
    Margins.Bottom = 32
    Align = alClient
    Constraints.MinHeight = 120
    Constraints.MinWidth = 280
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    inherited SearchBox: TSearchFrame
      Width = 604
      inherited Splitter: TSplitter
        Left = 438
      end
      inherited tbxSearchBox: TButtonedEdit
        Width = 438
      end
      inherited cbxColumn: TComboBox
        Left = 444
      end
    end
    inherited Tree: TDevirtualizedTree
      Width = 604
      Height = 383
    end
  end
end
