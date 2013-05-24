object EditConfigForm: TEditConfigForm
  Left = 0
  Top = 0
  Caption = 'EditConfigForm'
  ClientHeight = 460
  ClientWidth = 690
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object pnlBottom: TPanel
    Left = 0
    Top = 396
    Width = 690
    Height = 64
    Align = alBottom
    TabOrder = 0
    ExplicitTop = 344
    ExplicitWidth = 641
    DesignSize = (
      690
      64)
    object btnOk: TBitBtn
      Left = 378
      Top = 19
      Width = 110
      Height = 25
      Anchors = []
      DoubleBuffered = True
      Kind = bkCancel
      ParentDoubleBuffered = False
      TabOrder = 0
    end
    object btnCancel: TBitBtn
      Left = 202
      Top = 19
      Width = 110
      Height = 25
      Anchors = []
      DoubleBuffered = True
      Kind = bkOK
      ParentDoubleBuffered = False
      TabOrder = 1
    end
  end
end
