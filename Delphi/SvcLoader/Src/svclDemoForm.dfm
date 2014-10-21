object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 188
  ClientWidth = 301
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnStart: TBitBtn
    Left = 30
    Top = 24
    Width = 75
    Height = 25
    Caption = 'btnStart'
    TabOrder = 1
    OnClick = btnStartClick
  end
  object btnPause: TBitBtn
    Left = 111
    Top = 24
    Width = 75
    Height = 25
    Caption = 'btnPause'
    TabOrder = 2
  end
  object btnStop: TBitBtn
    Left = 198
    Top = 24
    Width = 75
    Height = 25
    Caption = 'btnStop'
    TabOrder = 4
    OnClick = btnStopClick
  end
  object btnClose: TBitBtn
    Left = 24
    Top = 80
    Width = 75
    Height = 25
    Caption = 'btnClose'
    TabOrder = 0
    OnClick = btnCloseClick
  end
  object btnEditConfig: TBitBtn
    Left = 111
    Top = 80
    Width = 75
    Height = 25
    Caption = 'Edit Config'
    TabOrder = 3
    OnClick = btnEditConfigClick
  end
end
