object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 300
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnReadUsers: TBitBtn
    Left = 48
    Top = 135
    Width = 75
    Height = 25
    Caption = 'btnReadUsers'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 0
    OnClick = btnReadUsersClick
  end
  object chklstLoggedUsers: TCheckListBox
    Left = 24
    Top = 32
    Width = 121
    Height = 97
    ItemHeight = 13
    TabOrder = 1
  end
end
