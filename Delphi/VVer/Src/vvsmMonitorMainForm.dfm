object VVMMonitorMainForm: TVVMMonitorMainForm
  Left = 0
  Top = 0
  Caption = 'Verificador de vers'#245'es'
  ClientHeight = 359
  ClientWidth = 632
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  DesignSize = (
    632
    359)
  PixelsPerInch = 96
  TextHeight = 13
  object btnOK: TBitBtn
    Left = 269
    Top = 293
    Width = 100
    Height = 57
    Anchors = []
    Caption = '&Fechar'
    DoubleBuffered = True
    Kind = bkOK
    Layout = blGlyphTop
    ParentDoubleBuffered = False
    Spacing = 0
    TabOrder = 3
    OnClick = btnOKClick
  end
  object grdList: TListView
    Left = 8
    Top = 57
    Width = 616
    Height = 230
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <>
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    GridLines = True
    ReadOnly = True
    RowSelect = True
    ParentFont = False
    TabOrder = 1
    ViewStyle = vsReport
    OnAdvancedCustomDrawItem = grdListAdvancedCustomDrawItem
    OnClick = grdListClick
  end
  object pnlLog: TPanel
    Left = 55
    Top = 92
    Width = 517
    Height = 173
    Caption = '....'
    ShowCaption = False
    TabOrder = 2
    Visible = False
    object lblStatus: TLabel
      Left = 32
      Top = 24
      Width = 457
      Height = 121
      Alignment = taCenter
      AutoSize = False
      Caption = 'Carregando informa'#231#245'es das vers'#245'es'#13#10'Aguarde...'
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 632
    Height = 51
    Align = alTop
    TabOrder = 0
    object lblMainLabel: TLabel
      Left = 8
      Top = 10
      Width = 258
      Height = 13
      Caption = 'SESOP - Verificador de Vers'#245'es de Sistemas 2010 - T1'
    end
    object lblProfLabel: TLabel
      Left = 9
      Top = 29
      Width = 34
      Height = 13
      Caption = 'Perfil : '
    end
    object lblProfile: TLabel
      Left = 55
      Top = 29
      Width = 40
      Height = 13
      Caption = '----------'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
  end
end
