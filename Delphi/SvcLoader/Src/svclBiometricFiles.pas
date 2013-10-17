{$IFDEF svclBiometricFiles}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}
unit svclBiometricFiles;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs, svclTransBio, ExtCtrls,
    IdMessage, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase,
    IdMessageClient, IdSMTPBase, IdSMTP, FileInfo, XPThreads, IdRawBase, IdRawClient, IdIcmpClient;

type
    TBioFilesService = class(TService)
        tmrCycleEvent : TTimer;
        smtpSender :    TIdSMTP;
        mailMsgNotify : TIdMessage;
        fvInfo :        TFileVersionInfo;
        icmpclntMain :  TIdIcmpClient;
        procedure ServiceAfterInstall(Sender : TService);
        procedure ServiceBeforeInstall(Sender : TService);
        procedure ServiceCreate(Sender : TObject);
        procedure ServicePause(Sender : TService; var Paused : boolean);
        procedure ServiceStart(Sender : TService; var Started : boolean);
        procedure ServiceStop(Sender : TService; var Stopped : boolean);
        procedure ServiceContinue(Sender : TService; var Continued : boolean);
        procedure tmrCycleEventTimer(Sender : TObject);
        procedure icmpclntMainReply(ASender : TComponent; const AReplyStatus : TReplyStatus);
    private
        { Private declarations }
        FSvcThread :     TXPNamedThread; // Dualidade entre o thread de cliente e de servidor
        FLastLogCheck :  Word;
        FLastPingReply : boolean;
        procedure AddDestinations;
        procedure CheckLogs();
        function isIntranetConnected() : boolean;
    public
        class function LogFilePrefix() : string;
        constructor CreateNew(AOwner : TComponent; Dummy : Integer = 0); override;
        function GetServiceController : TServiceController; override;
        procedure ServiceThreadPulse();
        function SendMailNotification(const NotificationText : string) : boolean;
        { Public declarations }
    end;

var
    BioFilesService : TBioFilesService;

implementation

uses
    AppLog, WinReg32, FileHnd, svclConfig, svclUtils, WinnetHnd, APIHnd, svclEditConfigForm, Str_Pas,
    IdEMailAddress, XPFileEnumerator, StrHnd, svclTCPTransfer, IdGlobal;

{$R *.DFM}

const
    SUBJECT_TEMPLATE  = 'BioFilesService - Versão: %s - %s - %s';
    SWITCH_AUTOCONFIG = 'autoconfig'; //informa que durante a instalação janela de configuração não será mostrada

procedure ServiceController(CtrlCode : DWord); stdcall;
begin
    BioFilesService.Controller(CtrlCode);
end;

procedure InitServiceLog();
/// Altera o nome do log a ser gerado para esta iniciação do serviço de modo a ser unico por dia de levantameto
var
    LogFileName : string;
