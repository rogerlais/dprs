object dtmdMain: TdtmdMain
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 267
  Width = 466
  object httpLoader: TIdHTTP
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentRangeInstanceLength = -1
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoForceEncodeParams]
    Left = 25
    Top = 28
  end
  object smtpSender: TIdSMTP
    Host = 'smtp.tre-pb.gov.br'
    SASLMechanisms = <>
    Left = 161
    Top = 28
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
    Left = 89
    Top = 28
  end
  object fvVersion: TFileVersionInfo
    Left = 225
    Top = 28
  end
end
