object BioFilesService: TBioFilesService
  OldCreateOrder = False
  OnCreate = ServiceCreate
  Dependencies = <
    item
      Name = 'Netlogon'
      IsGroup = False
    end>
  DisplayName = 'SESOP TransBio Replicator'
  Interactive = True
  WaitHint = 1000
  BeforeInstall = ServiceBeforeInstall
  AfterInstall = ServiceAfterInstall
  OnContinue = ServiceContinue
  OnPause = ServicePause
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 236
  Width = 339
  object tmrCycleEvent: TTimer
    Enabled = False
    Interval = 60000
    OnTimer = tmrCycleEventTimer
    Left = 184
    Top = 4
  end
  object smtpSender: TIdSMTP
    Host = 'smtp.tre-pb.gov.br'
    SASLMechanisms = <>
    Left = 126
    Top = 120
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
    Left = 126
    Top = 62
  end
  object fvInfo: TFileVersionInfo
    Left = 126
    Top = 4
  end
  object icmpclntMain: TIdIcmpClient
    Protocol = 1
    ProtocolIPv6 = 58
    IPVersion = Id_IPv4
    PacketSize = 32
    OnReply = icmpclntMainReply
    Left = 200
    Top = 64
  end
end
