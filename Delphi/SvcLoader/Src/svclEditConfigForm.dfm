object EditConfigForm: TEditConfigForm
  Left = 0
  Top = 0
  Caption = 'EditConfigForm'
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
  object tbcConfig: TTabControl
    Left = 0
    Top = 41
    Width = 690
    Height = 355
    Align = alClient
    TabOrder = 2
    Tabs.Strings = (
      '&Esta'#231#227'o'
      '&Servidor')
    TabIndex = 0
    object lblSourceFilePath: TLabel
      Left = 16
      Top = 45
      Width = 164
      Height = 13
      Caption = 'Caminho de captura dos arquivos:'
    end
    object edtDirCapturePath: TJvDirectoryEdit
      Left = 16
      Top = 64
      Width = 393
      Height = 21
      DialogKind = dkWin32
      TabOrder = 0
      Text = 'edtDirCapturePath'
    end
  end
end
