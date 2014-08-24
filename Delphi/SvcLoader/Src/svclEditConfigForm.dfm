object EditConfigForm: TEditConfigForm
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Configura'#231#245'es (Servi'#231'o / TransBio / ELO)'
  ClientHeight = 462
  ClientWidth = 692
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object pnlBottom: TPanel
    Left = 0
    Top = 398
    Width = 692
    Height = 64
    Align = alBottom
    TabOrder = 2
    DesignSize = (
      692
      64)
    object btnOk: TBitBtn
      Left = 379
      Top = 19
      Width = 110
      Height = 25
      Anchors = []
      DoubleBuffered = True
      Kind = bkCancel
      ParentDoubleBuffered = False
      TabOrder = 1
    end
    object btnCancel: TBitBtn
      Left = 203
      Top = 19
      Width = 110
      Height = 25
      Anchors = []
      DoubleBuffered = True
      Kind = bkOK
      ParentDoubleBuffered = False
      TabOrder = 0
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 692
    Height = 41
    Align = alTop
    TabOrder = 0
    object chkServerMode: TCheckBox
      Left = 16
      Top = 13
      Width = 281
      Height = 17
      Caption = 'Funcionar como m'#225'quina  &prim'#225'ria/servidor'
      TabOrder = 0
    end
  end
  object tbcConfig: TPageControl
    Left = 0
    Top = 41
    Width = 692
    Height = 357
    ActivePage = tsClientConfig
    Align = alClient
    TabOrder = 1
    object tsClientConfig: TTabSheet
      Caption = '&Esta'#231#227'o'
      object lblClientSourceBioService: TLabel
        Left = 9
        Top = 28
        Width = 97
        Height = 13
        Caption = 'Caminho BioService:'
      end
      object lblClientTransBioTrans: TLabel
        Left = 9
        Top = 124
        Width = 124
        Height = 13
        Caption = 'Caminho TransBio(Trans):'
      end
      object lblClientTransBioRetrans: TLabel
        Left = 9
        Top = 172
        Width = 135
        Height = 13
        Caption = 'Caminho TransBio(Retrans):'
      end
      object lblClientTransBioError: TLabel
        Left = 9
        Top = 228
        Width = 117
        Height = 13
        Caption = 'Caminho TransBio(Erro):'
      end
      object lblClientELO2TransBio: TLabel
        Left = 9
        Top = 78
        Width = 142
        Height = 13
        Caption = 'Caminho ELO->TransBio(Bio):'
      end
      object lblClientServername: TLabel
        Left = 345
        Top = 28
        Width = 44
        Height = 13
        Caption = 'Servidor:'
      end
      object lblClientTimeInterval: TLabel
        Left = 345
        Top = 76
        Width = 69
        Height = 13
        Caption = 'Intervalo(ms):'
      end
      object lblClientPathFullyBackup: TLabel
        Left = 345
        Top = 126
        Width = 110
        Height = 13
        Caption = 'Caminho Backup Geral:'
      end
      object lblClientPathOrderedBackup: TLabel
        Left = 345
        Top = 172
        Width = 133
        Height = 13
        Caption = 'Caminho Backup Ordenado:'
      end
      object edtDirClientBioServicePath: TJvDirectoryEdit
        Left = 9
        Top = 47
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 0
      end
      object edtDirClientTransBioTrans: TJvDirectoryEdit
        Left = 9
        Top = 143
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 2
      end
      object edtDirClientTransBioRetrans: TJvDirectoryEdit
        Left = 9
        Top = 191
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 3
      end
      object edtDirClientTransBioError: TJvDirectoryEdit
        Left = 9
        Top = 247
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 4
      end
      object edtDirClientELO2TransBioBio: TJvDirectoryEdit
        Left = 9
        Top = 97
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 1
      end
      object edtClientServername: TEdit
        Left = 345
        Top = 47
        Width = 121
        Height = 21
        TabOrder = 5
      end
      object seClientTimeInterval: TSpinEdit
        Left = 345
        Top = 95
        Width = 67
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 6
        Value = 0
      end
      object edtDirClientPathFullyBackup: TJvDirectoryEdit
        Left = 345
        Top = 143
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 7
      end
      object edtDirClientPathOrderedBackup: TJvDirectoryEdit
        Left = 345
        Top = 191
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 8
      end
    end
    object tsServerConfig: TTabSheet
      Caption = 'Ser&vidor'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object lblServerPathPrimaryBackup: TLabel
        Left = 12
        Top = 28
        Width = 136
        Height = 13
        Caption = 'Caminho Transbio(servidor):'
      end
      object lblServerPathOrderlyBackup: TLabel
        Left = 9
        Top = 76
        Width = 131
        Height = 13
        Caption = 'Caminho Backup ordenado:'
      end
      object lbledtDirServerPathFullyBackup: TLabel
        Left = 9
        Top = 132
        Width = 131
        Height = 13
        Caption = 'Caminho Backup ordenado:'
      end
      object edtDirServerPathTransBio: TJvDirectoryEdit
        Left = 9
        Top = 47
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 0
      end
      object edtDirServerPathOrderlyBackup: TJvDirectoryEdit
        Left = 9
        Top = 95
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 1
      end
      object edtDirServerPathFullyBackup: TJvDirectoryEdit
        Left = 9
        Top = 151
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 2
      end
    end
    object tsCommon: TTabSheet
      Caption = '&Comum'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object lblTCPPort: TLabel
        Left = 13
        Top = 28
        Width = 52
        Height = 13
        Caption = 'Porta TCP:'
      end
      object lblNotificationList: TLabel
        Left = 13
        Top = 73
        Width = 96
        Height = 13
        Caption = 'Lista de noti&fica'#231#227'o:'
      end
      object lblEmailEmitter: TLabel
        Left = 13
        Top = 117
        Width = 95
        Height = 13
        Caption = 'Emissor notifica'#231#227'o:'
      end
      object lblTransBioConfigFile: TLabel
        Left = 13
        Top = 161
        Width = 152
        Height = 13
        Caption = 'Arquivo Configura'#231#227'o Transbio:'
      end
      object lblDebugLevel: TLabel
        Left = 13
        Top = 208
        Width = 96
        Height = 13
        Caption = 'N'#237'vel de depura'#231#227'o:'
      end
      object edtTCPPort: TSpinEdit
        Left = 13
        Top = 46
        Width = 67
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 0
        Value = 0
      end
      object edtNotificationList: TEdit
        Left = 13
        Top = 91
        Width = 121
        Height = 21
        TabOrder = 1
      end
      object edtEmailEmitter: TEdit
        Left = 13
        Top = 135
        Width = 121
        Height = 21
        TabOrder = 2
      end
      object edtfTransBioConfigFile: TJvFilenameEdit
        Left = 13
        Top = 179
        Width = 233
        Height = 21
        TabOrder = 3
        Text = 'edtfTransBioConfigFile'
      end
      object seDebugLevel: TSpinEdit
        Left = 13
        Top = 226
        Width = 67
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 4
        Value = 0
      end
    end
  end
end
