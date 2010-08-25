object MigraToolsMainForm: TMigraToolsMainForm
  Left = 0
  Top = 0
  Caption = 'Ferramentas de Migra'#231#227'o - Vers'#227'o Alfa'
  ClientHeight = 329
  ClientWidth = 469
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object statStatusBar: TStatusBar
    Left = 0
    Top = 310
    Width = 469
    Height = 19
    Panels = <>
  end
  object pnlBottomPanel: TPanel
    Left = 0
    Top = 0
    Width = 469
    Height = 25
    Align = alTop
    TabOrder = 1
  end
  object pnlTopPanel: TPanel
    Left = 0
    Top = 269
    Width = 469
    Height = 41
    Align = alBottom
    TabOrder = 2
    object btnClose: TBitBtn
      Left = 197
      Top = 8
      Width = 75
      Height = 25
      Caption = '&Fechar'
      DoubleBuffered = True
      Kind = bkClose
      ParentDoubleBuffered = False
      TabOrder = 0
    end
  end
  object pgc1: TPageControl
    Left = 0
    Top = 25
    Width = 469
    Height = 244
    ActivePage = tsPasswords
    Align = alClient
    TabOrder = 3
    object tsPasswords: TTabSheet
      Caption = 'S&enhas'
      object lblAccountFilter: TLabel
        Left = 5
        Top = 5
        Width = 75
        Height = 13
        Caption = '&Tipos de contas'
        FocusControl = cbbAccountFilter
      end
      object lblLocal: TLabel
        Left = 3
        Top = 56
        Width = 24
        Height = 13
        Caption = '&Local'
        FocusControl = cbbLocalDomain
      end
      object lblAccounts: TLabel
        Left = 168
        Top = 5
        Width = 34
        Height = 13
        Caption = '&Contas'
        FocusControl = chklstAccounts
      end
      object chklstAccounts: TCheckListBox
        Left = 168
        Top = 24
        Width = 129
        Height = 161
        OnClickCheck = chklstAccountsClickCheck
        ItemHeight = 13
        Items.Strings = (
          'Supervisor'
          'Suporte'
          'Suporte(T'#237'tulo)'
          'Oficial'
          'Instalador'
          'Desinstalador'
          'vncAcesso'
          'ghost')
        TabOrder = 0
      end
      object cbbAccountFilter: TComboBox
        Left = 5
        Top = 24
        Width = 143
        Height = 22
        Style = csOwnerDrawFixed
        Enabled = False
        ItemIndex = 0
        TabOrder = 1
        Text = '1 - Todas'
        Items.Strings = (
          '1 - Todas'
          '2 - Zonas'
          '3 - Equipe Suporte'
          '4 - Personalizado'
          '5 - Nenhuma')
      end
      object btnSetDefaulPasswords: TBitBtn
        Left = 3
        Top = 119
        Width = 113
        Height = 25
        Caption = 'Ajuste &Senhas'
        DoubleBuffered = True
        ParentDoubleBuffered = False
        TabOrder = 2
        OnClick = btnSetDefaulPasswordsClick
      end
      object cbbLocalDomain: TComboBox
        Left = 3
        Top = 75
        Width = 145
        Height = 22
        Style = csOwnerDrawFixed
        Enabled = False
        ItemIndex = 0
        TabOrder = 3
        Text = '1 - Todos'
        Items.Strings = (
          '1 - Todos'
          '2 - Local'
          '3 - Dom'#237'nio'
          '4 - Nenhuma')
      end
      object btnChepass: TBitBtn
        Left = 3
        Top = 159
        Width = 113
        Height = 25
        Caption = '&Verificar Senhas'
        DoubleBuffered = True
        Enabled = False
        ParentDoubleBuffered = False
        TabOrder = 4
      end
      object edtNewAccount: TLabeledEdit
        Left = 320
        Top = 24
        Width = 105
        Height = 21
        CharCase = ecLowerCase
        EditLabel.Width = 63
        EditLabel.Height = 13
        EditLabel.Caption = 'Novo usu'#225'rio'
        TabOrder = 5
      end
      object edtNewPass: TLabeledEdit
        Left = 320
        Top = 75
        Width = 105
        Height = 21
        EditLabel.Width = 57
        EditLabel.Height = 13
        EditLabel.Caption = 'Nova senha'
        PasswordChar = '*'
        TabOrder = 6
      end
      object btnAddNewUser: TBitBtn
        Left = 320
        Top = 159
        Width = 105
        Height = 25
        Caption = 'Adicionar usu'#225'rio'
        DoubleBuffered = True
        ParentDoubleBuffered = False
        TabOrder = 7
        OnClick = btnAddNewUserClick
      end
    end
    object tsPrinters: TTabSheet
      Caption = '&Impressoras'
      Enabled = False
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object btnSetScanner: TBitBtn
        Left = 19
        Top = 24
        Width = 113
        Height = 25
        Caption = 'Ajuste de &Portas'
        DoubleBuffered = True
        Enabled = False
        ParentDoubleBuffered = False
        TabOrder = 0
      end
    end
  end
  object fileVerMain: TFileVersionInfo
    Left = 24
    Top = 272
  end
  object ProcessControl: TJvCreateProcess
    OnTerminate = ProcessControlTerminate
    Left = 104
    Top = 272
  end
end
