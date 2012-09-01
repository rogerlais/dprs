object AppMainForm: TAppMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = 'AppMainForm'
  ClientHeight = 249
  ClientWidth = 375
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblStatus: TLabel
    Left = 0
    Top = 57
    Width = 375
    Height = 13
    Align = alTop
    ExplicitWidth = 3
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 375
    Height = 57
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 373
    object btnConfig: TBitBtn
      Left = 24
      Top = 16
      Width = 75
      Height = 25
      Caption = '&Configurar'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 0
      OnClick = btnConfigClick
    end
    object btnStart: TBitBtn
      Left = 128
      Top = 16
      Width = 75
      Height = 25
      Caption = '&Iniciar'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 1
      OnClick = btnStartClick
    end
    object btnClose: TBitBtn
      Left = 232
      Top = 16
      Width = 75
      Height = 25
      Caption = '&Fechar'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 2
      OnClick = btnCloseClick
    end
  end
  object memoVerbose: TMemo
    Left = 0
    Top = 70
    Width = 375
    Height = 160
    Align = alClient
    ReadOnly = True
    TabOrder = 1
    ExplicitWidth = 373
    ExplicitHeight = 158
  end
  object stBar: TStatusBar
    Left = 0
    Top = 230
    Width = 375
    Height = 19
    Panels = <
      item
        Width = 50
      end
      item
        Width = 50
      end>
    ExplicitTop = 228
    ExplicitWidth = 373
  end
end
