object FrmUserBrowser: TFrmUserBrowser
  Left = 0
  Top = 0
  Width = 852
  Height = 480
  Align = alClient
  TabOrder = 0
  object splSplitter: TSplitter
    Left = 389
    Top = 0
    Height = 480
    Align = alRight
    ExplicitLeft = -6
  end
  object pgcDetails: TPageControl
    Left = 392
    Top = 0
    Width = 460
    Height = 480
    ActivePage = tsAD
    Align = alRight
    TabOrder = 0
    object tsAD: TTabSheet
      Caption = 'Actice Diretory'
      ExplicitWidth = 370
      ExplicitHeight = 423
    end
    object tsTitular: TTabSheet
      Caption = 'Servidores do Quadro'
      ImageIndex = 3
      ExplicitWidth = 370
    end
    object tsRequisit: TTabSheet
      Caption = 'Requisitados'
      ImageIndex = 1
      ExplicitWidth = 370
    end
    object tsEstag: TTabSheet
      Caption = 'Estagi'#225'rios'
      ImageIndex = 2
      ExplicitWidth = 370
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 389
    Height = 480
    Align = alClient
    Caption = 'pnlLeft'
    TabOrder = 1
    ExplicitLeft = 1
    object dbgrdUserBrowser: TDBGrid
      Left = 1
      Top = 1
      Width = 387
      Height = 375
      Align = alClient
      DataSource = dsUserFull
      ReadOnly = True
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
      Columns = <
        item
          Expanded = False
          FieldName = 'idext_users'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'full_name'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'full_name_ruled'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'user_type'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'location'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'acronym_location'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'start_date'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'end_date'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'source'
          Visible = True
        end>
    end
    object pnlBrowseFilters: TPanel
      Left = 1
      Top = 376
      Width = 387
      Height = 103
      Align = alBottom
      TabOrder = 1
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
    Left = 232
    Top = 144
  end
end
