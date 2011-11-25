object FUMainWindow: TFUMainWindow
  Left = 0
  Top = 0
  Caption = 'FUMainWindow'
  ClientHeight = 247
  ClientWidth = 535
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lstFoundFiles: TListBox
    Left = 32
    Top = 24
    Width = 457
    Height = 121
    ItemHeight = 13
    TabOrder = 0
  end
  object btnSearch: TBitBtn
    Left = 56
    Top = 176
    Width = 75
    Height = 25
    Caption = '&Buscar'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 1
  end
end
