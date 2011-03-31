object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Lan'#231'ador do VNC Viewer'
  ClientHeight = 295
  ClientWidth = 542
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object grpHost: TGroupBox
    Left = 104
    Top = 24
    Width = 281
    Height = 145
    Caption = '[ Acesso ]'
    TabOrder = 0
    object lblCombooHosts: TLabel
      Left = 19
      Top = 26
      Width = 102
      Height = 13
      Caption = 'Nome do computador'
    end
    object lblIPHost: TLabel
      Left = 155
      Top = 26
      Width = 85
      Height = 13
      Caption = 'IP do computador'
    end
    object lblUsers: TLabel
      Left = 19
      Top = 84
      Width = 80
      Height = 13
      Caption = 'Lista de usu'#225'rios'
    end
    object cbbHosts: TComboBox
      Left = 19
      Top = 45
      Width = 117
      Height = 21
      TabOrder = 0
      Text = 'cbbHosts'
    end
    object cbbIPHost: TComboBox
      Left = 155
      Top = 45
      Width = 102
      Height = 21
      TabOrder = 1
      Text = 'cbbHosts'
    end
    object cbbUsers: TComboBox
      Left = 19
      Top = 103
      Width = 117
      Height = 21
      TabOrder = 2
      Text = 'cbbHosts'
    end
    object btnLaunch: TBitBtn
      Left = 155
      Top = 101
      Width = 75
      Height = 25
      Caption = 'Ini&ciar'
      DoubleBuffered = True
      Kind = bkYes
      ParentDoubleBuffered = False
      TabOrder = 3
    end
  end
  object btnRecentListHost: TJvRecentMenuButton
    Left = 176
    Top = 224
    Width = 121
    Height = 25
    Caption = 'btnRecentListHost'
    TabOrder = 1
  end
  object cbbTest: TComboBoxEx
    Left = 104
    Top = 184
    Width = 145
    Height = 22
    ItemsEx = <
      item
      end
      item
      end>
    TabOrder = 2
    Text = 'cbbTest'
  end
  object mrlstHost: TJvMruList
    Active = False
    Left = 416
    Top = 48
  end
end
