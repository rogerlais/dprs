object BioFilesService: TBioFilesService
  OldCreateOrder = False
  OnCreate = ServiceCreate
  AllowPause = False
  Dependencies = <
    item
      Name = 'Netlogon'
      IsGroup = False
    end>
  DisplayName = 'SESOP TransBio Replicator'
  BeforeInstall = ServiceBeforeInstall
  AfterInstall = ServiceAfterInstall
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 150
  Width = 215
  object tmrCycleEvent: TTimer
    Enabled = False
    Interval = 60000
    OnTimer = tmrCycleEventTimer
    Left = 64
    Top = 48
  end
end
