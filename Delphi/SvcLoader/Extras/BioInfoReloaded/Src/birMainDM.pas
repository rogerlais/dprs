{$IFDEF birMainDM}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I bir.inc}

unit birMainDM;

interface

uses
  SysUtils, Classes, Windows, DB, ZAbstractRODataset, ZAbstractDataset, ZAbstractTable, ZDataset, ZAbstractConnection, ZConnection,
  ZSqlUpdate, ImgList, Controls, ActnList, Dialogs, SimpleProgress, ThreadProgressForm, JvComponentBase, JvSearchFiles, StrHnd, ClipBrd;

type
  TMainDM = class(TDataModule)
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
	 srchflSearchFiles: TJvSearchFiles;
    mfldBioFilesCOMENT: TMemoField;
    mfldBioFilesCOMMENT: TMemoField;
    procedure ztblBioFilesAfterPost(DataSet: TDataSet);
    procedure ztblBioFilesAfterApplyUpdates(Sender: TObject);
    procedure ztblBioFilesAfterDelete(DataSet: TDataSet);
	 procedure srchflSearchFilesFindFile(Sender: TObject; const AName: string);
  private
	 { Private declarations }
	 FFileCount : integer;
	 FParser : TBufferedStringStream;
	 FStreamer : TMemoryStream;
	 FRegId : Integer;
  public
	 { Public declarations }
	 procedure  ImportFromClipBoard();
	 procedure  SearchFromClipBoard();
	 constructor Create( AOwner : TComponent ); override;
	 destructor Destroy; override;
  end;


  TSearhFiles = class(TProgressThread)
  private
	FSearchFiles : TJvSearchFiles;
	FFoundCount : Integer;
  public
		 function GetCurrentValue : int64; override;
		 {1 Método para leitura do valor corrente do progresso do thread. }
		 function GetMaxValue : int64; override;
		 {1 Método para leitura do valor máximo do progresso do thread. }
		 function GetMinValue : int64; override;
		 procedure Execute(); override;
	end;

const
	 DELIMS: TSysCharSet = [';', #13, #10];

var
  MainDM: TMainDM;

implementation


{$R *.dfm}

constructor TMainDM.Create(AOwner: TComponent);
begin
	inherited;
	Self.FStreamer:=TMemoryStream.Create;
	Self.FParser := TBufferedStringStream.Create( Self.FStreamer );
end;

destructor TMainDM.Destroy;
begin
	Self.FParser.Free;
	Self.FStreamer.Free;
  inherited;
end;

procedure TMainDM.ImportFromClipBoard;
var
	lp : TParser;
begin
	{TODO -oroger -cdsg : Importa a partir da area de transferencia usando um parser}
	{TODO -oroger -cdsg : Varre pasta repositorio dos aqruivos}
	Self.srchflSearchFiles.Search;
end;

procedure TMainDM.SearchFromClipBoard;
var
	SearchThread : TSearhFiles;
	clp : AnsiString;
begin
	{TODO -oroger -cdsg :
	Metodo gambiarra que passa por todos os arquivos encontrados na pasta de arquivos ordenados
	e busca dentro do texto presente na área de transferência,
	caso encontre uma entrada é gerada na tabela }
	Self.ztblBioFiles.EmptyDataSet;

	//Carrega a área de transferência
	clp :=Clipboard.AsText;
	FreeAndNil( Self.FStreamer );
	Self.FStreamer := TMemoryStream.Create;
	Self.FStreamer.SetSize(  Length( clp ) + 1 );
	Self.FStreamer.Write( clp[1], Length( clp ) );
	Self.FStreamer.Position:=0;
	FreeAndNil( Self.FParser );

	Self.FParser := TBufferedStringStream.Create( Self.FStreamer );
	Self.FParser.SetWordDelimiters( @DElIMS );
	clp:=Self.FParser.ReadLine();

	//Prepara parametros de busca
	Self.srchflSearchFiles.RootDirectory:= 'B:\Ordenado';
	Self.srchflSearchFiles.FileParams.FileMask:='*.bio';
	Self.srchflSearchFiles.Options:=[ soSearchFiles ];
	if Self.srchflSearchFiles.Search() then begin
		Self.ztblBioFiles.ApplyUpdates;
	end;
	MessageDlg(Format( 'Encontrados: %d arquivos' , [ Self.FFileCount ] ),  mtInformation, [mbOK], 0);

end;

procedure TMainDM.srchflSearchFilesFindFile(Sender: TObject; const AName: string);
var
	lastFilename : string;
begin
	Inc( Self.FFileCount );
	{TODO -oroger -cdsg : Localiza nome do arquivo no texto passado, caso positivo insere linha na tabela }
  //'FULL_FILENAME' , 'COMPUTERNAME' , 'ELECT_ID' , 'BIO_TYPE' , 'CENTRAL_ID' , 'ZONE_ID' , 'COMMENT'
  Self.FParser.Reset;
  lastFilename:= ExtractFileName( AName );
  if ( Self.FParser.Search( lastFilename ) ) then begin
		try
		Self.ztblBioFiles.AppendRecord( [ AName, 'este', Self.FRegId, 1, 1, 1 ] );
		except
			on E : Exception do begin
				MessageDlg( E.Message,  mtError, [mbOK],0);
			end;
       end;
		Inc( Self.FRegId );
  end;
end;

procedure TMainDM.ztblBioFilesAfterApplyUpdates(Sender: TObject);
begin
	Self.ztblBioFiles.ApplyUpdates;
end;

procedure TMainDM.ztblBioFilesAfterDelete(DataSet: TDataSet);
begin
	Self.ztblBioFiles.ApplyUpdates;
end;

procedure TMainDM.ztblBioFilesAfterPost(DataSet: TDataSet);
begin
	Self.ztblBioFiles.ApplyUpdates;
end;

{ TSearhFiles }

procedure TSearhFiles.Execute;
begin
  Self.FSearchFiles:=TJvSearchFiles.Create( nil );
  try
		inherited;
		Self.FSearchFiles.RootDirectory:='B:\Ordenado';
		Self.FSearchFiles.FileParams.FileMask:='*.bio';
		Self.FSearchFiles.Search;
		while Self.FSearchFiles.Searching do begin
			 Self.FFoundCount:=Self.FSearchFiles.TotalFiles;
		end;
  finally
		Self.FSearchFiles.Free();
  end;
end;

function TSearhFiles.GetCurrentValue: int64;
begin
	Result:=Self.FFoundCount;
end;

function TSearhFiles.GetMaxValue: int64;
begin
	Result := MaxInt;
end;

function TSearhFiles.GetMinValue: int64;
begin
	Result:=0;
end;

end.
