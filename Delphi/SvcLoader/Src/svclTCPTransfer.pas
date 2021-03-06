{$IFDEF svclTCPTransfer}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}
unit svclTCPTransfer;

interface

{ TODO -oroger -cdsg : Alternar as cores do icone de acordo com o tipo do computador e a opera��o, ver tabela abaixo:
  Servidor: Verde - recebendo, azul - ocioso, Laranja - Condi��o de alerta a ser definida , vermelho - falha qualquer
  Cliente: Verde - Enviando, laranja - Sem comunica��o com servidor, azul - ocioso }
{ TODO -oroger -cdsg : Possibilitar pela UI pausar o envio dos dados por x minutos }
{ TODO -oroger -cdsg : Ao receber mensagem de shutdown e havendo arquivos a transmitir, possibilita ao usu�rio deixar o desligamento a cargo do servi�o }
{ TODO -oroger -cdsg : Apenas no servidor possibilitar a importa��o de arquivos(op��o recursivo) de bio informando intervalo de data a igonarar e nome da fonte. podendo ainda moitir a transmiss�o via transbio }
{ TODO -oroger -cdsg : Limpar caches de imagens do elo na carga do servi�o }
{ TODO -oroger -cdsg : Registrar o encerramento do windows }

uses
	SysUtils, Classes, Windows, IdContext, IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, IdCustomTCPServer,
	IdTCPServer, AppLog, XPFileEnumerator, IdGlobal, Menus, ExtCtrls, SyncObjs, StreamHnd, ImgList, Controls;

type
	TThreadStringList = class(TStringList)
	private
		FLocker: TCriticalSection;
	protected
		procedure Enter;
		procedure Leave;
	public
		constructor Create;
		destructor Destroy; override;
	end;

	TTransferFile = class(TObject)
	private
		FAccesTime   : TDateTime;
		FModifiedTime: TDateTime;
		FCreatedTime : TDateTime;
		FFilename    : string;
		FHash        : string;
		FIsInputFile : boolean;
		FStream      : TMemoryStream;
		procedure SetFilename(const Value: string);
		procedure InvalidWriteOperation(const AttrName: string);
		function GetSize: int64;
		function GetHash: string;
		function GetDateStamp: string;
	public
		property Filename    : string read FFilename write SetFilename;
		property IsInputFile : boolean read FIsInputFile;
		property AccesTime   : TDateTime read FAccesTime;
		property ModifiedTime: TDateTime read FModifiedTime;
		property CreatedTime : TDateTime read FCreatedTime;
		property Size        : int64 read GetSize;
		property Hash        : string read GetHash;
		property DateStamp   : string read GetDateStamp;
		procedure ReadFromStream(AStream: TStream);
		procedure SetAsDivergent();
		constructor CreateOutput(const Filename: string);
		constructor Create(strm: TStream);
		destructor Destroy; override;
	end;

type
	TDMTCPTransfer = class(TDataModule)
		tcpsrvr: TIdTCPServer;
		tcpclnt: TIdTCPClient;
		TrayIcon: TTrayIcon;
		pmTrayMenu: TPopupMenu;
		Configurar1: TMenuItem;
		Sair1: TMenuItem;
		ilIcons: TImageList;
		procedure tcpclntConnected(Sender: TObject);
		procedure tcpclntDisconnected(Sender: TObject);
		procedure DataModuleDestroy(Sender: TObject);
		procedure tcpsrvrExecute(AContext: TIdContext);
		procedure tcpsrvrStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
		procedure Configurar1Click(Sender: TObject);
		procedure DataModuleCreate(Sender: TObject);
		procedure TrayIconMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
		procedure tcpsrvrConnect(AContext: TIdContext);
		procedure tcpsrvrDisconnect(AContext: TIdContext);
	private
		{ Private declarations }
		FClientSessionList: TThreadStringList;
		FSessionFileCount : Integer;
		FCycleFilesCount  : Integer;
		FMaxTrackedClients: Integer;
		procedure SaveBioFile(const ClientName, Filename, screateDate, saccessDate, smodifiedDate: string; inputStrm: TStream);
		procedure InitSettings();
		procedure UpdateServerTrayStatus();
	public
		{ Public declarations }
		procedure StartServer();
		procedure StartClient();
		procedure StartSession(const SessionName: string; TotalFilesCount: Integer);
		procedure EndSession(const SessionName: string);
		procedure StopServer();
		procedure StopClient();
		procedure SendFile(AFile: TTransferFile);
		constructor Create(AOwner: TComponent); override;
		destructor Destroy; override;
	end;

