object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Bio Info Reloaded - Vers'#227'o: '
  ClientHeight = 541
  ClientWidth = 642
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object dbgrdMain: TDBGrid
    Left = 0
    Top = 93
    Width = 634
    Height = 423
    DataSource = DataModule1.dsBioFiles
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnTitleClick = dbgrdMainTitleClick
  end
  object statbar: TStatusBar
    Left = 0
    Top = 522
    Width = 642
    Height = 19
    Panels = <>
  end
  object acttbMainForm: TActionToolBar
    Left = 0
    Top = 0
    Width = 642
    Height = 36
    ActionManager = actmgrMain
    Caption = 'acttbMainForm'
    ColorMap.HighlightColor = 15660791
    ColorMap.BtnSelectedColor = clBtnFace
    ColorMap.UnusedColor = 15660791
    Spacing = 0
  end
  object ilMain: TImageList
    ColorDepth = cd32Bit
    Height = 24
    Width = 24
    Left = 24
    Top = 472
    Bitmap = {
      494C010103001300040018001800FFFFFFFF2100FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000600000001800000001002000000000000024
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000404040307070706090909080D0D0D0C0F0F0F0E0F0F0F0E0D0D
      0D0C090909080707070604040403000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000575757598E8E8EC9000000000000
      0000020202018E8E8ECD5C5C5C600A0A0A090E0E0E0D6075B2BC1443C2F80000
      000000000000000000000E3FC0FA5F72A9B7171717160A0A0A09020202016173
      7F800983E2FC0983E2FC61737F80000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000202
      02013D3D3D4370706F8B83807BAC888580B68D8984C28F8B85C68F8B85C68D89
      84C2888580B683807BAC70706F8B3F3F3F450000000000000000000000000000
      0000595957666969648869696488696964886969648869696488696964886969
      6488696964886969648869696488696964886969648869696488696964886969
      648869696488696964885959576600000000A3A3A3D1818181FF000000000000
      000000000000818181FF9F9F9FD4151515145D74B7CA4F7BEEFF0D3DC0FC0000
      000000000000000000000D3DBFFB4572ECFF6077B3C515151514131313121087
      E4F94EBFFCFF0393F0FF1E96E8F9000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000002020201020202010C0D0D0C0E0F0F0E02020201020202010000
      0000262625279A8044EA9F7D2DFD9F7D2DFD9F7D2DFD9F7D2DFD9F7D2DFD9F7D
      2DFD9F7D2DFD9F7D2DFD9A8044EA282727290000000000000000000000000000
      000069696585F9F9E8FFF3F3E2FFF3F3E2FFF3F3E2FFF3F3E2FFF3F3E2FFF3F3
      E2FFF3F3E2FFF3F3E2FFF3F3E2FFF3F3E2FFF3F3E2FFF3F3E2FFF3F3E2FFF3F3
      E2FFF3F3E2FFF9F9E8FF6969658500000000ABABABFB919191D4000000000000
      000000000000919191D5AAAAAAFB1B1B1B1A2857D2FC6A89E5FF0C3ABFFD0000
      000000000000000000000A39BFFD6A8DF7FF3360DBF41B1B1B1A2020201F0A81
      D9FF85D5FDFF0389EBFF42BCFDFF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000232628282D3337380202
      02010909090840596A702681BBD30686D9FB0685D8FB2083C2DC4160747B0C0C
      0C0B43413C4BA28030FDA3802FFDA48130FEA48130FEA48130FEA48130FEA481
      30FEA48130FEA48130FEA3802FFD44413A4B0000000000000000000000000000
      000069696580F3F3E3FFE7E7D7FFE7E7D7FFE7E7D7FFE7E7D7FFE7E7D7FFE7E7
      D7FFE7E7D7FFE7E7D7FFE7E7D7FFE7E7D7FFE7E7D7FFE7E7D7FFE7E7D7FFE7E7
      D7FFE7E7D7FFF3F3E3FF6969658000000000A3A3A3D1BEBEBEFF8D8D8DA22929
      29288D8D8DA2BFBFBFFFA3A3A3D3040404032352D3FF7591E6FF0C3AB0FF0404
      04030000000000000000083AC0FE7D9CFCFF2457E1FC040404031B1B1B1A0B7E
      D3FF96CFECFF0482E5FF54C6FFFF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000003E525F641883CAE73743
      4B4D2780BAD10587DAFC0388DCFE0388DCFE0885D7F93F6D8A9630373B3C353C
      41424545404FA88434FDAA8535FEAA8535FEAA8535FEAA8535FEAA8535FEAA85
      35FEAA8535FEAA8535FEA88334FD45423B4C0000000000000000000000000000
      00006868647CF4F4E5FFE8E8D9FFFFCC47FFFECB46FFFDCA45FFEBD185FFD8D8
      C7FFD7D7C6FFD5D5C4FFD4D4C3FFD2D2C1FFD1D1C0FFCFCFBEFFCECEBDFFCDCD
      BCFFE8E8D9FFF4F4E5FF6868647C000000004B4B4B4CC8C8C8FFBDBDBDFFACAC
      ACFFBEBEBEFFCDCDCDFF4B4B4B4C000000001C50E0FF819DECFF0D3AAEFF1B1B
      1B1A0404040300000000083AC0FE81A0FDFF1E52E3FF00000000040404030A78
      D2FFB0D6E9FF0A78D2FF64CAFDFF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000202020141647A82058ADDFC0489
      DCFD0489DCFD0489DCFD058ADDFC2683BCD32B31343502020201000000000202
      020145433C4CAD8A3AFCAF8A3AFEAF8A3AFEAF8A3AFEAF8A3AFEAF8A3AFEAF8A
      3AFEAF8A3AFEAF8A3AFEAD893AFC46433B4C0000000000000000000000000000
      000067676378F4F4E6FFE9E9DBFFFFCC47FFFFEE88FFFEED87FFEBD185FFF4F4
      EDFFF4F4EDFFD5D5C4FFF4F4EDFFF4F4EDFFD1D1C0FFF4F4EDFFF4F4EDFFCDCD
      BCFFE9E9DBFFF4F4E6FF67676378000000000000000060606064C0C1C1FFD4D4
      D4FFCACACAFF5353535500000000000000001B50E2FF87A6FDFF0C3AB0FF2020
      201F1B1B1B1A04040403083AC0FE87A6FFFF1B50E2FF0000000000000000047D
      E0FFB2D9ECFF0B77CFFF62C2F2FF020202010000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000020202013D78959F0498E5FD0399
      E6FE0399E6FE0598E4FC3582AAB70D0E0E0D0000000000000000000000000000
      000045423B4BB38D3FFDB58F3FFEB58F3FFEB58F3FFEB58F3FFEB58F3FFEB58F
      3FFEB58F3FFEB58F3FFEB48D3EFD46433C4C0000000000000000000000000000
      000067676377F5F5E7FFEAEADDFFFFCC47FFFFEE88FFFEED87FFEBD185FFF5F5
      EEFFF5F5EEFFD5D5C4FFF5F5EEFFF5F5EEFFD1D1C0FFF5F5EEFFF5F5EEFFCDCD
      BCFFEAEADDFFF5F5E7FF6767637700000000000000000A0A0A09A1A1A1FFBDBD
      BDFFA8A8A8FF0000000000000000000000001C51E2FF88A7FFFF0738BBFF1B1B
      1B1A2020201F1B1B1B1A093ABEFE87A6FFFF2255E2FD0000000000000000037E
      E2FFBDE8FDFF0A78D2FF61C0F0FF0A0A0A090000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000002020201338CB2BB04A7EEFD03A8
      EFFE03A8EFFE179FDCE80D0E0E0D020202010000000000000000000000000000
      000046423C4BB99243FDBB9343FEBB9343FEBB9343FEBB9343FEBB9343FEBB93
      43FEBB9343FEBB9343FEB99243FD47443C4C0000000000000000000000000000
      000066666275F6F6E9FFECECDFFFA89B70FF8E8D7CFFD2B35BFFEBD185FFD8D8
      C7FFD7D7C6FFDBDBCBFFD4D4C3FFD2D2C1FFD8D8C8FFCFCFBEFFCECEBDFFCDCD
      BCFFECECDFFFF6F6E9FF66666275000000000000000002020201A2A2A2FFD2D3
      D3FF9E9F9FFF0404040300000000000000002A59E3FB88A7FFFF1240BFFB0404
      04031B1B1B1A2020201F113BB4FD81A0FBFF2A5AE3FB0000000000000000037E
      E2FFBFEAFFFF047DE0FF62C2F2FF0B0B0B0A0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000002020201319FC7CC05B5F6FC05B5
      F6FC05B4F6FC06B3F5FB40647172000000000000000000000000000000000000
      000046433C4BBE984AFCC09848FEC09848FEC09848FEC09848FEC09848FEC098
      48FEC09848FEC09848FEBE984AFC47443D4C0000000000000000000000000000
      000066666274F6F6EBFFEDEDE1FF8F8F81FFFFFFFCFFA4A181FFCEC08FFFF6F6
      F1FFF6F6F1FFD5D5C4FFF6F6F1FFF6F6F1FFD1D1C0FFF6F6F1FFF6F6F1FFCDCD
      BCFFEDEDE1FFF6F6EBFF66666274000000000000000000000000A8A8A8FFE1E2
      E2FF9C9D9DFF1B1B1B1A04040403000000004B72DFEF81A1FEFF1845C3F90000
      0000040404031B1B1B1A1741B2FB7A95EAFF5075DCEA00000000000000000383
      E7FFA0DFFFFF0383E7FF54C5FDFF0A0A0A090000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000025292B2A435961614969
      74754B7888894A869C9C4590A9AA0C0D0D0C0000000000000000000000000000
      000047433C4BC69C4EFDC59D4DFEC59D4DFEC59D4DFEC59D4DFEC59D4DFEC59D
      4DFEC59D4DFEC59D4DFEC69C4EFD48443D4C0000000000000000000000000000
      000066666273F7F7ECFFEFEFE4FF959584FFFFFFFCFFFFFCE9FFB6AD88FFE5E5
      DEFFF7F7F2FFD5D5C4FFF7F7F2FFF7F7F2FFD1D1C0FFF7F7F2FFF7F7F2FFCDCD
      BCFFEFEFE4FFF7F7ECFF66666273000000000000000000000000A9A9A9FFF8F8
      F8FF9E9F9FFF2020201F1B1B1B1A04040403748AC7CB7E9DFEFF1E4CC7F90000
      00000000000004040403143FB9FD6D8AE4FF788ABCC904040403000000000389
      EBFF86D7FFFF0389EBFF47C1FFFF020202010000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000020202010202
      0201030303020303030202020201020202010000000000000000000000000000
      000047443D4BCCA356FDCBA252FECBA253FECBA253FECBA252FECBA253FECBA2
      53FECBA252FECBA253FECDA356FD49453E4C0000000057575560696965806969
      6580696965809B9B8AFF9B9B8AFF9B9B8AFFFFFEFAFFFFF6DCFFF6EED3FFC1C1
      B0FFD1D1C0FFDCDCCDFFD4D4C3FFD2D2C1FFD9D9CAFFCFCFBEFFCECEBDFFCDCD
      BCFFF0F0E6FFF8F8EEFF65656272000000000000000000000000A9A9A9FFFFFF
      FFFFA8A8A8FF1B1B1B1A2020201F1B1B1B1A7785AAAC7093FCFF1E4ED0FF1717
      171600000000212222210E40C8FF597EE3FF7984A2AC1B1B1B1A040404030396
      F2FF56C6FFFF0396F2FF2DB8FFFF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000006060605181818182B2B2B2D3939
      3A3E4444464D4A4A505A4B4B515C474749523D3D3D432F2F2F321E1E1E1E0B0B
      0B0A2E2D2B2FDBB973FAD6AF65FCD5B066FDD5B066FDD6AF65FCD5B066FDD5B0
      66FDD6AF65FCD5B066FDDBB972FA2F2D2A2F000000006969647DFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFCFFFFFCE9FFF6EED3FFFCFC
      F9FFFAFAF7FFD5D5C4FFF9F9F4FFF9F9F4FFD1D1C0FFF9F9F4FFF9F9F4FFCDCD
      BCFFF2F2E9FFF9F9F0FF64646170000000000000000000000000A9A9A9FFFFFF
      FFFFA9A9A9FF040404031B1B1B1A2020201F6D7383885580F6FF1D4DD0FF5356
      5D5F000000005A5E696D0C3FCAFF3868EBFF6B707C812020201F0A8CDFFF0481
      E4FF037EE2FF037EE2FF0382E6FF0394F1FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000004B4B4B54878791C86363A4EB3333
      A8F61C1CA6FC1A1AA1FC19199DFC181897FC232392F9565693EE8A8A93D46969
      697F0808080743403B45756D5D7C766E5E7D766E5E7D766E5E7D766E5E7D766E
      5E7D766E5D7D756C5C7B44413C46020202010000000067676379FFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFCFFFFFCE9FFF6EED3FFFCFC
      FAFFFBFBF8FFD5D5C4FFFAFAF6FFFAFAF6FFD1D1C0FFFAFAF6FFFAFAF6FFCDCD
      BCFFF4F4ECFFFAFAF2FF6363606F000000000000000000000000A9A9A9FFFFFF
      FFFFA9A9A9FF00000000040404031B1B1B1A4F5053554D76E3FF1D4CCDFF5D6E
      A0B600000000556BA5C00B3FCAFF3465ECFF363738371B1B1B1A668290970A9F
      ECFF6DCCFDFF6ECEFFFF03AAFFFF637B87870000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000151515153B3BB9F21E1EB3FD1A1A
      AEFE1818A8FE1616A3FE15159DFE141497FE131390FD11118BFE232386F11B1B
      1B1B000000000202020124262728252728291616161609090908040404030303
      0302020202010202020100000000000000000000000052525158666662756666
      627566666275B0B09FFFB0B09FFFB0B09FFFFFFEFAFFFFF6DDFFF6EED3FFC9C9
      B8FFD3D3C2FFDDDDCFFFD4D4C3FFD2D2C1FFDADACCFFCFCFBEFFCECEBDFFCDCD
      BCFFF5F5EFFFFAFAF4FF6363606E000000000000000002020201A9A9A9FFFFFF
      FFFFA9A9A9FF000000000000000004040403212121204E72D9F81D4AC0FF143F
      B4F7000000000D3AB6FA093DC9FF3F6AE2F305050504040404031B1B1B1A2020
      201FB5B5B5FF919191FF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000020202015A5A9BB41D1DB4FD1A1A
      AFFE1818A9FE1616A3FE15159DFE131397FE121291FE11118AFD3C3C76B40202
      0201000000000000000041647A830787D8FA0786D9FB0C87D4F61984CAE62F7E
      B1C6121213120000000000000000000000000000000000000000000000000000
      00006363606DFBFBF6FFF7F7F1FFB6B6A5FFFFFFFCFFFFFCE9FFCAC29DFFEEEE
      E9FFFBFBF8FFD5D5C4FFFBFBF8FFFBFBF8FFD1D1C0FFFBFBF8FFFBFBF8FFCDCD
      BCFFF7F7F1FFFBFBF6FF6363606D00000000000000000A0A0A09A8A8A8FFFAFA
      FAFFA9A9A9FF000000000000000000000000043DD9FF0A3ECBFF4C72DAFF7A95
      E9FF87A6FDFF809EFCFF4D78EFFF033DDBFF033DDBFF00000000040404031B1B
      1B1AC4C4C4FF808080FF03030302000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000002C2C31323232BCFB1A1A
      AFFE1818A9FE1616A3FE15159DFE131397FE131390FD131389FB2D2D33380000
      00000000000000000000050505043679A3B40388DCFE0487DBFD0388DCFE0588
      DBFC1D1F20200000000000000000000000000000000000000000000000000000
      00006262606CFCFCF8FFF8F8F4FFBDBDACFFFFFFFCFFC9C6A5FFDACD9CFFFCFC
      FAFFFCFCFAFFD5D5C4FFFCFCFAFFFCFCFAFFD1D1C0FFFCFCFAFFFCFCFAFFCDCD
      BCFFF8F8F4FFFCFCF8FF6262606C00000000000000000B0B0B0AA2A2A2FFF3F3
      F3FFA9A9A9FF000000000000000000000000636B8589043DD9FF0A3ECBFF0B3E
      C9FF0A3ECBFF043DD9FF033DDBFF033DDBFF636B828700000000000000000404
      0403CFD0D0FF7F7F7FFF13131312020202010000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000020202015A5A91A71A1A
      AFFE1818A9FE1616A3FE15159DFE131397FE131390FD3E3E79B0020202010000
      00000000000000000000191B1C1B2186C3DB038DDFFE038EE0FE0390E1FE0E92
      DDF70A0A0A090000000000000000000000000000000000000000000000000000
      000062625F6BFDFDF9FFFAFAF6FFD2C596FFC5C3AFFFE7C770FFF4CD66FFE9D0
      83FFE8CF82FFE6CD81FFE5CC81FFE3CA80FFE2C97FFFE0C77DFFDFC67CFFDEC5
      7BFFFAFAF6FFFDFDF9FF62625F6B00000000000000000A0A0A09A1A1A1FFD8D8
      D8FFA8A8A8FF00000000000000000000000000000000636B85893B59A7FF676C
      7AFF707070FF696D79FF415CA2FF636B85890000000000000000000000000000
      0000DFDFDFFF858585FF151515140A0A0A090000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000242427273636
      B9F81919A8FD1616A3FE15159DFE141596FD151590FB28282C2F000000000000
      000002020201282D3030218EC7DA0496E4FD0498E5FD049AE6FD049CE7FD2298
      D2E2030303020000000000000000000000000000000000000000000000000000
      000061615E6AFDFDFAFFFBFBF8FFFFCC47FFFFEE88FFFEED87FFFCC944FFFBEA
      84FFF9E882FFF7C43FFFF6E581FFF4E380FFF3C03BFFF0DF7CFFEFDE7BFFEFBC
      37FFFBFBF8FFFDFDFAFF61615E6A000000000000000002020201A2A2A2FFC0C0
      C0FF9E9F9FFF0404040300000000000000000000000000000000000000009898
      98FFC2C2C2FF8E8F8FFF1B1B1B1A040404030000000000000000000000000000
      0000E0E0E0FF969696FF131313120B0B0B0A0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000020202015959
      85991A1AA9FD1717A2FD15159DFE131497FE424579A50A0A0A09020202010C0C
      0C0B41687B7F0C9CE3F504A1EAFD03A4ECFE04A5ECFD379BC6D018A8E6F23494
      BCC5020202010000000000000000000000000000000000000000000000000000
      000061615E69FEFEFCFFFCFCFAFFFFCC47FFFFEE88FFFEED87FFFCC944FFFBEA
      84FFF9E882FFF7C43FFFF6E581FFF4E380FFF3C03BFFF0DF7CFFEFDE7BFFEFBC
      37FFFCFCFAFFFEFEFCFF61615E69000000000000000076767686838383FB7677
      77FF7E7F7FFB7B7C7C93040404030000000000000000000000009B9B9BFFA2A2
      A2FFEAEAEAFF989898FF909191FF1B1B1B1A0404040300000000000000000000
      0000D6D6D6FFA2A2A2FF030303020A0A0A090000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000001C1C
      1D1D3B3BB4F41717A2FD15159DFE181894F8222225261C1D1F1E426E82861E9F
      D8E206AAEDFB04ACF0FD05ACF0FC1BAFEBF54B788A8D0C0C0C0B3C4B51514786
      9DA1020202010000000000000000000000000000000000000000000000000000
      000060605D68FEFEFDFFFDFDFCFFFFCC47FFFECB46FFFDCA45FFFCC944FFFAC7
      42FFF9C641FFF7C43FFFF6C33EFFF4C13CFFF3C03BFFF1BE39FFF0BD38FFEFBC
      37FFFDFDFCFFFEFEFDFF60605D680000000073737381898989FFC1C1C1FFDBDB
      DBFFB4B4B4FF818181FF7979798E040404030000000000000000979797FFABAB
      ABFFD7D7D7FFAAAAAAFF8E8E8EFF2020201F1B1B1B1A04040403000000000000
      0000C2C2C2FFA9A9A9FF00000000020202010000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000202
      020156567A8B1A1AA2FC17179DFC454573980202020100000000040404033540
      444449707E814A798A8D465F68691A1B1C1B0202020100000000000000000505
      0504000000000000000000000000000000000000000000000000000000000000
      000060605D68FFFFFFFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFE
      FEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFE
      FEFFFEFEFEFFFFFFFFFF60605D6800000000949494E9C0C0C0FF9C9C9CB22F2F
      2F2E9C9C9CB3B2B2B2FF8C8C8CEC1B1B1B1A0404040300000000A0A0A0FFB4B4
      B4FF4F4F4F50B4B4B4FF9F9F9FFF1B1B1B1A2020201F1B1B1B1A040404037B7B
      7B87A9A9A9FFA9A9A9FF70707078000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000151516154141AFED1E1E99F21A1A1C1C0000000000000000000000000000
      0000020202010202020100000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000060605D67FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFF60605D6700000000A0A0A0FC929292D6000000000000
      000000000000929292D79B9C9CFC151515141313131203030302B1B1B1D9BDBD
      BDFF00000000BDBDBDFFB1B1B1D703030302131313121515151413131312A8A8
      A8FFA9A9A9FFA9A9A9FFA9A9A9FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000020202013D3D494E40404E57020202010000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00004A4A494D5F5F5C665F5F5C665F5F5C665F5F5C665F5F5C665F5F5C665F5F
      5C665F5F5C665F5F5C665F5F5C665F5F5C665F5F5C665F5F5C665F5F5C665F5F
      5C665F5F5C665F5F5C664A4A494D00000000A3A3A3D1818181FF000000000000
      000000000000818181FFA3A3A3D10A0A0A090B0B0B0A0A0A0A097C7C7C84C1C1
      C1FF51515152C1C1C1FF7C7C7C8300000000020202010A0A0A090B0B0B0ACDCD
      CDFFD8D8D8FFD9D9D9FFD2D2D2FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000555555578E8E8EC9000000000000
      0000000000008E8E8ECB555555570000000000000000000000002D2D2D2CC1C1
      C1FFE1E1E1FFC1C1C1FF2D2D2D2C00000000000000000000000000000000C7C7
      C7FFC7C7C7FFC7C7C7FFC7C7C7FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000060000000180000000100010000000000200100000000000000000000
      000000000000000000000000FFFFFF00FFF801FFFFFF000000000000FFE000F0
      0001000000000000F81000F00001000000000000800000F00001000000000000
      800000F00001000000000000002000F0000100000000000000F000F000010000
      0000000000F000F0000100000000000001F000F0000100000000000080F000F0
      0001000000000000C0F000800001000000000000000000800001000000000000
      000000800001000000000000000803800001000000000000000C07F000010000
      00000000801C07F00001000000000000801C07F00001000000000000C03007F0
      0001000000000000C00007F00001000000000000E00007F00001000000000000
      E0406FF00001000000000000F0F3FFF00001000000000000F0FFFFF000010000
      00000000FFFFFFFFFFFF000000000000}
  end
  object actmgrMain: TActionManager
    ActionBars = <
      item
        Items.CaptionOptions = coAll
        Items.SmallIcons = False
        Items = <>
      end
      item
      end
      item
        Items = <
          item
            Action = actReadClipboard
            Caption = '&Importar'#13#10#193'rea Transfer'#234'ncia'
            ImageIndex = 0
          end
          item
            Action = actLocate
            Caption = '&Localizar'
            ImageIndex = 1
          end
          item
            Action = actConfig
            Caption = '&Configura'#231#245'es'
            ImageIndex = 2
          end>
        ActionBar = acttbMainForm
      end>
    Images = ilMain
    Left = 80
    Top = 472
    StyleName = 'Platform Default'
    object actReadClipboard: TAction
      Caption = 'Importar'#13#10#193'rea Transfer'#234'ncia'
      ImageIndex = 0
    end
    object actConfig: TAction
      Caption = 'Configura'#231#245'es'
      ImageIndex = 2
    end
    object actLocate: TAction
      Caption = 'Localizar'
      ImageIndex = 1
    end
  end
end