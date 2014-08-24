{$IFDEF vvSvcDM}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVERSvc.inc}

unit vvSvcDM;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs, IdBaseComponent, IdMessage, IdComponent, IdRawBase,
    IdRawClient, IdIcmpClient, FileInfo, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase,
    IdSMTP, XPThreads, ExtCtrls, vvsConfig, vvsServiceThread, WinFileNotification, vvsFileMgmt;

type
    TVVerService = class(TService)
        mailMsgNotify : TIdMessage;
        icmpclntMain :  TIdIcmpClient;
        fvInfo :        TFileVersionInfo;
        smtpSender :    TIdSMTP;
        tmrCycleEvent : TTimer;
        filemonit :     TWinFileSystemMonitor;
        procedure ServiceAfterInstall(Sender : TService);
        procedure ServiceBeforeInstall(Sender : TService);
        procedure ServiceCreate(Sender : TObject);
        procedure ServiceStart(Sender : TService; var Started : boolean);
        procedure ServiceContinue(Sender : TService; var Continued : boolean);
        procedure filemonitChanged(Sender : TWinFileSystemMonitor; AFolderItem : TFolderItemInfo);
        procedure ServicePause(Sender : TService; var Paused : boolean);
    private
        { Private declarations }
        FLastLogCheck :  Word;
        FLastPingReply : boolean;
        FServerThread :  TVVerServerThread;
        FClientThread :  TVVerClientThread;
        FLocalStorage :  TManagedFolder;
        FLastHash :      string;
        FLastUpdate :    TDateTime;
        procedure LocalStorageMonitoring(GoActive : boolean);
        procedure AddDestinations;
        procedure CheckLogs();
        function isIntranetConnected() : boolean;
        function SendMailNotification(const NotificationText : string) : boolean;
    public
        class function LogFilePrefix() : string;
        function GetServiceController : TServiceController; override;
        destructor Destroy; override;
        { Public declarations }
    end;

var
    VVerService : TVVerService;

implementation

uses
    WinReg32, FileHnd, AppLog, vvsConsts, XPFileEnumerator, XPTypes, StrHnd, IdGlobal,
    Str_Pas, IdEMailAddress, WinNetHnd;

{$R *.DFM}

procedure ServiceController(CtrlCode : DWord); stdcall;
begin
    VVerService.Controller(CtrlCode);
end;

procedure TVVerService.AddDestinations;
var
    dst : TIdEMailAddressItem;
    lst : TStringList;
    x :   Integer;
begin
    lst := TStringList.Create;
    try
        lst.Delimiter     := ';';
        lst.DelimitedText := VVSvcConfig.NotificationList;
        for x := 0 to lst.Count - 1 do begin
            dst      := Self.mailMsgNotify.Recipients.Add();
            dst.Address := lst.Strings[x];
            dst.Name := 'SESOP - Verificador de Sistemas eleitorais';
        end;
    finally
        lst.Free;
    end;
end;

procedure TVVerService.CheckLogs;
 /// <summary>
 /// Buscar por logs posteriores a data de registro, enviando todos aqueles que possuirem erros.
/// A cada envio com sucesso avancar a data de registro para a data do respectivo arquivo de log e buscar pelo mais antigo até chegar ao log atual
 /// </summary>
 /// <remarks>
 ///
 /// </remarks>
var
    Files :  IEnumerable<TFileSystemEntry>;
    f :      TFileSystemEntry;
    currLogName, newLogName, sentPath : string;
    logText : TXPStringList;
    dummy :  Integer;
    sentOK : boolean;
    lt :     TSystemTime;
