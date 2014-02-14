object FormMain: TFormMain
  Left = 277
  Top = 146
  Align = alClient
  BorderStyle = bsNone
  Caption = 'SESOP - Screensaver'
  ClientHeight = 453
  ClientWidth = 688
  Color = clBlack
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  Visible = True
  WindowState = wsMaximized
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object scrlngcrdts1: TScrollingCredits
    AlignWithMargins = True
    Left = 24
    Top = 24
    Width = 656
    Height = 409
    Credits.Strings = (
      'TScrollingCredits'
      #175#175#175#175#175#175#175#175#175#175#175#175#175#175
      'Copyright '#169'2000 Saturn Laboratories'
      ''
      'Please let me know if you find'
      'this component useful'
      'components@saturnlaboratories.gq.nu')
    CreditsFont.Charset = DEFAULT_CHARSET
    CreditsFont.Color = clWhite
    CreditsFont.Height = -43
    CreditsFont.Name = 'Tahoma'
    CreditsFont.Style = []
    BackgroundColor = clBlack
    BorderColor = clBlack
    Animate = True
    Interval = 50
  end
  object tmrMain: TTimer
    Interval = 10000
    OnTimer = tmrMainTimer
    Left = 328
    Top = 216
  end
end
