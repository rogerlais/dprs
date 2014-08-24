object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 300
  ClientWidth = 535
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnUsers: TButton
    Left = 207
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btnUsers'
    TabOrder = 0
    OnClick = btnUsersClick
  end
  object lstUsers: TListBox
    Left = 32
    Top = 8
    Width = 169
    Height = 177
    ItemHeight = 13
    TabOrder = 1
  end
  object btnTest2: TButton
    Left = 216
    Top = 88
    Width = 75
    Height = 25
    Caption = 'btnTest2'
    TabOrder = 2
    OnClick = btnTest2Click
  end
end
