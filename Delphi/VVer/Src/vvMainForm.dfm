object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = 'Verificador de Vers'#245'es 2010 T1'
  ClientHeight = 354
  ClientWidth = 563
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblMainLabel: TLabel
    Left = 32
    Top = 21
    Width = 258
    Height = 13
    Caption = 'SESOP - Verificador de Vers'#245'es de Sistemas 2010 - T1'
  end
  object btnOK: TBitBtn
    Left = 240
    Top = 288
    Width = 75
    Height = 25
    DoubleBuffered = True
    Kind = bkOK
    ParentDoubleBuffered = False
    TabOrder = 0
    OnClick = btnOKClick
  end
  object grdList: TEnhStringGrid
    Left = 32
    Top = 40
    Width = 489
    Height = 217
    ColCount = 3
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goColMoving]
    TabOrder = 1
    ColWidths = (
      288
      102
      88)
  end
end