var
	DMTCPTransfer: TDMTCPTransfer = nil; //Criado manualmente nas aplica��es de teste

implementation

uses
	svclConfig, FileHnd, svclUtils, StrHnd, svclEditConfigForm, svclBiometricFiles, XP.StrConverters;

{$R *.dfm}

const
	TOKEN_DELIMITER             = #13#10;
	STR_END_SESSION_SIGNATURE   = '=end_session';
	STR_BEGIN_SESSION_SIGNATURE = '=start_session';
	STR_OK_PACK                 = 'OK';
	STR_FAIL_HASH               = 'FAIL HASH';
	STR_FAIL_SIZE               = 'FAIL SIZE';

	II_SERVER_IDLE  = 0;
	II_SERVER_ERROR = 1;
	II_SERVER_BUZY  = 2;
	II_SERVER_OK    = 3;
	II_CLIENT_IDLE  = 0;
	II_CLIENT_ERROR = 1;
	II_CLIENT_BUZY  = 2;
	II_CLIENT_OK    = 3;

procedure TDMTCPTransfer.Configurar1Click(Sender: TObject);
begin
	TEditConfigForm.EditConfig();
end;

constructor TDMTCPTransfer.Create(AOwner: TComponent);
begin
	inherited;
	Self.FClientSessionList := TThreadStringList.Create;
	if (GlobalConfig.RunAsServer) then begin
		Self.TrayIcon.IconIndex := II_SERVER_ERROR; //Mesmo valor para o servidor no momento
	end else begin
		Self.TrayIcon.IconIndex := II_CLIENT_ERROR; //Mesmo valor para o servidor no momento
	end;
end;

procedure TDMTCPTransfer.DataModuleCreate(Sender: TObject);
begin
	Self.tcpclnt.ReadTimeout;
end;

procedure TDMTCPTransfer.DataModuleDestroy(Sender: TObject);
begin
	//Fecha clientes e servidor
	Self.StopClient;
	Self.StopServer;
end;

destructor TDMTCPTransfer.Destroy;
begin
	Self.FClientSessionList.Free;
	inherited;
end;

procedure TDMTCPTransfer.EndSession(const SessionName: string);
var
	idx: Integer;
begin
	Self.TrayIcon.IconIndex := II_CLIENT_IDLE;
	Self.FCycleFilesCount   := 0; //zera contador de arquivos para envio
	Self.FClientSessionList.Enter;
	try
		idx := Self.FClientSessionList.IndexOf(SessionName);
		if (idx >= 0) then begin
			Self.FClientSessionList.Delete(idx);
		end;
	finally
		Self.FClientSessionList.Leave;
	end;
	//Envia a finaliza��o de sess�o para o servidor
	Self.tcpclnt.IOHandler.WriteLn(SessionName + STR_END_SESSION_SIGNATURE); //Envia msg de fim de sess�o
end;

procedure TDMTCPTransfer.InitSettings;
begin
	{$WARN UNSAFE_CODE OFF}
	TStrConv.FormatSettings^.DecimalSeparator := '.'; //Usar� globalmente este simbolo
	{$WARN UNSAFE_CODE ON}
end;

