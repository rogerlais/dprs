unit birMainDM;

interface

uses
  SysUtils, Classes, DB, ZAbstractRODataset, ZAbstractDataset, ZAbstractTable, ZDataset, ZAbstractConnection, ZConnection,
  ZSqlUpdate, ImgList, Controls, ActnList;

type
  TDataModule1 = class(TDataModule)
    zconMain: TZConnection;
    ztblBioFiles: TZTable;
    dsBioFiles: TDataSource;
    zpdtsqlBioFiles: TZUpdateSQL;
    wdstrngfldBioFilesFULL_FILENAME: TWideStringField;
    wdstrngfldBioFilesCOMPUTERNAME: TWideStringField;
    intgrfldBioFilesELECT_ID: TIntegerField;
    intgrfldBioFilesBIO_TYPE: TIntegerField;
    intgrfldBioFilesCENTRAL_ID: TIntegerField;
    intgrfldBioFilesZONE_ID: TIntegerField;
    wdstrngfldBioFilesCOMMENT: TWideStringField;
    procedure ztblBioFilesAfterPost(DataSet: TDataSet);
    procedure ztblBioFilesAfterApplyUpdates(Sender: TObject);
    procedure ztblBioFilesAfterDelete(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.dfm}

procedure TDataModule1.ztblBioFilesAfterApplyUpdates(Sender: TObject);
begin
	Self.ztblBioFiles.ApplyUpdates;
end;

procedure TDataModule1.ztblBioFilesAfterDelete(DataSet: TDataSet);
begin
	Self.ztblBioFiles.ApplyUpdates;
end;

procedure TDataModule1.ztblBioFilesAfterPost(DataSet: TDataSet);
begin
	Self.ztblBioFiles.ApplyUpdates;
end;

end.
