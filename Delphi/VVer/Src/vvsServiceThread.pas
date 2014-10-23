{$IFDEF vvsServiceThread}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
unit vvsServiceThread;

interface

uses
	SysUtils, Windows, Classes, XPFileEnumerator, XPThreads, vvsConsts, vvsFileMgmt, IdContext,
	IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, IdCustomTCPServer, Generics.Collections,
	IdTCPServer, AppLog, IdGlobal, Types;

type

	TVVerClientThread = class(TXPNamedThread)
	private
		FCycleErrorCount : Integer;
		FLastVerification: TDateTime;
		FTempFolder      : TManagedFolder;
		FSyncFolder      : TManagedFolder;
		FActiveSession   : boolean;
		procedure DoClientCycle;
	public
		constructor Create(CreateSuspended: boolean; const ThreadName: string); override;
		procedure DoTerminate; override;
		procedure Execute(); override;
		property LastVerification: TDateTime read FLastVerification;
	end;

	TVVerServerThread = class(TXPNamedThread)
	private
		procedure DoServerCycle;
		procedure StartTCPServer;
		procedure StopTCPServer;
	protected
		procedure DoTerminate(); override;
	public
		constructor Create(CreateSuspended: boolean; const ThreadName: string); override;
		procedure Execute(); override;
	end;

	TClientSyncSession = class
	private
		FParent: TVVerClientThread;
		FSocket: TIdTCPClient;
		function GetCancelled: boolean;
		function ReadFileFirgerPrint(remoteFile: TVVSFile): TStringDynArray;
	protected
		procedure PostRequest(Args: array of string);
		function ReadResponse(): string;
		procedure ReadRemoteFile(inFile, outFile: TVVSFile);
		procedure ReadCloseFile(downID: THandle; AStream: TFileStream);
		procedure ReadStreamSegment(downID, SegIdx: int64; Strm: TStream; const prevHash: string);
	public
		constructor Create(AParent: TVVerClientThread; ASocket: TIdTCPClient);
		property Cancelled: boolean read GetCancelled;
		function ReadRemoteContent(const PubName: string): string;
		function Synch(const PubName: string; LocalFolder, TempFolder: TManagedFolder): string;
		procedure UpdateFile(inFile: TVVSFile);
	end;

implementation

uses
	vvsTCPTransfer, FileHnd, StreamHnd, StrHnd, Str_pas, Math, vvSvcDM, vvConfig;

{ TVVerServiceThread }

constructor TVVerServerThread.Create(CreateSuspended: boolean; const ThreadName: string);
begin
	//Self.FInstSegPublication := TVVSPublication.Create( PUBLICATION_INSTSEG, VVSvcConfig.PathLocalInstSeg );
	if (not ForceDirectories(GlobalInfo.PathLocalRepository)) then begin
		raise EVVException.CreateFmt('Caminho "%s" usado para repositório local, não pode ser acessado',
			[GlobalInfo.PathLocalRepository]);
	end;
	inherited;
end;

procedure TVVerServerThread.DoServerCycle;
begin
	{ TODO -oroger -cdsg : Delimitar o que fara o ciclo servidor além de reenvio de logs, sugestão para ser o local de atualização de status }
end;

procedure TVVerServerThread.DoTerminate;
begin
	//Finaliza o servidor TCP
	Self.StopTCPServer;
	inherited;
end;

procedure TVVerServerThread.Execute;
{ TODO -oroger -cdsg : repete o ciclo do servidor e aguarda sinalizações }
begin
	inherited;
	try
		Self.StartTCPServer; //Para o servidor inicia escuta na porta
	except
		on E: Exception do begin
			TLogFile.Log('Serviço não pode continuar e será encerrado. Razão:' + E.Message, lmtError);
			raise;
		end;
	end;
	while (not Self.Terminated) do begin
		try
			Self.DoServerCycle();
		except
			on E: Exception do begin
				TLogFile.Log('Ciclo de organização de arquivos do servidor de envio falhou: ' + E.Message, lmtError);
			end;
		end;
		Self.Suspended := True; //Libera cpu até novo ciclo
	end;
end;