procedure TDMTCPTransfer.SaveBioFile(const ClientName, Filename, screateDate, saccessDate, smodifiedDate: string;
	inputStrm: TStream);

	procedure LSRWriteFile(const Filename: string; src: TStream);
	var
		fs  : TFileStream;
		mode: Word;
	begin
		src.Position := 0;
		ForceDirectories(ExtractFilePath(Filename));
		mode := fmShareExclusive;
		if (not FileExists(Filename)) then begin
			mode := mode + fmCreate;
		end else begin
			mode := mode + fmOpenWrite;
		end;
		fs := TFileStream.Create(Filename, mode);
		try
			fs.CopyFrom(src, src.Size);
		finally
			fs.Free;
		end;
	end;

var
	createDate, modDate, accDate              : TDateTime;
	lastName, TransbioFileName, BackupFileName: string;
	fs                                        : TFormatSettings;
begin
	{$WARN UNSAFE_CODE OFF}
	fs               := TStrConv.FormatSettings^;
	{$WARN UNSAFE_CODE ON}
	createDate       := StrToFloat(screateDate, fs);
	modDate          := StrToFloat(smodifiedDate, fs);
	accDate          := StrToFloat(saccessDate, fs);
	lastName         := ExtractFileName(Filename);
	TransbioFileName := TFileHnd.ConcatPath([GlobalConfig.PathServerTransBio, lastName]);
	BackupFileName := TFileHnd.ConcatPath([GlobalConfig.PathServerOrderedBackup, ClientName, FormatDateTime('YYYY\MM\DD', modDate),
		lastName]);
	LSRWriteFile(TransbioFileName, inputStrm);
	FileHnd.SetFileTimeProperties(TransbioFileName, createDate, accDate, modDate);
	LSRWriteFile(BackupFileName, inputStrm);
	FileHnd.SetFileTimeProperties(BackupFileName, createDate, accDate, modDate);
end;

procedure TDMTCPTransfer.SendFile(AFile: TTransferFile);
///<summary>
///Envia a instancia passada para o servidor
///</summary>
///<preconditions>
///Socket com o servidor aberto
///<preconditions>
///<remarks>
///
///</remarks>
var
	s: string;
	FS : TFormatSettings;
begin
	{$WARN UNSAFE_CODE OFF}
	FS := TStrConv.FormatSettings^;
	{$WARN UNSAFE_CODE ON}
	if (not Self.tcpclnt.Connected) then begin
		raise ESVCLException.Create('Canal com o servidor n�o estabelecido antecipadamente');
	end;
	//Passados obrigatoriamente nesta ordem!!!
	s := AFile.FFilename + TOKEN_DELIMITER + FloatToStr(AFile.FCreatedTime, FS ) + TOKEN_DELIMITER +
		FloatToStr(AFile.FAccesTime, FS ) + TOKEN_DELIMITER + FloatToStr(AFile.FModifiedTime, FS )
		+ TOKEN_DELIMITER + FloatToStr(AFile.Size, FS ) + TOKEN_DELIMITER + AFile.Hash;
	Self.tcpclnt.IOHandler.WriteLn(s);
	Self.tcpclnt.IOHandler.WriteFile(AFile.Filename);
	s := Self.tcpclnt.IOHandler.ReadLn();
	if (s <> STR_OK_PACK) then begin
		raise ESVCLException.CreateFmt('Retorno de erro de envio: "%s" para arquivo="%s".', [s, AFile.Filename]);
	end else begin
		Inc(Self.FSessionFileCount); //Incrementa contador de trafego(modo cliente)
		Dec(Self.FCycleFilesCount);  //Decrementa contador de arquivos coletados no ciclo
	end;
end;

procedure TDMTCPTransfer.StartClient;
///<summary>
///Ajusta o container para funcionar apenas como cliente(envio de arquivos apenas)
///</summary>
///<remarks>
///
///</remarks>
begin
	Self.InitSettings;
	Self.tcpclnt.ConnectTimeout := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
	Self.tcpclnt.Host           := GlobalConfig.ServerName;
	Self.tcpclnt.Port           := GlobalConfig.NetServicePort;
	Self.tcpclnt.OnDisconnected := tcpclntDisconnected;
	Self.tcpclnt.OnConnected    := tcpclntConnected;
	Self.tcpclnt.ConnectTimeout := 0;
	Self.tcpclnt.IPVersion      := Id_IPv4;
	Self.tcpclnt.ReadTimeout    := -1;
	Self.TrayIcon.IconIndex     := II_CLIENT_IDLE;
	TLogFile.LogDebug(Format('Falando na porta:(%d) - Servidor:(%s)', [GlobalConfig.NetServicePort, GlobalConfig.ServerName]),
		DBGLEVEL_DETAILED);
