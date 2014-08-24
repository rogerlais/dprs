object ConfigForm: TConfigForm
  Left = 0
  Top = 0
  Caption = 'Configura'#231#245'es'
  ClientHeight = 308
  ClientWidth = 501
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lblOrderedPath: TLabel
    Left = 32
    Top = 21
    Width = 168
    Height = 13
    Caption = 'Caminho para arquivos ordenados:'
  end
  object edtDirOrderedPath: TJvDirectoryEdit
    Left = 32
    Top = 40
    Width = 273
    Height = 21
    DialogKind = dkWin32
    TabOrder = 1
    Text = 'edtDirOrderedPath'
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 228
    Width = 501
    Height = 80
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 224
    ExplicitWidth = 643
    DesignSize = (
      501
      80)
    object btnOk: TBitBtn
      Left = 157
      Top = 27
      Width = 75
      Height = 25
      Anchors = []
      DoubleBuffered = True
      Kind = bkOK
      ParentDoubleBuffered = False
      TabOrder = 0
      ExplicitLeft = 160
    end
    object btnCancel: TBitBtn
      Left = 268
      Top = 27
      Width = 75
      Height = 25
      Anchors = []
      Caption = 'Cancelar'
      DoubleBuffered = True
      Kind = bkCancel
      ParentDoubleBuffered = False
      TabOrder = 1
      ExplicitLeft = 272
    end
  end
end