begin
    // Registra a hora da ultima passagem de verificação de log
    currLogName := AppLog.TLogFile.GetDefaultLogFile.FileName;
    GetLocalTime(lt);
    if (Self.FLastLogCheck <> lt.wHour) then begin
        newLogName := TFileHnd.ConcatPath([VVSvcConfig.PathServiceLog, TVVerService.LogFilePrefix() +
            FormatDateTime('YYYYMMDD', Now())]) + '.log';
        if (currLogName <> newLogName) then begin
            AppLog.TLogFile.GetDefaultLogFile.FileName := newLogName;
            currLogName := newLogName;
        end;
        Self.FLastLogCheck := lt.wHour; //Registra a mudanca de hora
    end;
    // filtra arquivos referentes apenas a este runtime
    Files := TDirectory.FileSystemEntries(VVSvcConfig.PathServiceLog, TVVerService.LogFilePrefix + '*.log', False);
    for f in Files do begin
        if (not Sametext(f.FullName, currLogName)) then begin // Pula o arquivo em uso no momento como saida de log
            logText := TXPStringList.Create;
            try
                logText.LoadFromFile(f.FullName);
                dummy  := 1; // Sempre do inicio
                sentOK := not logText.FindPosIgnoreCase('erro:', dummy, dummy); //Marca para envio em caso de erro presente
                sentOK := sentOK and (not logText.FindPosIgnoreCase('Alarme:', dummy, dummy)); //Idem acima para o caso de alarmes
                if (not sentOK) then begin
                    try
                        sentOK := Self.SendMailNotification(logText.Text);
                    except
                        on E : Exception do begin // Apenas logar a falha de envio e continuar com os demais arquivos
                            TLogFile.Log('Envio de notificações de erro falhou:'#13#10 + E.Message, lmtError);
                            sentOK := False;
                        end;
                    end;
                end;
                // mover arquivo para a pasta de enviados applog
                if (sentOK) then begin
                    sentPath := VVSvcConfig.PathServiceLog + '\Sent\';
                    ForceDirectories(sentPath);
                    sentPath := sentPath + f.Name;
                    sentPath := TFileHnd.NextFamilyFilename(sentPath);
                    if (not MoveFile(PWideChar(f.FullName), PWideChar((sentPath)))) then begin
                        TLogFile.Log('Final do processamento de arquivo de log falhou:'#13#10 +
                            SysErrorMessage(GetLastError()), lmtError);
                    end;
                end;
            finally
                logText.Free;
            end;
        end;
    end;
end;

destructor TVVerService.Destroy;
begin
	 Self.FLocalStorage.Free;
	 Self.filemonit.IsActive:=False;
	 if ( Assigned( Self.FServerThread ) ) then begin
		Self.FServerThread.Terminate;
		FreeAndNil(Self.FServerThread);
	 end;
	 if ( Assigned( Self.FClientThread ) ) then begin
		Self.FClientThread.Terminate;
		FreeAndNil( Self.FClientThread);
	 end;
    inherited;
end;

procedure TVVerService.filemonitChanged(Sender : TWinFileSystemMonitor; AFolderItem : TFolderItemInfo);
begin
    TLogfile.LogDebug('Alteração: ' + AFolderItem.Name, DBGLEVEL_ULTIMATE);
    {
     MessageBoxW(0, PWideChar('Alteração: ' + AFolderItem.Name ), PWideChar(Application.Title),
         MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
     }
end;

function TVVerService.GetServiceController : TServiceController;
begin
    Result := ServiceController;
end;

function TVVerService.isIntranetConnected : boolean;
    ///Alerta: Método não thread safe
var
    x : Integer;
begin
    Self.icmpclntMain.Protocol := 1;
    Self.icmpclntMain.ReceiveTimeout := 2000;
    Self.icmpclntMain.ProtocolIPv6 := 58;
    Self.icmpclntMain.IPVersion := Id_IPv4;
    Self.icmpclntMain.PacketSize := 32;
    Self.icmpclntMain.Host := VVSvcConfig.ParentServer;
    Result := False;
    Self.FLastPingReply := Result;
    for x := 0 to 5 do begin
        try
            Self.icmpclntMain.Ping();
        except
            on E : Exception do begin
                //Sem tratamento -> espera nova tentativa
                TLogFile.LogDebug(Format('Sem conectividade com a intranet(%s): %s', [VVSvcConfig.ParentServer, E.Message]),
                    DBGLEVEL_ULTIMATE);
            end;
        end;
        Result := Result or Self.FLastPingReply;
        if (Result) then begin
            Self.FLastPingReply := False;
            Break;
        end;
    end;
end;

procedure TVVerService.LocalStorageMonitoring(GoActive : boolean);
begin
    if (not Assigned(Self.FLocalStorage)) then begin
        //carrega a estrutura de arquivos do repositorio local
        Self.FLocalStorage := TManagedFolder.Create(VVSvcConfig.PathLocalInstSeg);
    end else begin
        if (GoActive and (Self.filemonit.IsActive xor GoActive)) then begin
            Self.FLocalStorage.Reload();
		 end;
	 end;
	 Self.FLastHash   := Self.FLocalStorage.GlobalHash;
	 Self.FLastUpdate := Now();
    Self.filemonit.MonitoredChanges := [ctFileName, ctDirName, ctSize, ctLastWriteTime, ctCreationTime];
    Self.filemonit.Folder    := VVSvcConfig.PathLocalInstSeg;
    Self.filemonit.Recursive := True;
    Self.filemonit.OnFolderChange := Self.filemonitChanged;
    Self.filemonit.IsActive  := GoActive;
end;

class function TVVerService.LogFilePrefix : string;
begin
    Result := APP_SERVICE_NAME + '_' + TFileHnd.ExtractFilenamePure(ParamStr(0)) + '_';
end;

function TVVerService.SendMailNotification(const NotificationText : string) : boolean;
begin
    Result := False;
    if (not Self.isIntranetConnected) then begin //Verificar a conectividade com a intranet
        Exit;
    end;

    mailMsgNotify.ConvertPreamble := True;
    mailMsgNotify.AttachmentEncoding := 'UUE';
    mailMsgNotify.Encoding      := mePlainText;
    mailMsgNotify.From.Address  := VVSvcConfig.NotificationSender;
    mailMsgNotify.From.Name     := Application.Title;
    mailMsgNotify.From.Text     := Format(' %s <%s>', [Application.Title, VVSvcConfig.NotificationSender]);
    mailMsgNotify.From.Domain   := Str_Pas.GetDelimitedSubStr('@', VVSvcConfig.NotificationSender, 1);
    mailMsgNotify.From.User     := Str_Pas.GetDelimitedSubStr('@', VVSvcConfig.NotificationSender, 0);
    mailMsgNotify.Sender.Address := VVSvcConfig.NotificationSender;
    mailMsgNotify.Sender.Name   := APP_NOTIFICATION_DESCRIPTION;
    mailMsgNotify.Sender.Text   := Format('"%s" <%s>', [APP_NOTIFICATION_DESCRIPTION, VVSvcConfig.NotificationSender]);
    mailMsgNotify.Sender.Domain := mailMsgNotify.From.Domain;
    mailMsgNotify.Sender.User   := mailMsgNotify.From.User;

    // Coletar informações de destino de mensagem com possibilidade de macros no mesmo arquivo de configuração
    Self.AddDestinations();

    Self.mailMsgNotify.Subject   := Format(SUBJECT_TEMPLATE, [Self.fvInfo.FileVersion, WinnetHnd.GetComputerName(),
        FormatDateTime('yyyyMMDDhhmm', Now())]);
    Self.mailMsgNotify.Body.Text := NotificationText + #13#10'****** Arquivo de configuração ******' +
        #13#10 + VVSvcConfig.ToString;
    //insere arquivo de configuração ao final
    try
        Self.smtpSender.Connect;
        Self.smtpSender.Send(Self.mailMsgNotify);
        Self.smtpSender.Disconnect(True);
        Result := True;
    except
        on E : Exception do begin
            raise ESVCLException.Create('Falha enviando notificação: ' + E.Message);
        end;
    end;
end;

procedure TVVerService.ServiceAfterInstall(Sender : TService);
 /// <summary>
 /// Registra as informações de função deste serviço
 /// </summary>
var
    Reg :     TRegistryNT;
    svcType : Integer;
    svcKey :  string;
begin
    Reg := TRegistryNT.Create();
    try
        svcKey := TFileHnd.ConcatPath(['HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services', Self.Name]);
        Reg.WriteFullString(svcKey + '\Description', 'Verificação das versões dos aplicativos seguros.', True);
        Reg.ReadFullInteger(svcKey + '\Type', svcType);
        svcType := svcType or $100; //Nono bit para indicar interativo
        Reg.WriteFullInteger(svcKey + '\Type', svcType, True);
    finally
        Reg.Free;
    end;
    TLogFile.Log('Serviço instalado com sucesso neste computador', lmtAlarm);
end;

procedure TVVerService.ServiceBeforeInstall(Sender : TService);
 /// <summary>
 /// Ajusta os parametros do serviço antes de sua instalação. Dentre as ações está levantar o serviço como o último da lista de
 /// serviços
 /// </summary>
 /// <remarks>
 ///
 /// </remarks>
var
    Reg : TRegistryNT;
    lst : TStringList;
begin
    Reg := TRegistryNT.Create;
    lst := TStringList.Create;
    try
        Reg.ReadFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', lst);
        if ((lst.IndexOf(APP_SERVICE_GROUP) < 0)) then begin
            lst.Add(APP_SERVICE_GROUP);
            TLogFile.Log('Alterando ordem de inicializaçao dos serviços no registro local', lmtInformation);
            if (not IsDebuggerPresent()) then begin
                Reg.WriteFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', lst, True);
            end;
        end;
    finally
        Reg.Free;
        lst.Free;
    end;
    TLogFile.Log('Ordem de carga do serviço alterada com SUCESSO no computador local', lmtInformation);
end;

procedure TVVerService.ServiceContinue(Sender : TService; var Continued : boolean);
 /// <summary>
 /// Reincio do servico
 /// </summary>
 /// <remarks>
 ///
 /// </remarks>
begin
    TLogFile.LogDebug('Chamada de ServiceContinue em execução', DBGLEVEL_ULTIMATE);

    // Liberação do thread servidor
    if Assigned(Self.FServerThread) then begin
        if Self.FServerThread.Suspended then begin
            TLogFile.LogDebug('Liberando thread de serviço servidor de conexões', DBGLEVEL_ULTIMATE);
            Self.LocalStorageMonitoring(True);
            Self.FServerThread.Start; //Dispara o thread de serviço
            Sleep(300);
        end;
        Continued := (not Self.FServerThread.Finished);
    end else begin
        Continued := False;
        TLogFile.Log('Thread de Serviço servidor não criado anteriormente!');
    end;

    //Liberação do thread cliente
    if Assigned(Self.FClientThread) then begin
        if Self.FClientThread.Suspended then begin
            TLogFile.LogDebug('Liberando thread de serviço cliente', DBGLEVEL_ULTIMATE);
            Self.FClientThread.Start; //Dispara o thread de serviço
            Sleep(300);
        end;
        Continued := (not Self.FClientThread.Finished);
    end else begin
        Continued := False;
        TLogFile.Log('Thread de Serviço cliente não criado anteriormente!');
    end;

        {
        // Para de aceitar conexoes se no modo servidor
       TLogFile.LogDebug('Abrindo conexões de rede', DBGLEVEL_DETAILED);
       if (GlobalConfig.RunAsServer) then begin
           try
               DMTCPTransfer.tcpsrvr.StartListening;
               Continued := True;
           except
               on E : Exception do begin
                   Continued := False;
                   TLogFile.Log(Format('Serviço não foi capaz de iniciar escuta na porta:%d'#13#10 + E.Message,
                       [GlobalConfig.NetServicePort]), lmtError);
               end;
            end;
        end;
       }
end;

procedure TVVerService.ServiceCreate(Sender : TObject);
begin
    Self.DisplayName := APP_SERVICE_DISPLAYNAME;
    Self.Interactive := True;
    Self.WaitHint    := 1000;
    Self.smtpSender.Host := 'smtp.tre-pb.gov.br';
    Self.tmrCycleEvent.Interval := 60000;
    Self.tmrCycleEvent.Enabled := False;
end;

procedure TVVerService.ServicePause(Sender : TService; var Paused : boolean);
begin
    TLogFile.LogDebug('Chamada de ServicePause em execução', DBGLEVEL_ULTIMATE);

    // Liberação do thread servidor
    if Assigned(Self.FServerThread) then begin
        if Self.FServerThread.Suspended then begin
            TLogFile.LogDebug('Liberando thread de serviço servidor de conexões', DBGLEVEL_ULTIMATE);
            Self.FServerThread.Start; //Dispara o thread de serviço
            Sleep(300);
        end;
        Paused := (not Self.FServerThread.Finished);
    end else begin
        Paused := False;
        TLogFile.Log('Thread de Serviço servidor não criado anteriormente!');
    end;

    //Liberação do thread cliente
    if Assigned(Self.FClientThread) then begin
        if Self.FClientThread.Suspended then begin
            TLogFile.LogDebug('Liberando thread de serviço cliente', DBGLEVEL_ULTIMATE);
            Self.FClientThread.Start; //Dispara o thread de serviço
            Sleep(300);
        end;
        Paused := (not Self.FClientThread.Finished);
    end else begin
        Paused := False;
        TLogFile.Log('Thread de Serviço cliente não criado anteriormente!');
    end;
end;

procedure TVVerService.ServiceStart(Sender : TService; var Started : boolean);
var
    msvc : string;
begin
    try
        Self.CheckLogs(); // proteger chamada ,pois rede pode estar instavel neste momento
        TLogFile.Log('Iniciando serviço de verificação de versões', lmtInformation);
    except
        on E : Exception do begin
            TLogFile.Log('Checagem de logs falhou.'#13#10 + E.Message, lmtWarning);
        end;
    end;
    case Self.Status of
        csStopped : begin
            msvc := 'csStopped';
        end;
        csStartPending : begin
            msvc := 'csStartPending';
        end;
        csStopPending : begin
            msvc := 'csStopPending';
        end;
        csRunning : begin
            msvc := 'csRunning';
        end;
        csContinuePending : begin
            msvc := 'csContinuePending';
        end;
        csPausePending : begin
            msvc := 'csPausePending';
        end;
        csPaused : begin
            msvc := 'csPaused';
        end;
        else begin
            msvc := 'Estado desconhecido';
        end
    end;

    TLogFile.LogDebug('Transição de estado durante início do serviço. Estado anterior = ' + msvc, DBGLEVEL_ULTIMATE);

    if (Self.Status in [csStartPending, csStopped]) then begin // veio de parada(não pause)
        TLogFile.Log('Criando thread de serviço no modo Servidor', lmtInformation);
        Self.FServerThread      := vvsServiceThread.TVVerServerThread.Create(True);
        Self.FServerThread.Name := APP_SERVICE_NAME + 'Server'; // Nome de exibição do thread primário servidor

        TLogFile.Log('Criando thread de serviço no modo Cliente', lmtInformation);
        Self.FClientThread      := vvsServiceThread.TVVerClientThread.Create(True);
        Self.FClientThread.Name := APP_SERVICE_NAME + 'Client'; // Nome de exibição do thread primário servidor

    end;

    Self.ServiceContinue(Sender, Started); // Rotinas de resumo do thread de servico
    if (Started) then begin
        Self.tmrCycleEvent.Interval := VVSvcConfig.CycleInterval;
        Self.tmrCycleEvent.Enabled  := True; // Liberar disparo de liberação de thread de serviço
        TLogFile.Log('Serviço ' + Self.Name + ' - Versão: ' + Self.fvInfo.FileVersion + ' - iniciado com sucesso.',
            lmtInformation);
    end else begin
        TLogFile.Log('Serviço falhou em sua carga.', lmtWarning);
    end;
end;

end.
