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
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
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
    Body.Strings = (
      'teste via indy')
    BccList = <>
    CCList = <>
    Encoding = meDefault
    FromList = <
      item
        Address = 'sesop@tre-pb.gov.br'
        Name = 'VVer - Verificador de sistemas 2010 - T1'
        Text = 'VVer - Verificador de sistemas 2010 - T1 <sesop@tre-pb.gov.br>'
        Domain = 'tre-pb.gov.br'
        User = 'sesop'
      end>
    From.Address = 'sesop@tre-pb.gov.br'
    From.Name = 'VVer - Verificador de sistemas 2010 - T1'
    From.Text = 'VVer - Verificador de sistemas 2010 - T1 <sesop@tre-pb.gov.br>'
    From.Domain = 'tre-pb.gov.br'
    From.User = 'sesop'
    Recipients = <>
    ReplyTo = <
      item
        Address = 'sesop@tre-pb.gov.br'
        Name = 'SESOP'
        Text = 'SESOP <sesop@tre-pb.gov.br>'
        Domain = 'tre-pb.gov.br'
        User = 'sesop'
      end>
    Sender.Address = 'sesop@tre-pb.gov.br'
    Sender.Name = 'SESOP - Se'#195#167#195#163'o de Suporte Operacional'
    Sender.Text = '"SESOP - Se'#195#167#195#163'o de Suporte Operacional" <sesop@tre-pb.gov.br>'
    Sender.Domain = 'tre-pb.gov.br'
    Sender.User = 'sesop'
    ConvertPreamble = True
    Left = 89
    Top = 28
  end
  object fvVersion: TFileVersionInfo
    Left = 225
    Top = 28
  end
end
