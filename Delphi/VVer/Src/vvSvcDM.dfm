object VVerService: TVVerService
  OldCreateOrder = False
  OnCreate = ServiceCreate
  Dependencies = <
    item
      Name = 'Netlogon'
      IsGroup = False
    end>
  DisplayName = 'VVerService'
  ServiceStartName = 'VVer'
  BeforeInstall = ServiceBeforeInstall
  AfterInstall = ServiceAfterInstall
  OnContinue = ServiceContinue
  OnPause = ServicePause
  OnStart = ServiceStart
  Height = 150
  Width = 321
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
    Left = 54
    Top = 30
  end
  object icmpclntMain: TIdIcmpClient
    Protocol = 1
    ProtocolIPv6 = 58
    IPVersion = Id_IPv4
    PacketSize = 32
    Left = 120
    Top = 32
  end
  object fvInfo: TFileVersionInfo
    Left = 54
    Top = 84
  end
  object smtpSender: TIdSMTP
    Host = 'smtp.tre-pb.gov.br'
    SASLMechanisms = <>
    Left = 126
    Top = 88
  end
  object tmrCycleEvent: TTimer
    Enabled = False
    Interval = 60000
    OnTimer = tmrCycleEventTimer
    Left = 192
    Top = 28
  end
end