procedure TVVerServerThread.StartTCPServer;
//Verificar a atividade do servidor tcp, ativando o mesmo se necessário
begin
	try
		if (not DMTCPTransfer.tcpsrvr.Active) then begin
			TLogFile.LogDebug('Abrindo porta no modo servidor', DBGLEVEL_ULTIMATE);
			DMTCPTransfer.StartServer();
		end;
	except
		on E: Exception do begin
			TLogFile.Log('Chamada StartTCPServer retornou erro:' + E.Message, lmtError);
			raise;
		end;
	end;
end;

procedure TVVerServerThread.StopTCPServer;
begin
	DMTCPTransfer.StopServer;
end;

{ TClientThread }

constructor TVVerClientThread.Create(CreateSuspended: boolean; const ThreadName: string);
begin
	inherited;
	Self.FTempFolder           := TManagedFolder.CreateLocal(GlobalInfo.PathLocalTempDir);
	Self.FTempFolder.BlockSize := GlobalInfo.BlockSize;
	if (GlobalInfo.PublicationParentServer = EmptyStr) then begin
		raise EVVException.CreateFmt('Servidor pai desta instância inválido(%s)', [GlobalInfo.PublicationParentServer]);
	end;
end;

procedure TVVerClientThread.DoClientCycle;
var
	clientSession: TClientSyncSession;
begin
	if (Self.FActiveSession) then begin //aguarda a anterior terminar seu trabalho
		Exit;
	end;
	{ TODO -oroger -cdsg : Buscar por atualizações }
	Self.FActiveSession := True;
	try
		DMTCPTransfer.StartSession(GlobalInfo.ClientName + ' * ' + TimeToStr(Now()));
		try
			clientSession := TClientSyncSession.Create(Self, DMTCPTransfer.tcpclnt);
			try
				clientSession.Synch(PUBLICATION_INSTSEG, Self.FSyncFolder, Self.FTempFolder);
				//realiza todas as operações até desejar finalizar conexao
			finally
				clientSession.Free;
			end;
		finally
			DMTCPTransfer.EndSession(GlobalInfo.ClientName);
		end;
	finally
		Self.FActiveSession := False;
	end;
end;

procedure TVVerClientThread.DoTerminate;
begin
	FreeAndNil(Self.FTempFolder);
	FreeAndNil(Self.FSyncFolder);
	inherited;
end;

procedure TVVerClientThread.Execute;
///<summary>
///Rotina primaria do caso de uso do servico.
///Nele temos 2 cenarios:
///1 - Maquina secundária:
///a) Enumera todos os arquivos da pasta de origem
///b) Repassa todo os arquivos para a maquina primária
///c) Realiza seu backup local
///2 - Máquina primária:
///a) Move todos os da pasta de recepção remota para a pasta de transmissão
///b) Move todos os arquivos da pasta transmitidos para a de backup global
///c) Reorganiza todos os arquivos do backup global
///</summary>
///<remarks>
///
///</remarks>
var
	ErrorMessage: string;

	procedure LSRReportError(EComm: Exception);
	//notificar agente monitorador
	begin
		//Registrar o erro e testar o contador de erros
		Inc(Self.FCycleErrorCount);
		ErrorMessage := Format('Quantidade de erros consecutivos(%d) ultrapassou o limite.'#13#10 + 'Último erro registrado = "%s"',
			[Self.FCycleErrorCount, EComm.Message]);
		if (Integer(Self.FCycleErrorCount) > 10) then begin
			TLogFile.Log(ErrorMessage, lmtError);
			Self.FCycleErrorCount := 0; //reseta contador global
		end;
	end;

begin
	inherited;
	DMTCPTransfer.StartClient(); //configura o tcpclient
	//Repetir os ciclos de acordo com a temporização configurada
	//O Thread primário pode enviar notificação da cancelamento que deve ser verificada ao inicio de cada ciclo
	while (not Self.Terminated) do begin
		try
			Self.DoClientCycle;
			Self.FCycleErrorCount := 0; //Reseta contador de erros do ciclo
		except
			on EComm: Exception do begin
				LSRReportError(EComm);
			end;
		end;
		//Suspende este thread até a liberação pelo thread do serviço ou de mudança de arqivo monitorado
		Self.Suspended := True;
	end;
