object VMCloneMainForm: TVMCloneMainForm
  Left = 0
  Top = 0
  Caption = 'VMWare Safe Clone Utility'
  ClientHeight = 171
  ClientWidth = 398
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object ExecBtn: TButton
    Left = 160
    Top = 99
    Width = 75
    Height = 25
    Caption = 'E&xecutar'
    TabOrder = 0
  end
  object ComputerNameEdit: TLabeledEdit
    Left = 105
    Top = 45
    Width = 185
    Height = 21
    EditLabel.Width = 59
    EditLabel.Height = 13
    EditLabel.Caption = '&Computador'
    TabOrder = 1
  end
end
