object FrmUserBrowser: TFrmUserBrowser
  Left = 0
  Top = 0
  Width = 742
  Height = 554
  Align = alClient
  TabOrder = 0
  object splSplitter: TSplitter
    Left = 277
    Top = 0
    Height = 554
    Align = alRight
    ExplicitLeft = -6
    ExplicitHeight = 480
  end
  object pgcDetails: TPageControl
    Left = 280
    Top = 0
    Width = 460
    Height = 554
    ActivePage = tsAD
    Align = alRight
    TabOrder = 0
    ExplicitLeft = -9
    ExplicitHeight = 304
    object tsAD: TTabSheet
      Caption = 'Actice Diretory'
      ExplicitHeight = 276
      object edtLogin: TLabeledEdit
        Left = 24
        Top = 48
        Width = 121
        Height = 21
        EditLabel.Width = 25
        EditLabel.Height = 13
        EditLabel.Caption = 'Login'
        TabOrder = 0
      end
      object edtFullName: TLabeledEdit
        Left = 24
        Top = 95
        Width = 281
        Height = 21
        EditLabel.Width = 77
        EditLabel.Height = 13
        EditLabel.Caption = 'Nome completo:'
        TabOrder = 1
      end
      object edtRuledName: TLabeledEdit
        Left = 24
        Top = 151
        Width = 281
        Height = 21
        EditLabel.Width = 139
        EditLabel.Height = 13
        EditLabel.Caption = 'Nome completo normatizado:'
        TabOrder = 2
      end
    end
    object tsTitular: TTabSheet
      Caption = 'Servidores do Quadro'
      ImageIndex = 3
      ExplicitHeight = 276
    end
    object tsRequisit: TTabSheet
      Caption = 'Requisitados'
      ImageIndex = 1
      ExplicitHeight = 276
    end
    object tsEstag: TTabSheet
      Caption = 'Estagi'#225'rios'
      ImageIndex = 2
      ExplicitHeight = 276
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 277
    Height = 554
    Align = alClient
    Caption = 'pnlLeft'
    TabOrder = 1
    ExplicitWidth = 207
    ExplicitHeight = 304
    object dbgrdUserBrowser: TDBGrid
      Left = 1
      Top = 1
      Width = 275
      Height = 449
      Align = alClient
      DataSource = dsUserFull
      ReadOnly = True
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
    end
    object pnlBrowseFilters: TPanel
      Left = 1
      Top = 450
      Width = 275
      Height = 103
      Align = alBottom
      TabOrder = 1
      ExplicitTop = 200
      ExplicitWidth = 205
      object chkTitular: TCheckBox
        Left = 16
        Top = 6
        Width = 265
        Height = 17
        Caption = 'Servidores do &Quadro'
        TabOrder = 0
      end
      object chkRequisit: TCheckBox
        Left = 16
        Top = 27
        Width = 265
        Height = 17
        Caption = '&Requisitados'
        TabOrder = 1
      end
      object chkEstag: TCheckBox
        Left = 16
        Top = 48
        Width = 265
        Height = 17
        Caption = '&Estagi'#225'rios'
        TabOrder = 2
      end
      object chkTodos: TCheckBox
        Left = 16
        Top = 69
        Width = 265
        Height = 17
        Caption = '&Todos'
        TabOrder = 3
      end
    end
  end
  object dsUserFull: TDataSource
    AutoEdit = False
    DataSet = DtMdMainADUserMgr.dsExtUserSD
    OnDataChange = dsUserFullDataChange
    Left = 104
    Top = 128
  end
end