end;

{ TClientSyncSession }

constructor TClientSyncSession.Create(AParent: TVVerClientThread; ASocket: TIdTCPClient);
begin
	inherited Create;
	Self.FParent := AParent;
	Self.FSocket := ASocket;
end;

function TClientSyncSession.GetCancelled: boolean;
begin
	Result := Self.FParent.Terminated;
end;

procedure TClientSyncSession.PostRequest(Args: array of string);
var
	req, s: string;
begin
	req := EmptyStr;
	for s in Args do begin
		req := req + s + TOKEN_DELIMITER;
	end;
	try
		Self.FSocket.IOHandler.Write(STR_CMD_VERB + req); //write -> cadeia possui fim de linha
	except
		on E: Exception do begin
			raise EVVException.Create('Erro enviando solicitação ao servidor: ' + E.Message);
		end;
	end;
end;

procedure TClientSyncSession.ReadCloseFile(downID: THandle; AStream: TFileStream);
///Informa o id a ser fechado
///recebe data de criação, modificação, acesso e tamanho total do arquivo
///Este metodo DEVE ser chamado ao final da leitura do arquivo
var
	sDate, resp                 : string;
	accDate, createDate, modDate: TDateTime;
	fSize                       : int64;
begin
	Self.PostRequest([Verb2String(vvvFileClose), IntToStr(downID)]);
	resp         := Self.ReadResponse();
	sDate        := GetDelimitedSubStr(TOKEN_DELIMITER, resp, 0);
	createDate   := TDateTime(StrToFloatFilter(sDate));
	sDate        := GetDelimitedSubStr(TOKEN_DELIMITER, resp, 1);
	modDate      := TDateTime(StrToFloatFilter(sDate));
	sDate        := GetDelimitedSubStr(TOKEN_DELIMITER, resp, 2);
	accDate      := TDateTime(StrToFloatFilter(sDate));
	fSize        := StrToInt64(GetDelimitedSubStr(TOKEN_DELIMITER, resp, 3));
	AStream.Size := fSize; //trunca de novo e abaixo de novo
	SetFileTimeProperties(AStream.Handle, createDate, accDate, modDate);
end;

function TClientSyncSession.ReadFileFirgerPrint(remoteFile: TVVSFile): TStringDynArray;
var
	ret: TStringList;
	I  : Integer;
begin
	{ TODO -oroger -cdsg : envia pedido para o servidor para calcular o hash segmentado do arquivo remoto }
	ret := TStringList.Create;
	try
		try
			Self.PostRequest([Verb2String(vvvFullFingerprint), PUBLICATION_INSTSEG, remoteFile.Filename]);
			ret.Text := Self.ReadResponse();
			SetLength(Result, ret.Count);
			for I         := 0 to ret.Count - 1 do begin
				Result[I] := ret.Strings[I];
			end;
		except
			on E: Exception do begin
				raise EVVException.Create('Cliente não pode carregar conteúdo da publicação: ' + PUBLICATION_INSTSEG + #13#10 +
					E.Message);
			end;
		end;
	finally
		ret.Free;
	end;
end;

