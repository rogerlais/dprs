{$IFDEF vvsServiceThread}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVERSvc.inc}

unit vvsServiceThread;

interface

uses
    SysUtils, Windows, Classes, XPFileEnumerator, XPThreads, vvsConsts, vvsConfig, vvsFileMgmt, IdContext,
    IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, IdCustomTCPServer,
    IdTCPServer, AppLog, IdGlobal;

type

    TVVerClientThread = class(TXPNamedThread)
    private
        FCycleErrorCount :  Integer;
        FLastVerification : TDateTime;
        FTempFolder :       TManagedFolder;
        FSyncFolder :       TManagedFolder;
        procedure DoClientCycle;
        function ReadRemoteContent() : string;
    public
        ClientName : string;
        constructor Create(CreateSuspended : boolean; const ThreadName : string); override;
        procedure DoTerminate; override;
        procedure Execute(); override;
        property LastVerification : TDateTime read FLastVerification;
    end;


    TVVerServerThread = class(TXPNamedThread)
    private
        FPublishingFolder : TManagedFolder;
        procedure DoServerCycle;
        procedure StartTCPServer;
        procedure StopTCPServer;
    protected
        procedure DoTerminate(); override;
    public
        constructor Create(CreateSuspended : boolean; const ThreadName : string); override;
        procedure Execute(); override;

    end;


implementation

uses
    vvsTCPTransfer, FileHnd, StreamHnd, StrHnd;

{ TVVerServiceThread }

constructor TVVerServerThread.Create(CreateSuspended : boolean; const ThreadName : string);
begin
    inherited;
    Self.FPublishingFolder := TManagedFolder.CreateLocal(VVSvcConfig.PathLocalInstSeg);
    Self.FPublishingFolder.Monitored := True; //remonta lista de arquivos pelos eventos do filesystem
end;

procedure TVVerServerThread.DoServerCycle;
begin
    {TODO -oroger -cdsg : Delimitar o que fara o ciclo servidor além de reenvio de logs}
end;

procedure TVVerServerThread.DoTerminate;
begin
    inherited;

end;

procedure TVVerServerThread.Execute;
{TODO -oroger -cdsg : repete o ciclo do servidor e aguarda sinalizações}
begin
    inherited;
    try
        Self.StartTCPServer; //Para o servidor inicia escuta na porta
    except
        on E : Exception do begin
            TLogFile.Log('Serviço não pode continuar e será encerrado. Razão:' + E.Message, lmtError);
            raise;
        end;
    end;
    while (not Self.Terminated) do begin
        try
            Self.DoServerCycle();
        except
            on E : Exception do begin
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
        on E : Exception do begin
            TLogFile.Log('Chamada StartTCPServer retornou erro:' + E.Message, lmtError);
            raise;
        end;
    end;
end;

procedure TVVerServerThread.StopTCPServer;
begin

end;

{ TClientThread }

constructor TVVerClientThread.Create(CreateSuspended : boolean; const ThreadName : string);
begin
    inherited;
    Self.FTempFolder := TManagedFolder.CreateLocal(VVSvcConfig.PathTempDownload);
    if (VVSvcConfig.ParentServer <> EmptyStr) then begin
        Self.FSyncFolder := TManagedFolder.CreateRemote(VVSvcConfig.ParentServer);
    end;
end;

procedure TVVerClientThread.DoClientCycle;
var
    localHash, remoteHash : string;
begin
    {TODO -oroger -cdsg : Buscar por atualizações}
    DMTCPTransfer.StartSession(VVSvcConfig.ClientName, 0);
    try

    finally
        DMTCPTransfer.EndSession(VVSvcConfig.ClientName);
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
 /// 1 - Maquina secundária:
 ///     a) Enumera todos os arquivos da pasta de origem
 ///    b) Repassa todo os arquivos para a maquina primária
 ///    c) Realiza seu backup local
 /// 2 - Máquina primária:
 ///     a) Move todos os da pasta de recepção remota para a pasta de transmissão
 ///     b) Move todos os arquivos da pasta transmitidos para a de backup global
 ///     c) Reorganiza todos os arquivos do backup global
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
var
    ErrorMessage : string;

    procedure LSRReportError(EComm : Exception);
    //notificar agente monitorador
    begin
        //Registrar o erro e testar o contador de erros
        Inc(Self.FCycleErrorCount);
        ErrorMessage := Format('Quantidade de erros consecutivos(%d) ultrapassou o limite.'#13#10 +
            'Último erro registrado = "%s"', [Self.FCycleErrorCount, EComm.Message]);
        if (Integer(Self.FCycleErrorCount) > 10) then begin
            TLogFile.Log(ErrorMessage, lmtError);
            Self.FCycleErrorCount := 0; //reseta contador global
        end;
    end;

begin
    inherited;
    DMTCPTransfer.StartClient; //configura o tcpclient
    //Repetir os ciclos de acordo com a temporização configurada
    //O Thread primário pode enviar notificação da cancelamento que deve ser verificada ao inicio de cada ciclo
    while (not Self.Terminated) do begin
        try
            Self.DoClientCycle;
            Self.FCycleErrorCount := 0; //Reseta contador de erros do ciclo
        except
            on EComm : Exception do begin
                LSRReportError(EComm);
            end;
        end;
        //Suspende este thread até a liberação pelo thread do serviço ou de mudança de arqivo monitorado
        Self.Suspended := True;
    end;
end;

function TVVerClientThread.ReadRemoteContent : string;
var
    lastStr, s : string;
    csocket :    TIdTCPClient;
begin
    csocket := DMTCPTransfer.tcpclnt;
    if (not csocket.Connected) then begin
        raise ESVCLException.Create('Canal com o servidor não estabelecido antecipadamente');
    end;
    //Passados obrigatoriamente nesta ordem!!!
    s := STR_CMD_VERB + STR_VERB_READCONTENT + TOKEN_DELIMITER + 'INSTSEG'; //Verbo de leitura de conteudo da publicação instseg
    csocket.IOHandler.WriteLn(s); //envia o comando
    //csocket.IOHandler.WriteFile();
    Result  := EmptyStr;
    lastStr := EmptyStr;
    repeat
		 s := csocket.IOHandler.ReadLn();
		 if (TStrHnd.IsPertinent(s, [STR_OK_PACK, STR_FAIL_HASH, STR_FAIL_SIZE, STR_FAIL_VERB], True)) then begin
			 lastStr := s;
		 end else begin //Execução normal
			 Result := Result + s;
		 end;
    until (lastStr <> EmptyStr);
    if (lastStr <> STR_OK_PACK) then begin
        raise ESVCLException.CreateFmt('Retorno de erro de execução de comando: "%s" resposta="%s".',
            [STR_VERB_READCONTENT, lastStr]);
    end;
end;

end.
