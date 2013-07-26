object Form3: TForm3
  Left = 0
  Top = 0
  Caption = 'Form3'
  ClientHeight = 413
  ClientWidth = 396
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    396
    413)
  PixelsPerInch = 96
  TextHeight = 13
  object lblInputDir: TLabel
    Left = 24
    Top = 32
    Width = 130
    Height = 13
    Caption = 'Caminho de leitura(Cliente)'
  end
  object lblOutDir: TLabel
    Left = 24
    Top = 80
    Width = 110
    Height = 13
    Caption = 'Pasta Backup completo'
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
    TabOrder = 2
    OnClick = chkServerSwitchClick
  end
  object edtDirOutput: TJvDirectoryEdit
    Left = 24
    Top = 96
    Width = 345
    Height = 21
    DialogKind = dkWin32
    TabOrder = 1
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
    TabOrder = 4
    OnClick = btnStartStopClick
  end
  object memoLog: TMemo
    Left = 24
    Top = 254
    Width = 341
    Height = 151
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
  end
  object tmrCycle: TTimer
    Enabled = False
    Interval = 10000
    OnTimer = tmrCycleTimer
    Left = 264
    Top = 136
  end
end
