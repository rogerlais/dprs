object DMMainController: TDMMainController
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 357
  Width = 592
  object FileSearcher: TJvSearchFiles
    RootDirectory = 'd:\'
    Options = [soAllowDuplicates, soCheckRootDirValid, soSearchDirs, soSearchFiles, soIncludeSystemHiddenFiles]
    FileParams.SearchTypes = [stFileMask]
    FileParams.FileMasks.Strings = (
      'AcessoCli.exe'
      'Atualizador.exe'
      'SRH.exe')
    OnFindFile = FileSearcherFindFile
    Left = 80
    Top = 40
  end
end
