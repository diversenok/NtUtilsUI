object AceFrame: TAceFrame
  Left = 0
  Top = 0
  Width = 600
  Height = 581
  Constraints.MinHeight = 500
  Constraints.MinWidth = 460
  DoubleBuffered = True
  ParentDoubleBuffered = False
  ParentShowHint = False
  ShowHint = True
  TabOrder = 0
  OnResize = SplitterMoved
  object lblType: TLabel
    Left = 0
    Top = 0
    Width = 600
    Height = 13
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Type:'
  end
  object lblFlags: TLabel
    Left = 354
    Top = 184
    Width = 29
    Height = 13
    Anchors = [akTop, akRight]
    Caption = 'Flags:'
  end
  object lblAccessMask: TLabel
    Left = 3
    Top = 184
    Width = 37
    Height = 13
    Caption = 'Access:'
  end
  object lblSid: TLabel
    Left = 0
    Top = 46
    Width = 600
    Height = 13
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'SID:'
  end
  object lblServerSid: TLabel
    Left = 0
    Top = 92
    Width = 600
    Height = 13
    Hint = 
      'Compound ACEs introduce two access checks: the first (client) SI' +
      'D is checked against the effective token; the second (server) SI' +
      'D is always checked against the primary (process) token of the c' +
      'aller.'
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Server SID:'
    Enabled = False
  end
  object lblCondition: TLabel
    Left = 0
    Top = 138
    Width = 600
    Height = 13
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Condition:'
    Enabled = False
  end
  object lblExtraData: TLabel
    Left = 0
    Top = 538
    Width = 600
    Height = 13
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Extra Data:'
  end
  object cbxType: TComboBox
    Left = 0
    Top = 18
    Width = 600
    Height = 22
    Style = csOwnerDrawFixed
    Anchors = [akLeft, akTop, akRight]
    DropDownCount = 22
    ItemIndex = 0
    TabOrder = 0
    Text = '0: Access Allowed ACE'
    OnChange = cbxTypeChange
    Items.Strings = (
      '0: Access Allowed ACE'
      '1: Access Denied ACE'
      '2: System Audit ACE'
      '3: System Alarm ACE'
      '4: Access Allowed Compound ACE'
      '5: Access Allowed Object ACE'
      '6: Access Denied Object ACE'
      '7: System Audit Object ACE'
      '8: System Alarm Object ACE'
      '9: Access Allowed Callback ACE'
      '10: Access Denied Callback ACE'
      '11: Access Allowed Callback Object ACE'
      '12: Access Denied Callback Object ACE'
      '13: System Audit Callback ACE'
      '14: System Alarm Callback ACE'
      '15: System Audit Callback Object ACE'
      '16: System Alarm Callback Object ACE'
      '17: System Mandatory Label ACE'
      '18: System Resource Attribute ACE'
      '19: System Scoped Policy Id ACE'
      '20: System Process Trust Label ACE'
      '21: System Access Filter ACE')
  end
  inline fmxSid: TSidEditor
    Left = 0
    Top = 62
    Width = 600
    Height = 25
    Anchors = [akLeft, akTop, akRight]
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
  end
  inline fmxServerSid: TSidEditor
    Left = 0
    Top = 108
    Width = 600
    Height = 25
    Anchors = [akLeft, akTop, akRight]
    Enabled = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
  end
  object cbxObjectType: TCheckBox
    Left = 0
    Top = 442
    Width = 600
    Height = 17
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Object Type:'
    Enabled = False
    TabOrder = 5
    OnClick = cbxObjectTypeClick
  end
  object cbxInheritedObjectType: TCheckBox
    Left = 0
    Top = 490
    Width = 600
    Height = 17
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Inherited Object Type:'
    Enabled = False
    TabOrder = 6
    OnClick = cbxInheritedObjectTypeClick
  end
  object BitsPanel: TPanel
    Left = 0
    Top = 202
    Width = 600
    Height = 235
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 4
    object Splitter: TSplitter
      Left = 338
      Top = 0
      Width = 6
      Height = 235
      Align = alRight
      MinSize = 210
      ResizeStyle = rsLine
      OnMoved = SplitterMoved
    end
    inline fmxFlags: TBitsFrame
      Left = 344
      Top = 0
      Width = 256
      Height = 235
      Align = alRight
      Constraints.MinHeight = 100
      Constraints.MinWidth = 200
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      inherited Tree: TDevirtualizedTree
        Width = 256
        Height = 207
        Columns = <
          item
            Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
            Position = 0
            Text = 'Name'
            Width = 256
          end>
      end
      inherited BottomPanel: TPanel
        Top = 207
        Width = 256
        inherited tbxValue: TEdit
          Width = 110
        end
        inherited btnAll: TButton
          Left = 186
        end
      end
    end
    inline fmxAccessMask: TBitsFrame
      Left = 0
      Top = 0
      Width = 338
      Height = 235
      Align = alClient
      Constraints.MinHeight = 100
      Constraints.MinWidth = 200
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      inherited Tree: TDevirtualizedTree
        Width = 338
        Height = 207
        Columns = <
          item
            Options = [coAllowClick, coDraggable, coEnabled, coParentBidiMode, coParentColor, coResizable, coVisible, coAutoSpring, coSmartResize, coAllowFocus, coDisableAnimatedResize, coEditable, coStyleColor]
            Position = 0
            Text = 'Name'
            Width = 338
          end>
      end
      inherited BottomPanel: TPanel
        Top = 207
        Width = 338
        inherited tbxValue: TEdit
          Width = 192
        end
        inherited btnAll: TButton
          Left = 268
        end
      end
    end
  end
  inline fmxCondition: TAceConditionFrame
    Left = 0
    Top = 154
    Width = 600
    Height = 25
    Anchors = [akLeft, akTop, akRight]
    Constraints.MinHeight = 25
    Constraints.MinWidth = 200
    Enabled = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
  end
  inline fmxExtraData: THexEditFrame
    Left = 0
    Top = 556
    Width = 600
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    ParentShowHint = False
    ShowHint = True
    TabOrder = 7
  end
  inline fmxObjectType: TGuidFrame
    Left = 0
    Top = 464
    Width = 600
    Height = 21
    Anchors = [akLeft, akRight, akBottom]
    Constraints.MinWidth = 224
    Enabled = False
    TabOrder = 8
  end
  inline fmxInheritedObjectType: TGuidFrame
    Left = 0
    Top = 512
    Width = 600
    Height = 21
    Anchors = [akLeft, akRight, akBottom]
    Constraints.MinWidth = 224
    Enabled = False
    TabOrder = 9
  end
end
