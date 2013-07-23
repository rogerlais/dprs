object EditConfigForm: TEditConfigForm
  Left = 0
  Top = 0
  Caption = 'Configura'#231#245'es (Servi'#231'o / TransBio / ELO)'
  ClientHeight = 460
  ClientWidth = 690
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object pnlBottom: TPanel
    Left = 0
    Top = 396
    Width = 690
    Height = 64
    Align = alBottom
    TabOrder = 0
    DesignSize = (
      690
      64)
    object btnOk: TBitBtn
      Left = 378
      Top = 19
      Width = 110
      Height = 25
      Anchors = []
      DoubleBuffered = True
      Kind = bkCancel
      ParentDoubleBuffered = False
      TabOrder = 0
    end
    object btnCancel: TBitBtn
      Left = 202
      Top = 19
      Width = 110
      Height = 25
      Anchors = []
      DoubleBuffered = True
      Kind = bkOK
      ParentDoubleBuffered = False
      TabOrder = 1
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 690
    Height = 41
    Align = alTop
    TabOrder = 1
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
    Width = 690
    Height = 355
    ActivePage = tsCommon
    Align = alClient
    TabOrder = 2
    object tsClientConfig: TTabSheet
      Caption = '&Esta'#231#227'o'
      object lblSourceBioService: TLabel
        Left = 9
        Top = 28
        Width = 97
        Height = 13
        Caption = 'Caminho BioService:'
      end
      object lblTrasnBioBio: TLabel
        Left = 9
        Top = 76
        Width = 111
        Height = 13
        Caption = 'Caminho TransBio(Bio):'
      end
      object lblTransBioTrans: TLabel
        Left = 9
        Top = 124
        Width = 124
        Height = 13
        Caption = 'Caminho TransBio(Trans):'
      end
      object lblTransBioRetrans: TLabel
        Left = 9
        Top = 172
        Width = 135
        Height = 13
        Caption = 'Caminho TransBio(Retrans):'
      end
      object lblTransBioError: TLabel
        Left = 9
        Top = 228
        Width = 117
        Height = 13
        Caption = 'Caminho TransBio(Erro):'
      end
      object lblELO2TransBio: TLabel
        Left = 9
        Top = 284
        Width = 120
        Height = 13
        Caption = 'Caminho ELO->TransBio:'
      end
      object lblServername: TLabel
        Left = 361
        Top = 28
        Width = 44
        Height = 13
        Caption = 'Servidor:'
      end
      object edtDirCapturePath: TJvDirectoryEdit
        Left = 9
        Top = 47
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 0
        Text = 'edtDirBioService'
      end
      object edtDir1: TJvDirectoryEdit
        Left = 9
        Top = 95
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 1
        Text = 'edtDirTransBioBio'
      end
      object edtDirTransBioTrans: TJvDirectoryEdit
        Left = 9
        Top = 143
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 2
        Text = 'edtDirTransBioBio'
      end
      object edtDirTransBioRetrans: TJvDirectoryEdit
        Left = 9
        Top = 191
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 3
        Text = 'edtDirTransBioBio'
      end
      object edtDirTransBioError: TJvDirectoryEdit
        Left = 9
        Top = 247
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 4
        Text = 'edtDirTransBioBio'
      end
      object edtDirELO2TransBio: TJvDirectoryEdit
        Left = 9
        Top = 303
        Width = 299
        Height = 21
        DialogKind = dkWin32
        TabOrder = 5
        Text = 'edtDirTransBioBio'
      end
      object edtServername: TEdit
        Left = 360
        Top = 47
        Width = 121
        Height = 21
        TabOrder = 6
        Text = 'edtServername'
      end
    end
    object tsServerConfig: TTabSheet
      Caption = 'Ser&vidor'
      ImageIndex = 1
    end
    object tsCommon: TTabSheet
      Caption = '&Comum'
      ImageIndex = 2
      object lblTCPPort: TLabel
        Left = 13
        Top = 28
        Width = 52
        Height = 13
        Caption = 'Porta TCP:'
      end
      object edtTCPPort: TSpinEdit
        Left = 12
        Top = 47
        Width = 67
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 0
        Value = 0
      end
    end
  end
end
