object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 225
  ClientWidth = 469
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblZone: TLabel
    Left = 32
    Top = 7
    Width = 34
    Height = 13
    Caption = 'lblZone'
  end
  object lblPctNumber: TLabel
    Left = 224
    Top = 7
    Width = 62
    Height = 13
    Caption = 'lblPctNumber'
  end
  object lstZone: TListBox
    Left = 32
    Top = 21
    Width = 121
    Height = 97
    ItemHeight = 13
    TabOrder = 0
  end
  object pnlComputerName: TPanel
    Left = 32
    Top = 124
    Width = 313
    Height = 41
    Caption = 'pnlComputerName'
    Color = 15826053
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object pnlComputerIp: TPanel
    AlignWithMargins = True
    Left = 32
    Top = 171
    Width = 313
    Height = 41
    AutoSize = True
    Caption = 'pnlComputerName'
    Color = clFuchsia
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 2
  end
  object pnlButtons: TPanel
    Left = 356
    Top = 0
    Width = 113
    Height = 225
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 3
    object btnOk: TBitBtn
      Left = 19
      Top = 21
      Width = 75
      Height = 25
      DoubleBuffered = True
      Kind = bkOK
      ParentDoubleBuffered = False
      TabOrder = 0
    end
    object btnInserir: TBitBtn
      Left = 19
      Top = 56
      Width = 75
      Height = 25
      Caption = '&Inserir'
      Default = True
      DoubleBuffered = True
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
  end
  object lstPctNumber: TListBox
    Left = 224
    Top = 21
    Width = 121
    Height = 97
    ItemHeight = 13
    TabOrder = 4
  end
  object pnltest: TPanel
    Left = 168
    Top = 40
    Width = 33
    Height = 57
    Caption = 'pnltest'
    Color = clHotLight
    ParentBackground = False
    TabOrder = 5
  end
end
