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
    Left = 74
    Top = 26
  end
  object dsUserFullNames: TSimpleDataSet
    Aggregates = <>
    Connection = conMySQLADUsrMgrConnection
    DataSet.CommandText = 'select * from `work_users`'
    DataSet.MaxBlobSize = -1
    DataSet.Params = <>
    Params = <>
    ReadOnly = True
    Left = 72
    Top = 88
    object intgrfldUserFullNamesidexternal_users: TIntegerField
      FieldName = 'idexternal_users'
      Required = True
    end
    object strngfldUserFullNamesext_user_ad_login: TStringField
      FieldName = 'ext_user_ad_login'
      Size = 15
    end
    object strngfldUserFullNamesext_user_ad_sis_login: TStringField
      FieldName = 'ext_user_ad_sis_login'
      Size = 15
    end
    object strngfldUserFullNamesext_users_name: TStringField
      FieldName = 'ext_users_name'
      Size = 45
    end
    object strngfldUserFullNamesext_users_ruled_name: TStringField
      FieldName = 'ext_users_ruled_name'
      Size = 45
    end
    object strngfldUserFullNamesext_users_location: TStringField
      FieldName = 'ext_users_location'
      Size = 45
    end
    object strngfldUserFullNamesext_users_source: TStringField
      FieldName = 'ext_users_source'
      Size = 45
    end
    object sqltmstmpfldUserFullNamesext_users_start_time: TSQLTimeStampField
      FieldName = 'ext_users_start_time'
    end
    object sqltmstmpfldUserFullNamesext_users_end_time: TSQLTimeStampField
      FieldName = 'ext_users_end_time'
    end
    object strngfldUserFullNamesext_users_ad: TStringField
      FieldName = 'ext_users_ad'
      FixedChar = True
      Size = 1
    end
    object strngfldUserFullNamesext_uses_estag: TStringField
      FieldName = 'ext_uses_estag'
      FixedChar = True
      Size = 1
    end
    object strngfldUserFullNamesext_users_requisit: TStringField
      FieldName = 'ext_users_requisit'
      FixedChar = True
      Size = 1
    end
    object strngfldUserFullNamesext_users_titular: TStringField
      FieldName = 'ext_users_titular'
      FixedChar = True
      Size = 1
    end
    object strngfldUserFullNamesext_users_sis: TStringField
      FieldName = 'ext_users_sis'
      FixedChar = True
      Size = 1
    end
  end
end
