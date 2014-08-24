object MainDM: TMainDM
  OldCreateOrder = False
  Left = 450
  Top = 208
  Height = 255
  Width = 215
  object InstallProcess: TJvCreateProcess
    OnTerminate = InstallProcessTerminate
    Left = 80
    Top = 16
  end
  object UninstallProcess: TJvCreateProcess
    OnTerminate = UninstallProcessTerminate
    Left = 80
    Top = 88
  end
end
