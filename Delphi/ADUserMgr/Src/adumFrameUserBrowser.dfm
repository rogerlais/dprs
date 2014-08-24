object FrmUserBrowser: TFrmUserBrowser
  Left = 0
  Top = 0
  Width = 451
  Height = 304
  Align = alClient
  TabOrder = 0
  object splSplitter: TSplitter
    Left = -12
    Top = 0
    Height = 304
    Align = alRight
    ExplicitLeft = -6
    ExplicitHeight = 480
  end
  object pgcDetails: TPageControl
    Left = -9
    Top = 0
    Width = 460
    Height = 304
    ActivePage = tsAD
    Align = alRight
    TabOrder = 0
    object tsAD: TTabSheet
      Caption = 'Actice Diretory'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
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
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
    end
    object tsRequisit: TTabSheet
      Caption = 'Requisitados'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
    end
    object tsEstag: TTabSheet
      Caption = 'Estagi'#225'rios'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 396
    Height = 304
    Align = alClient
    Caption = 'pnlLeft'
    TabOrder = 1
    ExplicitWidth = 277
    object dbgrdUserBrowser: TDBGrid
      Left = 1
      Top = 1
      Width = 394
      Height = 385
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
      Top = 386
      Width = 394
      Height = 103
      Align = alBottom
      TabOrder = 1
      ExplicitTop = 200
      ExplicitWidth = 275
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
    OnDataChange = dsUserFullDataChange
    Left = 104
    Top = 128
  end
end
