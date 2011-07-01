object frmADUserMgr: TfrmADUserMgr
  Left = 0
  Top = 0
  Caption = 'Gerenciador de contas(AD) - Vers'#227'o: '
  ClientHeight = 450
  ClientWidth = 778
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object statbarMain: TStatusBar
    Left = 0
    Top = 431
    Width = 778
    Height = 19
    Panels = <>
    ExplicitTop = 368
    ExplicitWidth = 548
  end
  object acttbTopMain: TActionToolBar
    Left = 0
    Top = 0
    Width = 778
    Height = 29
    ActionManager = actmgrMainForm
    Caption = 'acttbTopMain'
    ColorMap.HighlightColor = clWhite
    ColorMap.BtnSelectedColor = clBtnFace
    ColorMap.UnusedColor = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Spacing = 0
    ExplicitWidth = 548
  end
  object actmgrMainForm: TActionManager
    Left = 32
    Top = 40
    StyleName = 'Platform Default'
  end
end
