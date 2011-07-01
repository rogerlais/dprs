object FrameStatusOperation: TFrameStatusOperation
  Left = 0
  Top = 0
  Width = 451
  Height = 304
  Align = alClient
  TabOrder = 0
  DesignSize = (
    451
    304)
  object lblStatus: TLabel
    AlignWithMargins = True
    Left = -31
    Top = 50
    Width = 514
    Height = 38
    Alignment = taCenter
    Anchors = []
    AutoSize = False
    Caption = 'Carregando informa'#231#245'es dos bancos de dados'
    ExplicitLeft = 121
    ExplicitTop = 63
  end
  object pbStatus: TProgressBar
    Left = -31
    Top = 100
    Width = 514
    Height = 38
    Anchors = []
    TabOrder = 0
  end
  object btnCancel: TBitBtn
    Left = 183
    Top = 152
    Width = 86
    Height = 27
    Anchors = []
    Caption = '&Cancelar'
    DoubleBuffered = True
    Kind = bkCancel
    ParentDoubleBuffered = False
    TabOrder = 1
  end
end
