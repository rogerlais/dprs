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
    Left = 24
    Top = 24
    Width = 75
    Height = 25
    Caption = 'btnStart'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 0
    OnClick = btnStartClick
  end
  object btnPause: TBitBtn
    Left = 111
    Top = 24
    Width = 75
    Height = 25
    Caption = 'btnPause'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 1
  end
  object btnStop: TBitBtn
    Left = 198
    Top = 24
    Width = 75
    Height = 25
    Caption = 'btnStop'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 2
  end
  object btnClose: TBitBtn
    Left = 24
    Top = 80
    Width = 75
    Height = 25
    Caption = 'btnClose'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 3
    OnClick = btnCloseClick
  end
  object btnRegister: TBitBtn
    Left = 111
    Top = 80
    Width = 75
    Height = 25
    Caption = 'Registro'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 4
    OnClick = btnRegisterClick
  end
  object btnGetDomain: TBitBtn
    Left = 105
    Top = 136
    Width = 75
    Height = 25
    Caption = 'btnServiceLogon'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 6
    OnClick = btnGetDomainClick
  end
  object tmrServiceThread: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmrServiceThreadTimer
    Left = 224
    Top = 80
  end
end
