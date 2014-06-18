object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'SESOP - Preparador de esta'#231#245'es - vers'#227'o: *********'
  ClientHeight = 299
  ClientWidth = 534
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
    Top = 232
    Width = 534
    Height = 67
    Align = alBottom
    TabOrder = 1
    object btnOk: TBitBtn
      Left = 162
      Top = 21
      Width = 75
      Height = 25
      DoubleBuffered = True
      Kind = bkOK
      ParentDoubleBuffered = False
      TabOrder = 0
    end
    object btnCancel: TBitBtn
      Left = 266
      Top = 21
      Width = 75
      Height = 25
      DoubleBuffered = True
      Kind = bkCancel
      ParentDoubleBuffered = False
      TabOrder = 1
    end
  end
  object pgcMain: TPageControl
    Left = 0
    Top = 0
    Width = 534
    Height = 232
    ActivePage = tsInfo
    Align = alClient
    TabOrder = 0
    ExplicitHeight = 209
    object tsInfo: TTabSheet
      Caption = '&Informa'#231#245'es'
      ExplicitLeft = 8
      ExplicitTop = 22
      ExplicitHeight = 181
      object lblResult: TLabel
        Left = 183
        Top = 30
        Width = 111
        Height = 13
        Caption = '&Resultado da opera'#231#227'o'
      end
      object lblNetAdapter: TLabel
        Left = 16
        Top = 129
        Width = 132
        Height = 13
        Caption = '&Adaptador de rede prim'#225'rio'
      end
      object ledtZonNumber: TLabeledEdit
        Left = 16
        Top = 48
        Width = 121
        Height = 21
        EditLabel.Width = 24
        EditLabel.Height = 13
        EditLabel.Caption = '&Zona'
        TabOrder = 0
      end
      object ledtWksId: TLabeledEdit
        Left = 16
        Top = 96
        Width = 121
        Height = 21
        EditLabel.Width = 78
        EditLabel.Height = 13
        EditLabel.Caption = '&N'#250'mero esta'#231#227'o'
        TabOrder = 1
      end
      object memoResult: TMemo
        Left = 182
        Top = 48
        Width = 283
        Height = 121
        TabOrder = 4
      end
      object cbbNetAdapter: TComboBox
        Left = 16
        Top = 146
        Width = 145
        Height = 21
        TabOrder = 2
        Text = 'cbbNetAdapter'
      end
      object chkUseDHCP: TCheckBox
        Left = 16
        Top = 180
        Width = 97
        Height = 17
        Caption = '&Usar DHCP'
        TabOrder = 3
      end
    end
  end
end
