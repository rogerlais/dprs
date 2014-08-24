object PthfMainForm: TPthfMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = 'Ajuste de Endere'#231'os fixos Zona eleitoral - Beta'
  ClientHeight = 162
  ClientWidth = 407
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object btnOK: TBitBtn
    Left = 184
    Top = 46
    Width = 75
    Height = 25
    Caption = '&OK'
    DoubleBuffered = True
    Kind = bkOK
    ParentDoubleBuffered = False
    TabOrder = 0
    OnClick = btnOKClick
  end
  object btnCancel: TBitBtn
    Left = 288
    Top = 46
    Width = 75
    Height = 25
    Caption = '&Fechar'
    DoubleBuffered = True
    Kind = bkClose
    ParentDoubleBuffered = False
    TabOrder = 1
    OnClick = btnCancelClick
  end
  object edtZoneId: TLabeledEdit
    Left = 40
    Top = 48
    Width = 121
    Height = 21
    EditLabel.Width = 64
    EditLabel.Height = 13
    EditLabel.Caption = 'N'#250'mero Zona'
    TabOrder = 2
  end
  object chkSetScannerPort: TCheckBox
    Left = 40
    Top = 88
    Width = 219
    Height = 17
    Caption = 'Ajustar porta scanner SCX-4828'
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
  object btnOpenHost: TBitBtn
    Left = 40
    Top = 124
    Width = 75
    Height = 25
    Caption = '&Abrir Arquivo'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 4
    OnClick = btnOpenHostClick
  end
  object fileVerMain: TFileVersionInfo
    Top = 65528
  end
  object JvCreateProcess: TJvCreateProcess
    ApplicationName = 'notepad.exe'
    WaitForTerminate = False
    Left = 160
    Top = 8
  end
end
