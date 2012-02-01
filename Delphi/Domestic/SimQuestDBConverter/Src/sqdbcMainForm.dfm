object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 524
  ClientWidth = 694
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
  object edtSourceDir: TJvDirectoryEdit
    Left = 32
    Top = 64
    Width = 409
    Height = 21
    DialogKind = dkWin32
    TabOrder = 0
    Text = 'edtSourceDir'
  end
  object edtDestDir: TJvDirectoryEdit
    Left = 32
    Top = 112
    Width = 409
    Height = 21
    DialogKind = dkWin32
    TabOrder = 1
    Text = 'edtSourceDir'
  end
  object fllstSource: TFileListBox
    Left = 32
    Top = 168
    Width = 193
    Height = 233
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 2
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 424
    Width = 694
    Height = 100
    Align = alBottom
    TabOrder = 3
    object btnConvert: TBitBtn
      Left = 88
      Top = 32
      Width = 75
      Height = 25
      Caption = 'btnConvert'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 0
    end
  end
end
