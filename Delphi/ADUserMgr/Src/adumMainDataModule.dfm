object DtMdMainADUserMgr: TDtMdMainADUserMgr
  OldCreateOrder = False
  Height = 378
  Width = 462
  object conMySQLADUsrMgrConnection: TSQLConnection
    ConnectionName = 'ADUsrMgrConnection'
    DriverName = 'MYSQL'
    GetDriverFunc = 'getSQLDriverMYSQL'
    LibraryName = 'dbxmys.dll'
    LoginPrompt = False
    Params.Strings = (
      'drivername=MYSQL'
      'Database=usr_mgr'
      'HostName=pbocomon'
      'User_Name=desenv'
      'Password=desenv')
    VendorLib = 'LIBMYSQL.dll'
    Connected = True
    Left = 74
    Top = 26
  end
  object dsExtUserSD: TSimpleDataSet
    Aggregates = <>
    Connection = conMySQLADUsrMgrConnection
    DataSet.MaxBlobSize = -1
    DataSet.Params = <>
    Params = <>
    ReadOnly = True
    Left = 72
    Top = 88
  end
end
