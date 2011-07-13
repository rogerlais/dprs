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
      'Database=desenv'
      'HostName=localhost'
      'User_Name=desenv'
      'Password=desenv')
    VendorLib = 'LIBMYSQL.dll'
    Connected = True
    Left = 74
    Top = 26
  end
  object dsUserFullNames: TSimpleDataSet
    Aggregates = <>
    Connection = conMySQLADUsrMgrConnection
    DataSet.CommandText = 'select * from `user_names`'
    DataSet.MaxBlobSize = -1
    DataSet.Params = <>
    Params = <>
    ReadOnly = True
    Left = 72
    Top = 88
    object fldUserNameId: TIntegerField
      FieldName = 'iduser_names'
      Required = True
    end
    object fldFullNameUse: TStringField
      FieldName = 'full_name'
      Size = 45
    end
    object fldRuledFullName: TStringField
      FieldName = 'ruled_full_name'
      Size = 45
    end
    object dtstfldUserFullNamesFldUserEntries: TDataSetField
      DefaultExpression = 
        'select * from `users_entry` where idexternal_users = :iduser_nam' +
        'es'#13#10
      FieldName = 'FldUserEntries'
    end
  end
end
