object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Depura'#231#227'o VVer'
  ClientHeight = 105
  ClientWidth = 496
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnStart: TButton
    Left = 48
    Top = 40
    Width = 125
    Height = 25
    Caption = 'btnStartServervice'
    TabOrder = 0
    OnClick = btnStartClick
  end
  object btnStop: TButton
    Left = 320
    Top = 40
    Width = 125
    Height = 25
    Caption = 'btnStop'
    TabOrder = 2
  end
  object btnStartClient: TButton
    Left = 184
    Top = 40
    Width = 125
    Height = 25
    Caption = 'btnPauseService'
    TabOrder = 1
    OnClick = btnStartClientClick
  end
end
