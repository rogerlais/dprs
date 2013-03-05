object Form3: TForm3
  Left = 0
  Top = 0
  Caption = 'Form3'
  ClientHeight = 243
  ClientWidth = 401
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblInputDir: TLabel
    Left = 24
    Top = 32
    Width = 49
    Height = 13
    Caption = 'lblInputDir'
  end
  object lblOutDir: TLabel
    Left = 24
    Top = 80
    Width = 49
    Height = 13
    Caption = 'lblInputDir'
  end
  object edtDir: TJvDirectoryEdit
    Left = 24
    Top = 48
    Width = 345
    Height = 21
    DialogKind = dkWin32
    TabOrder = 0
    Text = 'edtDir'
  end
  object chkServerSwitch: TCheckBox
    Left = 24
    Top = 160
    Width = 137
    Height = 17
    Caption = '&Modo Servidor/Cliente'
    TabOrder = 1
  end
  object edtDirOutput: TJvDirectoryEdit
    Left = 24
    Top = 96
    Width = 345
    Height = 21
    DialogKind = dkWin32
    TabOrder = 2
    Text = 'edtDir'
  end
  object btnStartStop: TBitBtn
    Left = 168
    Top = 200
    Width = 75
    Height = 25
    Caption = '&Iniciar'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 3
    OnClick = btnStartStopClick
  end
end
