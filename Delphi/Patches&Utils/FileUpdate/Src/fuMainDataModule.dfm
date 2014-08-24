object DMMainController: TDMMainController
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
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
  object httpNotifier: TIdHTTP
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    HTTPOptions = [hoForceEncodeParams]
    Left = 184
    Top = 40
  end
end
