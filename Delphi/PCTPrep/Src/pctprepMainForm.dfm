object MainForm: TMainForm
  Left = 30
  Top = 20
  BorderIcons = []
  Caption = 'MainForm'
  ClientHeight = 237
  ClientWidth = 469
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblZone: TLabel
    Left = 32
    Top = 7
    Width = 29
    Height = 13
    Caption = '&Zonas'
  end
  object lblPctNumber: TLabel
    Left = 224
    Top = 7
    Width = 88
    Height = 13
    Caption = '&PCT(Identificador)'
  end
  object lstZone: TListBox
    Left = 32
    Top = 21
    Width = 121
    Height = 97
    ItemHeight = 13
    TabOrder = 0
    OnClick = lstZoneClick
  end
  object pnlComputerName: TPanel
    Left = 32
    Top = 124
    Width = 313
    Height = 41
    Caption = 'pnlComputerName'
    Color = 14825524
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentBackground = False
    ParentFont = False
    TabOrder = 1
  end
  object pnlComputerIp: TPanel
    AlignWithMargins = True
    Left = 32
    Top = 171
    Width = 313
    Height = 41
    Caption = 'pnlComputerName'
    Color = 14825524
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -27
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentBackground = False
    ParentFont = False
    TabOrder = 2
  end
  object pnlButtons: TPanel
    Left = 356
    Top = 0
    Width = 113
    Height = 218
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 3
    object btnOk: TBitBtn
      Left = 19
      Top = 25
      Width = 75
      Height = 25
      DoubleBuffered = True
      Kind = bkOK
      ParentDoubleBuffered = False
      TabOrder = 0
      OnClick = btnOkClick
    end
    object btnInserir: TBitBtn
      Left = 19
      Top = 56
      Width = 75
      Height = 25
      Caption = '&Inserir'
      Default = True
      DoubleBuffered = True
      Enabled = False
      Glyph.Data = {
        76010000424D7601000000000000760000002800000020000000100000000100
        04000000000000010000130B0000130B00001000000000000000000000000000
        800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
        33333333FF33333333FF333993333333300033377F3333333777333993333333
        300033F77FFF3333377739999993333333333777777F3333333F399999933333
        33003777777333333377333993333333330033377F3333333377333993333333
        3333333773333333333F333333333333330033333333F33333773333333C3333
        330033333337FF3333773333333CC333333333FFFFF77FFF3FF33CCCCCCCCCC3
        993337777777777F77F33CCCCCCCCCC3993337777777777377333333333CC333
        333333333337733333FF3333333C333330003333333733333777333333333333
        3000333333333333377733333333333333333333333333333333}
      ModalResult = 6
      NumGlyphs = 2
      ParentDoubleBuffered = False
      TabOrder = 1
      OnClick = btnInserirClick
    end
    object btnCancel: TBitBtn
      Left = 19
      Top = 91
      Width = 75
      Height = 25
      DoubleBuffered = True
      Kind = bkCancel
      ParentDoubleBuffered = False
      TabOrder = 2
      OnClick = btnCancelClick
    end
    object btnClose: TBitBtn
      Left = 19
      Top = 147
      Width = 75
      Height = 25
      DoubleBuffered = True
      Kind = bkClose
      ParentDoubleBuffered = False
      TabOrder = 3
      OnClick = btnCloseClick
    end
    object btnTest: TBitBtn
      Left = 19
      Top = 180
      Width = 75
      Height = 25
      Caption = '&Teste'
      DoubleBuffered = True
      Glyph.Data = {
        76010000424D7601000000000000760000002800000020000000100000000100
        04000000000000010000120B0000120B00001000000000000000000000000000
        800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00370777033333
        3330337F3F7F33333F3787070003333707303F737773333373F7007703333330
        700077337F3333373777887007333337007733F773F333337733700070333333
        077037773733333F7F37703707333300080737F373333377737F003333333307
        78087733FFF3337FFF7F33300033330008073F3777F33F777F73073070370733
        078073F7F7FF73F37FF7700070007037007837773777F73377FF007777700730
        70007733FFF77F37377707700077033707307F37773F7FFF7337080777070003
        3330737F3F7F777F333778080707770333333F7F737F3F7F3333080787070003
        33337F73FF737773333307800077033333337337773373333333}
      NumGlyphs = 2
      ParentDoubleBuffered = False
      TabOrder = 4
      OnClick = btnTestClick
    end
  end
  object lstPctNumber: TListBox
    Left = 224
    Top = 21
    Width = 121
    Height = 97
    ItemHeight = 13
    TabOrder = 4
    OnClick = lstPctNumberClick
  end
  object statBar: TStatusBar
    Left = 0
    Top = 218
    Width = 469
    Height = 19
    Panels = <
      item
        Width = 250
      end>
  end
  object fvVersion: TFileVersionInfo
    Left = 176
    Top = 24
  end
end