end;

procedure TDMTCPTransfer.StartServer;
///<summary>
///Ajusta o container para funcionar apenas como servidor(recebimento de arquivos apenas)
///</summary>
///<remarks>
///
///</remarks>
begin
	TLogFile.LogDebug('Ajustando parametros para o modo servidor', DBGLEVEL_ULTIMATE);
	try
		Self.InitSettings;
		Self.tcpsrvr.OnStatus          := tcpsrvrStatus;
		Self.tcpsrvr.DefaultPort       := GlobalConfig.NetServicePort;
		Self.tcpsrvr.OnExecute         := tcpsrvrExecute;
		Self.tcpsrvr.TerminateWaitTime := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
		Self.tcpsrvr.Active            := True;
		Self.tcpsrvr.StartListening;
		Self.TrayIcon.IconIndex := II_SERVER_IDLE;
		TLogFile.LogDebug(Format('Escutando na porta: %d', [GlobalConfig.NetServicePort]), DBGLEVEL_DETAILED);
	except
		on E: Exception do begin
			TLogFile.Log(Format('Erro fatal abrindo porta %d.'#13#10'%s', [GlobalConfig.NetServicePort, E.Message]), lmtError);
			raise E;
		end;
	end;
end;

procedure TDMTCPTransfer.StartSession(const SessionName: string; TotalFilesCount: Integer);
begin
	Self.TrayIcon.IconIndex := II_CLIENT_BUZY;
	Self.FCycleFilesCount   := TotalFilesCount;
	Self.FClientSessionList.Enter;
	try
		try
			if (Self.FClientSessionList.IndexOf(SessionName) <> -1) then begin
				raise ESVCLException.Create('Sess�o iniciada previamente neste m�dulo');
			end;
			//Envia a abertura de sess�o para o servidor
			Self.tcpclnt.Connect;
			Self.tcpclnt.IOHandler.WriteLn(SessionName + STR_BEGIN_SESSION_SIGNATURE);
			Self.FClientSessionList.Add(SessionName);
		finally
			Self.FClientSessionList.Leave;
		end;
	except
		on E: Exception do begin //colocar como registro de depura��o, por se tratar de erro comum
			TLogFile.LogDebug('Falha de comunica��o com o servidor de recebimento de arquivos'#13#10 + E.Message,
				DBGLEVEL_ALERT_ONLY);
			raise;
		end;
	end;
end;

procedure TDMTCPTransfer.StopClient;
///<summary>
///Atividade opcional, pois o processamento por sess�o � r�pido
///</summary>
///<remarks>
///
///</remarks>
begin
	if (Self.tcpclnt.Connected()) then begin
		Self.tcpclnt.Disconnect;
	end;
end;

procedure TDMTCPTransfer.StopServer;
begin
	if (Self.tcpsrvr.Active) then begin
		Self.tcpsrvr.StopListening;
		Self.tcpsrvr.Active := False;
		TLogFile.LogDebug('Servidor interrompido!', DBGLEVEL_DETAILED);
	end;
end;

procedure TDMTCPTransfer.tcpclntConnected(Sender: TObject);
begin
	TLogFile.LogDebug('Conectado ao servidor', DBGLEVEL_DETAILED);
end;

procedure TDMTCPTransfer.tcpclntDisconnected(Sender: TObject);
begin
	TLogFile.LogDebug('Desconectado do servidor', DBGLEVEL_DETAILED);
end;

procedure TDMTCPTransfer.tcpsrvrConnect(AContext: TIdContext);
begin
	Self.UpdateServerTrayStatus();
end;

procedure TDMTCPTransfer.tcpsrvrDisconnect(AContext: TIdContext);
begin
	Self.UpdateServerTrayStatus();
end;

procedure TDMTCPTransfer.tcpsrvrExecute(AContext: TIdContext);
///<summary>
///Metodo de opera��o do tcpserver para cada conex�o realizada
///</summary>
///<remarks>
///Todos os parametros s�o pegos por linha
///Estudar como proteger o metodo e o timeout da passagem dos dados
///</remarks>
var
	sfilename, smodifiedDate, saccessDate, screateDate, sFileSize, sHash: string;
	retSignature, retHash, retClientName                                : string;
	inStrm                                                              : TMemoryStream;
	nFileSize                                                           : int64;
begin
	//Criticidade em ReadBytes para o stream, ajustado para 30 segundos
	AContext.Connection.Socket.ReadTimeout := 30000;
	TLogFile.LogDebug(Format('Sess�o inciada, cliente: %s', [AContext.Connection.Socket.Binding.PeerIP]), DBGLEVEL_DETAILED);
	AContext.Connection.IOHandler.AfterAccept; //processamento pos conexao com sucesso
	try
		retSignature := AContext.Connection.IOHandler.ReadLn(); //Aguarda a assinatura do cliente para iniciar opera��o
		if (not TStrHnd.endsWith(retSignature, STR_BEGIN_SESSION_SIGNATURE)) then begin
			//Cancela a sess�o por falha de protocolo
			retClientName := EmptyStr;
			TLogFile.LogDebug(Format('Falha de protocolo, cadeia recebida=%s', [retSignature]), DBGLEVEL_ALERT_ONLY);
		end else begin
			retClientName := Copy(retSignature, 1, Pos(STR_BEGIN_SESSION_SIGNATURE, retSignature) - 1);
		end;

		repeat
			//Linha incial de dados deve conter os atributos do arquivo(fullname, createdDate, accessDate, modifiedDate, Size )
			//No inicio da opera��o, captura as cadeias. Caso a linha possua o token de final de sess�o desconecta(o servidor espera uma nova sess�o)
			retSignature := AContext.Connection.IOHandler.ReadLn();
			if (TStrHnd.endsWith(retSignature, STR_END_SESSION_SIGNATURE)) then begin
				System.Continue;
			end;
			//Dados passados nesta ordem!!!
			sfilename     := retSignature;
			screateDate   := AContext.Connection.IOHandler.ReadLn();
			saccessDate   := AContext.Connection.IOHandler.ReadLn();
			smodifiedDate := AContext.Connection.IOHandler.ReadLn();
			sFileSize     := AContext.Connection.IOHandler.ReadLn();
			sHash         := AContext.Connection.IOHandler.ReadLn();

			TLogFile.LogDebug(Format('Recebida cadeia do cliente(%s) ao servidor:'#13#10'arquivo="%s"'#13#10'cria��o=%s'#13#10 +
				'acesso=%s'#13#10'Modifica��o=%s'#13#10'tamanho=%s'#13#10'hash=%s'#13#10, [retClientName, sfilename, smodifiedDate,
				saccessDate, screateDate, sFileSize, sHash]), DBGLEVEL_DETAILED);

			nFileSize := StrToInt64(sFileSize); //Tamanho do stream a ser lido pela rede

			inStrm := TMemoryStream.Create();
			try
				AContext.Connection.IOHandler.ReadStream(inStrm, nFileSize); //Local para o ajuste do ReadTimeout
			finally
				if (inStrm.Size = nFileSize) then begin //Recep��o ok -> testar integridade
					retHash := THashHnd.MD5(inStrm);
					if (SameText(retHash, sHash)) then begin
						AContext.Connection.IOHandler.WriteLn(STR_OK_PACK); //informa OK e em seguida o tamanho do streamer lido
						Self.SaveBioFile(retClientName, sfilename, screateDate, saccessDate, smodifiedDate, inStrm);
						//Salva arquivo denominado OK
						Inc(Self.FSessionFileCount); //Incrementa contador de trafego(modo servidor)
					end else begin
						AContext.Connection.IOHandler.WriteLn(STR_FAIL_HASH); //informa OK e em seguida o tamanho do streamer lido
					end;
				end else begin                                            //Erro de recep��o rejeitar arquivo
					AContext.Connection.IOHandler.WriteLn(STR_FAIL_SIZE); //informa OK e em seguida o tamanho do streamer lido
				end;
				inStrm.Free;
			end;
		until (TStrHnd.endsWith(retSignature, STR_END_SESSION_SIGNATURE)); //assinatura de fim de sess�o
	finally
		//Finaliza a sess�o
		try
			AContext.Connection.Disconnect;
		finally
			if (TStrHnd.endsWith(retSignature, STR_END_SESSION_SIGNATURE)) then begin
				TLogFile.LogDebug('Sess�o encerrada normalmente', DBGLEVEL_DETAILED);
			end else begin
				TLogFile.Log(Format('Cliente("%s") desconectado abruptamente', [retClientName]), lmtWarning);
			end;
		end;
	end;
end;

procedure TDMTCPTransfer.tcpsrvrStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
	TLogFile.LogDebug(Format('Status do servidor: "%s"', [AStatusText]), DBGLEVEL_DETAILED);
end;

procedure TDMTCPTransfer.TrayIconMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
///Atualiza status da dica, informando o tr�fego atual da sess�o
var
	rtVersion: string;
begin
	if (not Assigned(BioFilesService)) then begin
		rtVersion := '*** DESCONHECIDA ***';
	end else begin
		rtVersion := BioFilesService.fvInfo.FileVersion;
	end;
	if (GlobalConfig.RunAsServer) then begin
		Self.TrayIcon.Hint := Format('SESOP - Replica��o de arquivos de biometria' + #13#10 + rtVersion + #13#10 +
			'Arquivos recebidos = %d' + #13#10, [Self.FSessionFileCount]);
	end else begin
		Self.TrayIcon.Hint := Format('SESOP - Replica��o de arquivos de biometria' + #13#10 + rtVersion + #13#10 +
			'Arquivos enviados na sess�o = %d' + #13#10, [Self.FSessionFileCount]);
		if (Self.FCycleFilesCount > 0) then begin
			Self.TrayIcon.Hint := Self.TrayIcon.Hint + 'Arquivos a enviar neste ciclo = ' + IntToStr(Self.FCycleFilesCount) +
				' '#13#10;
		end;
	end;
end;

procedure TDMTCPTransfer.UpdateServerTrayStatus;
var
	List       : TList;
	clientCount: Integer;
begin
	try
		List        := Self.tcpsrvr.Contexts.LockList;
		clientCount := List.Count;
	finally
		Self.tcpsrvr.Contexts.UnlockList;
	end;
	if (clientCount > 0) then begin
		Self.TrayIcon.IconIndex := II_SERVER_BUZY;
		if (Self.FMaxTrackedClients < clientCount) then begin
			Self.FMaxTrackedClients := clientCount;
			TLogFile.LogDebug(Format('Registro de clientes simult�neos aumentado = %d', [Self.FMaxTrackedClients]),
				DBGLEVEL_DETAILED);
		end;
	end else begin
		Self.TrayIcon.IconIndex := II_SERVER_IDLE;
	end;
end;

constructor TTransferFile.Create;
begin
	inherited Create;
	Self.FIsInputFile := True; //Atributo RO indica que o arquivo ser� lido como entrada da transmiss�o
end;

constructor TTransferFile.CreateOutput(const Filename: string);
///<summary>
///Construtor de arquivo de transferencia, realiza a leitura dos atributos do arquivo para repassar para a saida
///</summary>
///<remarks>
///
///</remarks>
begin
	inherited;
	Self.FIsInputFile := False;
	Self.FFilename    := Filename;
	FileHnd.TFileHnd.FileTimeProperties(Self.FFilename, Self.FCreatedTime, Self.FAccesTime, Self.FModifiedTime);
end;

destructor TTransferFile.Destroy;
begin
	if (Assigned(Self.FStream)) then begin
		FreeAndNil(Self.FStream);
	end;
	inherited;
end;

function TTransferFile.GetDateStamp: string;
///<summary>
///Retorna a cadeia no formato YYYY\MM\DD para a data de modifica��o do arquivo
///</summary>
var
	modDate, dummy: TDateTime;
	//FullDateStr, sy, sm, sd : string;
begin
	TFileHnd.FileTimeProperties(Self.FFilename, dummy, dummy, modDate);

	Result := FormatDateTime('YYYY\MM\DD', modDate);
	{
	  FullDateStr :=FormatDateTime( 'YYYMMDD' , modDate );
	  sy := Copy(FullDateStr, 1, 4);
	  sm := Copy(FullDateStr, 5, 2);
	  sd := Copy(FullDateStr, 7, 2);
	}
end;

function TTransferFile.GetHash: string;
begin
	if (Self.FHash = EmptyStr) then begin
		Self.FHash := THashHnd.MD5(Self.FFilename);
	end;
	Result := Self.FHash;
end;

function TTransferFile.GetSize: int64;
begin
	Result := TFileHnd.FileSize(Self.FFilename);
end;

procedure TTransferFile.InvalidWriteOperation(const AttrName: string);
begin
	raise Exception.CreateFmt('Atributo "%s" para arquivo tipo entrada n�o pode ter este atributo altereado.', [AttrName]);
end;

procedure TTransferFile.ReadFromStream(AStream: TStream);
begin
	if (not Assigned(Self.FStream)) then begin
		Self.FStream := TMemoryStream.Create;
	end;
	Self.FStream.CopyFrom(AStream, AStream.Size);
end;

procedure TTransferFile.SetAsDivergent;
///<summary>
///Altera sufixando o nome do arquivo para "_divergent" e o move para as pastas de backup ordenado
///</summary>
var
	newName: string;
begin
	{ TODO -oroger -cdsg : Informar todos os dados dos arquivos divergentes para estudo posterior da causa }
	TLogFile.Log('Arquivo divergente encontrado: "' + Self.FFilename + '". Usada a outra vers�o em Bioservice(caso haja)',
		lmtError);
	newName := TFileHnd.ExtractFilenamePure(Self.FFilename);
	newName := TFileHnd.ConcatPath([GlobalConfig.PathClientOrderlyBackup, Self.DateStamp,
		newName + '_divergent.' + SysUtils.ExtractFileExt(Self.FFilename)]);
	ForceDirectories(TFileHnd.ParentDir(newName));
	if (FileExists(newName)) then begin
		newName := TFileHnd.NextFamilyFilename(newName); //unicidade no destino
	end;
	if (MoveFile(PWideChar(Self.FFilename), PWideChar(newName))) then begin
		Self.FFilename := newName;
	end else begin
		raise ESVCLException.CreateFmt('Arquivo: "%s" n�o pode ser movido para "%s"', [Self.FFilename, newName]);
	end;
end;

procedure TTransferFile.SetFilename(const Value: string);
{ TODO -oroger -cfuture : diferenciar a carga nomral do construtor para carregar pelo streamer os dados das datas do arquivo }
begin
	if (not Self.FIsInputFile) then begin
		Self.FFilename := Value;
	end else begin
		Self.InvalidWriteOperation('Nome do arquivo:' + Value + ' n�o pode ser alterado neste momento');
	end;
end;

constructor TThreadStringList.Create;
begin
	inherited;
	Self.FLocker := TCriticalSection.Create;
end;

destructor TThreadStringList.Destroy;
begin
	FreeAndNil(Self.FLocker);
	inherited;
end;

procedure TThreadStringList.Enter;
begin
	Self.FLocker.Enter;
end;

procedure TThreadStringList.Leave;
begin
	Self.FLocker.Leave;
end;

end.
