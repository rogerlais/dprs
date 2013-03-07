object DMTCPTransfer: TDMTCPTransfer
  OldCreateOrder = False
  OnDestroy = DataModuleDestroy
  Height = 150
  Width = 215
  object tcpsrvr: TIdTCPServer
    Bindings = <>
    DefaultPort = 2013
    OnExecute = tcpsrvrExecute
    Left = 32
    Top = 24
  end
  object tcpclnt: TIdTCPClient
    OnDisconnected = tcpclntDisconnected
    OnConnected = tcpclntConnected
    ConnectTimeout = 0
    IPVersion = Id_IPv4
    Port = 0
    ReadTimeout = -1
    Left = 136
    Top = 24
  end
end
