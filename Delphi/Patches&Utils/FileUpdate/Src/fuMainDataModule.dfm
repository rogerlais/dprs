object DMMainController: TDMMainController
  OldCreateOrder = False
  Height = 357
  Width = 592
  object srchfl1: TJvSearchFiles
    RootDirectory = 'c:\'
    FileParams.FileMasks.Strings = (
      '*.pdat')
    OnFindFile = srchfl1FindFile
    Left = 80
    Top = 40
  end
end
