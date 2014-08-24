object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 329
  ClientWidth = 489
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object lstPrivelege: TListBox
    Left = 56
    Top = 40
    Width = 193
    Height = 145
    ItemHeight = 13
    TabOrder = 0
  end
  object btnReadPrivileges: TButton
    Left = 128
    Top = 224
    Width = 75
    Height = 25
    Caption = 'btnReadPrivileges'
    TabOrder = 1
    OnClick = btnReadPrivilegesClick
  end
end