function TClientSyncSession.ReadRemoteContent(const PubName: string): string;
begin
	try
		Self.PostRequest([Verb2String(vvvReadContent), PubName]);
		Result := Self.ReadResponse();
	except
		on E: Exception do begin
			raise EVVException.Create('Cliente não pode carregar conteúdo da publicação: ' + PubName + #13#10 + E.Message);
		end;
	end;
end;

procedure TClientSyncSession.ReadRemoteFile(inFile, outFile: TVVSFile);
var
	fps                                                      : TStringDynArray;
	remoteSegHash, localSegHash, remoteFullHash, PubName, ret: string;
	outFS                                                    : TFileStream;
	lms, ms                                                  : TMemoryStream;
	readSize, BlockSize, I, downID                           : Integer;
begin
	BlockSize := GlobalInfo.BlockSize; //tamanho dos blocos de rede
	lms       := TMemoryStream.Create;
	ms        := TMemoryStream.Create;
	try
		if (FileExists(outFile.FullFilename)) then begin
			outFS := TFileStream.Create(outFile.FullFilename, fmOpenReadWrite + fmShareExclusive);
		end else begin
			outFS := TFileStream.Create(outFile.FullFilename, fmCreate + fmShareExclusive);
		end;
		try
			fps := Self.ReadFileFirgerPrint(inFile);
			if (Assigned(inFile.Parent.Parent)) then begin
				PubName := inFile.Parent.Parent.Name;
			end else begin
				PubName := PUBLICATION_INSTSEG; //nesta versão força a barra
			end;
			Self.PostRequest([Verb2String(vvvFileDownload), PubName, inFile.Filename]);
			ret               := Self.ReadResponse(); //recebe id do download, hash do arquivo, e seu tamanho
			downID            := StrToInt(GetDelimitedSubStr(TOKEN_DELIMITER, ret, 0));
			remoteFullHash    := GetDelimitedSubStr(TOKEN_DELIMITER, ret, 1);
			localSegHash      := EmptyStr;
			for I             := low(fps) to high(fps) do begin
				remoteSegHash := fps[I];                    //coleta os hashes local e remoto
				if (outFS.Position < outFS.Size) then begin //arquivo de saida possui dados anteriores
					readSize := Math.Min(BlockSize, outFS.Size - outFS.Position);
					lms.CopyFrom(outFS, readSize);
					localSegHash := TVVerService.GetBlockHash(lms, MD5_BLOCK_ALIGNMENT);
					lms.Position := 0;
					if ((localSegHash = remoteSegHash) and (I < high(fps))) //sempre carrega segmento final
					then begin
						system.Continue;
					end else begin //retrocede segmento para ser sobrescrito
						outFS.Position := outFS.Position - readSize;
					end;
				end else begin
					readSize := BlockSize;
				end;
				Self.ReadStreamSegment(downID, I, ms, remoteSegHash); //realiza a leitura do segmento remoto
				ret := Self.FSocket.IOHandler.ReadLn();               //leitura do retorno inutil
				//TLogFile.LogDebug(Format('Pedindo segmento %d do arquivo %d', [I, downId]), DBGLEVEL_ULTIMATE);
				ms.Position := 0;
				outFS.CopyFrom(ms, readSize); { TODO -oroger -cdsg : marcar como ultima alteração }
				ms.Position := 0;             //volta para a nova leitura
			end;
			outFS.Size := outFS.Position; //trunca lixo anterior
			Self.ReadCloseFile(downID, outFS);
		finally
			outFS.Free;
		end;
	finally
		lms.Free;
		ms.Free;
	end;
end;

function TClientSyncSession.ReadResponse(): string;
var
	ret: string;
begin
	{$WARN IMPLICIT_STRING_CAST OFF} {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
	try
		Result := HTTPDecode(Self.FSocket.IOHandler.ReadLn(nil)); //leitura da resposta em si
	except
		on E: Exception do
			raise EVVException.Create('Erro lendo resposta do servidor.' + E.Message);
	end;
	try                                         //Leitura da checagem da resposta
		ret := Self.FSocket.IOHandler.ReadLn(); //codigo de retorno
		if (ret <> STR_OK_PACK) then begin
			raise EVVException.CreateFmt('Operação falhou(%s):'#13#10'%s', [ret, Result]);
		end;
	except
		on E: Exception do { TODO -oroger -cdsg : verificar e garantir o envio recebimento nesta codificação }
			raise EVVException.Create('Resposta de leitura de conteúdo não foi completa ou falha.'#13#10 + E.Message);
	end;
	{$WARN IMPLICIT_STRING_CAST ON} {$WARN IMPLICIT_STRING_CAST_LOSS ON}
end;

procedure TClientSyncSession.ReadStreamSegment(downID, SegIdx: int64; Strm: TStream; const prevHash: string);
//baixa stream do servidor
//( retorno da operação ) + (bytes no streamer a serem lidos) + (streamer) + (hash do segmento) + (bytes faltantes) + SOK
var
	sRestSize, opRet, calcHash, informHash, sBlockSize, ret: string;
	ms                                                     : TMemoryStream;
	segSize                                                : Integer;
	{$HINTS OFF}
	//restSize : int64;
	{$HINTS ON}
begin
	{ TODO -oroger -cdsg : Leitura da consulta de baixa de stream }
	Self.PostRequest([Verb2String(vvvReadSegment), IntToStr(downID), IntToStr(SegIdx)]);
	//Retorno da operação
	opRet := Self.FSocket.IOHandler.ReadLn();
	if (opRet <> STR_OK_PACK) then begin //recebeu operação ok
		raise EVVException.CreateFmt('Não foi possível ler segmento %d para identificador %d ', [SegIdx, downID]);
	end;

	//Leitura do tamanho do bloco
	sBlockSize := Self.FSocket.IOHandler.ReadLn(nil);
	segSize    := StrToInt(sBlockSize);

	ms := TMemoryStream.Create;
	try
		ms.SetSize(segSize);
		ms.Position := 0;
		Self.FSocket.IOHandler.Write(ms, segSize);
		calcHash   := TVVerService.GetBlockHash(ms, MD5_BLOCK_ALIGNMENT);
		informHash := Self.FSocket.IOHandler.ReadLn(nil);
		sRestSize  := Self.FSocket.IOHandler.ReadLn(nil);
		{$HINTS OFF}
		//restSize := StrToInt64( sRestSize ); //sem no momento
		{$HINTS ON}
		//assinatura de OK final
		ret := Self.FSocket.IOHandler.ReadLn(nil);
		if (ret <> STR_OK_PACK) then begin
			raise Exception.CreateFmt('Servidor não atendeu corretamente pedido para o segmento %d', [SegIdx]);
		end;

		ms.Position := 0;
		if ((calcHash = prevHash) and (prevHash = informHash)) then begin
			ms.Position := 0;
			Strm.CopyFrom(ms, segSize); //copia a parte do streamer correto(pode ser menor)
			ms.Position := 0;
			ms.Size     := segSize;
		end else begin
			raise Exception.CreateFmt
				('Recebidos hashes divergentes para o segmento %d: (recebido=%s, previamente informado=%s, atualmente informado=%s)',
				[SegIdx, calcHash, prevHash, informHash]);
		end;
	finally
		ms.Free;
	end;
end;

function TClientSyncSession.Synch(const PubName: string; LocalFolder, TempFolder: TManagedFolder): string;
var
	remoteFolder: TManagedFolder;
	slines      : string;
	delta       : TVVSFileList;
	f           : TVVSFile;
	ret         : Integer;
begin
	try
		slines := Self.ReadRemoteContent(PUBLICATION_INSTSEG);
	except
		on E: Exception do
			raise EVVException.Create('Operação de sincronismo falhou: ' + E.Message);
	end;

	try
		remoteFolder           := TManagedFolder.CreateRemote(slines);
		remoteFolder.BlockSize := GlobalInfo.BlockSize;
	except
		on E: Exception do
			raise EVVException.Create('Erro de parser para instância de conteúdo: '#13#10 + E.Message + #13#10 + slines);
	end;

	try
		delta := TVVSFileList.Create;
		try
			if (Self.FParent.FTempFolder.Diff(remoteFolder, delta)) then begin
				for f in delta do begin
					if (f.Parent = Self.FParent.FTempFolder) then begin
						//presenca apenas na pasta local, sem exitir no remoto -> apaga
						ret := f.Delete();
						if (ret = ERROR_SUCCESS) then begin
							f.Parent.Remove(f.Filename);
						end else begin
							TLogFile.LogDebug('Deleção de arquivo %s falhou: ' + SysErrorMessage(ret), DBGLEVEL_ALERT_ONLY);
						end;
						f.Free;
					end else begin
						Self.UpdateFile(f);
					end;
				end;
			end;
		finally
			delta.Free;
		end;
	finally
		remoteFolder.Free;
	end;

end;

procedure TClientSyncSession.UpdateFile(inFile: TVVSFile);
var
	outFile: TVVSFile;
begin
	outFile := TVVSFile.Create(Self.FParent.FTempFolder, inFile.Filename); //par para folder local com o remoto
	try
		Self.ReadRemoteFile(inFile, outFile);
	except
		on E: Exception do begin
			Self.FParent.FTempFolder.Remove(outFile.Filename);
			outFile.Free;
			raise;
		end;
	end;
end;

end.