begin
    LogFileName := TFileHnd.ConcatPath([GlobalConfig.PathServiceLog, TBioFilesService.LogFilePrefix() +
        FormatDateTime('YYYYMMDD', Now())]) + '.log';
    try
        AppLog.TLogFile.GetDefaultLogFile.FileName := LogFileName;
    except
        on E : Exception do begin
            AppLog.AppFatalError('Erro fatal iniciando aplicativo'#13#10 + E.Message, 10);
        end;
    end;
end;

procedure TBioFilesService.AddDestinations;
var
    dst : TIdEMailAddressItem;
    lst : TStringList;
    x :   Integer;
begin
    lst := TStringList.Create;
    try
        lst.Delimiter     := ';';
        lst.DelimitedText := GlobalConfig.NotificationList;
        for x := 0 to lst.Count - 1 do begin
            dst      := Self.mailMsgNotify.Recipients.Add();
            dst.Address := lst.Strings[x];
            dst.Name := 'SESOP - Verificador de Sistemas eleitorais';
        end;
    finally
        lst.Free;
    end;
end;

procedure TBioFilesService.CheckLogs;
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
        newLogName := TFileHnd.ConcatPath([GlobalConfig.PathServiceLog, TBioFilesService.LogFilePrefix() +
            FormatDateTime('YYYYMMDD', Now())]) + '.log';
        if (currLogName <> newLogName) then begin
            AppLog.TLogFile.GetDefaultLogFile.FileName := newLogName;
            currLogName := newLogName;
        end;
        Self.FLastLogCheck := lt.wHour; //Registra a mudanca de hora
    end;
    // filtra arquivos referentes apenas a este runtime
    Files := TDirectory.FileSystemEntries(GlobalConfig.PathServiceLog, TBioFilesService.LogFilePrefix + '*.log', False);
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
                    sentPath := GlobalConfig.PathServiceLog + '\Sent\';
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

constructor TBioFilesService.CreateNew(AOwner : TComponent; Dummy : Integer);
begin
    inherited;
    //Para aplicações externas de teste instancia criada a parte, ao contrario do modo de serviços
    if (not Assigned(DMTCPTransfer)) then begin
        Application.CreateForm(TDMTCPTransfer, DMTCPTransfer);
    end;
end;

function TBioFilesService.GetServiceController : TServiceController;
begin
    Result := ServiceController;
end;

procedure TBioFilesService.icmpclntMainReply(ASender : TComponent; const AReplyStatus : TReplyStatus);
begin
    Self.FLastPingReply := Self.FLastPingReply or (AReplyStatus.ReplyStatusType = rsEcho);
end;

function TBioFilesService.isIntranetConnected : boolean;
    ///Alerta: Método não thread safe
var
    x : Integer;
begin
    Self.icmpclntMain.Protocol := 1;
    Self.icmpclntMain.ReceiveTimeout := 2000;
    Self.icmpclntMain.ProtocolIPv6 := 58;
    Self.icmpclntMain.IPVersion := Id_IPv4;
    Self.icmpclntMain.PacketSize := 32;
    Self.icmpclntMain.Host := GlobalConfig.ServerName;
    Result := False;
    Self.FLastPingReply := Result;
    for x := 0 to 5 do begin
        try
            Self.icmpclntMain.Ping();
        except
            on E : Exception do begin
                //Sem tratamento -> espera nova tentativa
                TLogFile.LogDebug(Format('Sem conectividade com a intranet(%s): %s', [GlobalConfig.ServerName, E.Message]),
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

class function TBioFilesService.LogFilePrefix : string;
begin
    Result := APP_SERVICE_NAME + '_' + TFileHnd.ExtractFilenamePure(ParamStr(0)) + '_';
end;

function TBioFilesService.SendMailNotification(const NotificationText : string) : boolean;
begin
    Result := False;
    if (not Self.isIntranetConnected) then begin //Verificar a conectividade com a intranet
        Exit;
    end;

	 mailMsgNotify.ConvertPreamble := True;
	 mailMsgNotify.AttachmentEncoding := 'UUE';
    mailMsgNotify.Encoding      := mePlainText;
    mailMsgNotify.From.Address  := GlobalConfig.NotificationSender;
    mailMsgNotify.From.Name     := Application.Title;
    mailMsgNotify.From.Text     := Format(' %s <%s>', [Application.Title, GlobalConfig.NotificationSender]);
    mailMsgNotify.From.Domain   := Str_Pas.GetDelimitedSubStr('@', GlobalConfig.NotificationSender, 1);
    mailMsgNotify.From.User     := Str_Pas.GetDelimitedSubStr('@', GlobalConfig.NotificationSender, 0);
    mailMsgNotify.Sender.Address := GlobalConfig.NotificationSender;
    mailMsgNotify.Sender.Name   := APP_NOTIFICATION_DESCRIPTION;
    mailMsgNotify.Sender.Text   := Format('"%s" <%s>', [APP_NOTIFICATION_DESCRIPTION, GlobalConfig.NotificationSender]);
    mailMsgNotify.Sender.Domain := mailMsgNotify.From.Domain;
    mailMsgNotify.Sender.User   := mailMsgNotify.From.User;

    // Coletar informações de destino de mensagem com possibilidade de macros no mesmo arquivo de configuração
    Self.AddDestinations();

    Self.mailMsgNotify.Subject   := Format(SUBJECT_TEMPLATE, [Self.fvInfo.FileVersion, WinnetHnd.GetComputerName(),
        FormatDateTime('yyyyMMDDhhmm', Now())]);
	 Self.mailMsgNotify.Body.Text := NotificationText + #13#10'****** Arquivo de configuração ******' + #13#10 + GlobalConfig.ToString; //insere arquivo de configuração ao final
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

procedure TBioFilesService.ServiceAfterInstall(Sender : TService);
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
        Reg.WriteFullString(svcKey + '\Description',
            'Replica os arquivos de dados biométricos para máquina primária, possibilitando o transporte centralizado.', True);
        Reg.ReadFullInteger(svcKey + '\Type', svcType);
        svcType := svcType or $100; //Nono bit para indicar interativo
        Reg.WriteFullInteger(svcKey + '\Type', svcType, True);
    finally
        Reg.Free;
    end;
    TLogFile.Log('Serviço instalado com sucesso neste computador', lmtAlarm);
end;

procedure TBioFilesService.ServiceBeforeInstall(Sender : TService);
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
    try
		 if (GlobalConfig.isHotKeyPressed() or (not FindCmdLineSwitch(SWITCH_AUTOCONFIG))) then begin
            //Não invocar dialogo para o caso de instalação automatica
            TEditConfigForm.EditConfig; // Chama janela de configuração para exibição
        end;
    except
        on E : Exception do begin
            AppFatalError('Configurações do serviço não efetivadas'#13#10 + E.Message, 8666, True);
        end;
    end;

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

procedure TBioFilesService.ServiceContinue(Sender : TService; var Continued : boolean);
 /// <summary>
 /// Reincio do servico
 /// </summary>
 /// <remarks>
 ///
 /// </remarks>
begin
    TLogFile.LogDebug('Chamada de ServiceContinue em execução', DBGLEVEL_ULTIMATE);
    // Rotina de inicio do servico, dispara thread da operação
    if Assigned(Self.FSvcThread) then begin
        if Self.FSvcThread.Suspended then begin
            TLogFile.LogDebug('Liberando thread de serviço', DBGLEVEL_ULTIMATE);
            Self.FSvcThread.Start; //Dispara o thread de serviço
            Sleep(300);
        end;
        Continued := (not Self.FSvcThread.Finished);
    end else begin
        Continued := False;
        TLogFile.Log('Thread de Serviço não criado anteriormente!');
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

procedure TBioFilesService.ServiceCreate(Sender : TObject);
var
    dp : TDependency;
begin
    {TODO -oroger -cdsg : testar forma de atribuir depuração para carga por attachprocess }
     (*
     while DebugHook <> 0 do begin
         Break;
     end;
     *)
    Self.DisplayName := APP_SERVICE_DISPLAYNAME;
    Self.LoadGroup := APP_SERVICE_GROUP;
    dp      := TDependency(Self.Dependencies.Add); //Insere dependencia do dsn(topo da pilha tcp/ip)
    dp.Name := 'DnsCache';
    dp.IsGroup := False;
end;

procedure TBioFilesService.ServicePause(Sender : TService; var Paused : boolean);
 /// <summary>
 /// Pause do servico
 /// </summary>
 /// <remarks>
 ///
 /// </remarks>
begin
    Self.tmrCycleEvent.Enabled := False; // Suspende timer de liberação do thread do serviço
    if Assigned(Self.FSvcThread) and (not Self.FSvcThread.Suspended) then begin
        Self.FSvcThread.Suspended := True;
    end;

    // Para de aceitar conexoes se no modo servidor
    if (GlobalConfig.RunAsServer) then begin
        DMTCPTransfer.tcpsrvr.StopListening;
    end;

    Paused := Self.FSvcThread.Suspended;
end;

procedure TBioFilesService.ServiceStart(Sender : TService; var Started : boolean);
var
    msvc : string;
begin
    if (GlobalConfig.RunAsServer) then begin
        TLogFile.Log('Iniciando o serviço no modo servidor....', lmtInformation);
    end else begin
        TLogFile.Log('Iniciando o serviço no modo cliente...', lmtInformation);
    end;

    try
        Self.CheckLogs(); // proteger chamada ,pois rede pode estar instavel neste momento
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

    if (Self.Status in [csStartPending, csStopped]) then begin
        if (GlobalConfig.RunAsServer) then begin // veio de parada(não pause)
            TLogFile.Log('Criando thread de serviço no modo servidor', lmtInformation);
            Self.FSvcThread := TTransBioServerThread.Create(True);
        end else begin
            TLogFile.Log('Criando thread de serviço no modo cliente', lmtInformation);
            Self.FSvcThread := TTransBioThread.Create(True);
        end;
        Self.FSvcThread.Name := APP_SERVICE_DISPLAYNAME; // Nome de exibição do thread primário
    end;

    Self.ServiceContinue(Sender, Started); // Rotinas de resumo do thread de servico
    if (Started) then begin
        Self.tmrCycleEvent.Interval := GlobalConfig.CycleInterval;
        Self.tmrCycleEvent.Enabled  := True; // Liberar disparo de liberação de thread de serviço
        TLogFile.Log('Serviço iniciado com sucesso.', lmtInformation);
    end else begin
        TLogFile.Log('Serviço falhou em sua carga.', lmtWarning);
    end;
end;

procedure TBioFilesService.ServiceStop(Sender : TService; var Stopped : boolean);
 /// <summary>
 /// Destroi o thread de servico parando o servico
 /// </summary>
 /// <remarks>
 ///
 /// </remarks>
var
    cnt : Word;
begin
    // Para timer de gatilho do thread de serviço
    if (Assigned(Self.FSvcThread)) then begin
        Self.FSvcThread.Terminate; // informa do fim da vida deste thread
        cnt := 0;
        while ((not Self.FSvcThread.Finished) and (cnt < 5)) do begin // aguarda tempo para liberação(tempo chutado)
            Sleep(300);
            Inc(cnt);
        end;
        if (not Self.FSvcThread.Finished) then begin
            TLogFile.Log('Thread de serviço não parou em tempo hábil', lmtError);
        end;
        FreeAndNil(Self.FSvcThread);
    end;
    Self.tmrCycleEvent.Interval := GlobalConfig.CycleInterval;
    Self.tmrCycleEvent.Enabled := False; // Para a reativação do thread de serviço
    Stopped := True;
end;

procedure TBioFilesService.ServiceThreadPulse;
/// Dispara libera o thread de serviço de seu estado de ociosidade
begin
    if (Assigned(Self.FSvcThread) and (not Self.FSvcThread.Finished)) then begin
        Self.FSvcThread.Suspended := False;
    end;
end;

procedure TBioFilesService.tmrCycleEventTimer(Sender : TObject);
begin
    // Realiza a checkagem dos logs a cada mudança de hora
    Self.CheckLogs;
    Self.ServiceThreadPulse();
end;

initialization

    begin
        InitServiceLog();
    end;

end.
