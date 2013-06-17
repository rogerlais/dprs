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
  Height = 153
  Width = 339
  object tmrCycleEvent: TTimer
    Enabled = False
    Interval = 60000
    OnTimer = tmrCycleEventTimer
    Left = 64
    Top = 48
  end
  object smtpSender: TIdSMTP
    Host = 'smtp.tre-pb.gov.br'
    SASLMechanisms = <>
    Left = 145
    Top = 49
  end
  object mailMsgNotify: TIdMessage
    AttachmentEncoding = 'UUE'
    BccList = <>
    CCList = <>
    Encoding = meDefault
    FromList = <
      item
      end>
    Recipients = <>
    ReplyTo = <>
    ConvertPreamble = True
    Left = 225
    Top = 52
  end
end
