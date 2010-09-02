object Form1: TForm1
  Left = 307
  Top = 197
  BorderIcons = [biMaximize]
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 472
  ClientWidth = 688
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblHora: TLabel
    Left = 16
    Top = 256
    Width = 485
    Height = 213
    Caption = 'lblHora'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -187
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
  end
  object lblData: TLabel
    Left = 24
    Top = 16
    Width = 695
    Height = 302
    Caption = 'lblHora'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -267
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 656
  end
  object scrSuppressor: TJvScreenSaveSuppressor
    Left = 616
  end
end
