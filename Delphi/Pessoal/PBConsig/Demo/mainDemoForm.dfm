object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 457
  ClientWidth = 595
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object wbBrowser: TWebBrowser
    Left = 0
    Top = 0
    Width = 595
    Height = 399
    Align = alClient
    TabOrder = 0
    ExplicitHeight = 393
    ControlData = {
      4C0000007F3D00003D2900000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E126208000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 399
    Width = 595
    Height = 58
    Align = alBottom
    Caption = 'pnlBottom'
    TabOrder = 1
    object btnLoad: TBitBtn
      Left = 16
      Top = 16
      Width = 75
      Height = 25
      Caption = '&Carga'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 0
      OnClick = btnLoadClick
    end
    object btnTest: TBitBtn
      Left = 104
      Top = 16
      Width = 75
      Height = 25
      Caption = '&Teste'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 1
      OnClick = btnTestClick
    end
    object btnStep2: TBitBtn
      Left = 200
      Top = 16
      Width = 75
      Height = 25
      Caption = '&Teste'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 2
      OnClick = btnStep2Click
    end
  end
end
