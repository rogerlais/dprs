object MainDM: TMainDM
  OldCreateOrder = False
  Height = 336
  Width = 436
  object zconMain: TZConnection
    Connected = True
    DesignConnection = True
    SQLHourGlass = True
    Port = 0
    Database = 
      'C:\Sw\WorkDir\Dprs\Delphi\SvcLoader\Extras\BioInfoReloaded\Data\' +
      'bird.db3'
    Protocol = 'sqlite-3'
    Left = 32
    Top = 40
  end
  object ztblBioFiles: TZTable
    Connection = zconMain
    UpdateObject = zpdtsqlBioFiles
    CachedUpdates = True
    AfterPost = ztblBioFilesAfterPost
    AfterDelete = ztblBioFilesAfterDelete
    Active = True
    TableName = 'BIO_FILES'
    FetchRow = 100
    UpdateMode = umUpdateAll
    WhereMode = wmWhereAll
    Left = 88
    Top = 40
    object wdstrngfldBioFilesFULL_FILENAME: TWideStringField
      DisplayLabel = 'Arquivo'
      DisplayWidth = 255
      FieldName = 'FULL_FILENAME'
      Required = True
      Size = 255
    end
    object wdstrngfldBioFilesCOMPUTERNAME: TWideStringField
      DisplayLabel = 'Computador'
      FieldName = 'COMPUTERNAME'
      Required = True
      Size = 15
    end
    object intgrfldBioFilesELECT_ID: TIntegerField
      DisplayLabel = 'Inscri'#231#227'o'
      FieldName = 'ELECT_ID'
      Required = True
    end
    object intgrfldBioFilesBIO_TYPE: TIntegerField
      FieldName = 'BIO_TYPE'
    end
    object intgrfldBioFilesCENTRAL_ID: TIntegerField
      DisplayLabel = 'Central'
      FieldName = 'CENTRAL_ID'
    end
    object intgrfldBioFilesZONE_ID: TIntegerField
      DisplayLabel = 'Zona'
      FieldName = 'ZONE_ID'
    end
    object mfldBioFilesCOMENT: TMemoField
      FieldName = 'COMENT'
      BlobType = ftMemo
    end
    object mfldBioFilesCOMMENT: TMemoField
      FieldName = 'COMMENT'
      BlobType = ftMemo
    end
  end
  object dsBioFiles: TDataSource
    DataSet = ztblBioFiles
    Left = 152
    Top = 40
  end
  object zpdtsqlBioFiles: TZUpdateSQL
    DeleteSQL.Strings = (
      'DELETE FROM BIO_FILES'
      'WHERE'
      '  BIO_FILES.FULL_FILENAME = :OLD_FULL_FILENAME')
    InsertSQL.Strings = (
      'INSERT INTO BIO_FILES'
      
        '  (FULL_FILENAME, COMPUTERNAME, ELECT_ID, BIO_TYPE, CENTRAL_ID, ' +
        'ZONE_ID, '
      '   COMMENT)'
      'VALUES'
      
        '  (:FULL_FILENAME, :COMPUTERNAME, :ELECT_ID, :BIO_TYPE, :CENTRAL' +
        '_ID, :ZONE_ID, '
      '   :COMMENT)')
    ModifySQL.Strings = (
      'UPDATE BIO_FILES SET'
      '  FULL_FILENAME = :FULL_FILENAME,'
      '  COMPUTERNAME = :COMPUTERNAME,'
      '  ELECT_ID = :ELECT_ID,'
      '  BIO_TYPE = :BIO_TYPE,'
      '  CENTRAL_ID = :CENTRAL_ID,'
      '  ZONE_ID = :ZONE_ID,'
      '  COMMENT = :COMMENT'
      'WHERE'
      '  BIO_FILES.FULL_FILENAME = :OLD_FULL_FILENAME')
    UseSequenceFieldForRefreshSQL = False
    Left = 216
    Top = 40
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'FULL_FILENAME'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'COMPUTERNAME'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'ELECT_ID'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'BIO_TYPE'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'CENTRAL_ID'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'ZONE_ID'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'COMMENT'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'OLD_FULL_FILENAME'
        ParamType = ptUnknown
      end>
  end
  object srchflSearchFiles: TJvSearchFiles
    Options = []
    FileParams.SearchTypes = [stFileMask]
    FileParams.FileMasks.Strings = (
      '*.bio')
    OnFindFile = srchflSearchFilesFindFile
    Left = 304
    Top = 40
  end
end
