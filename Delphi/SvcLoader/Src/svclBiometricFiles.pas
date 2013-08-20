{$IFDEF svclBiometricFiles}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclBiometricFiles;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs, svclTransBio, ExtCtrls, IdMessage, IdBaseComponent,
    IdComponent, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase,
    IdSMTP, FileInfo, XPThreads;

type
    TBioFilesService = class(TService)
        tmrCycleEvent : TTimer;
        smtpSender :    TIdSMTP;
        mailMsgNotify : TIdMessage;
        fvInfo :        TFileVersionInfo;
        procedure ServiceStart(Sender : TService; var Started : boolean);
        procedure ServiceCreate(Sender : TObject);
        procedure ServiceAfterInstall(Sender : TService);
		 procedure ServiceStop(Sender : TService; var Stopped : boolean);
		 procedure tmrCycleEventTimer(Sender : TObject);
		 procedure ServiceBeforeInstall(Sender : TService);
        procedure ServicePause(Sender : TService; var Paused : boolean);
        procedure ServiceContinue(Sender : TService; var Continued : boolean);
    private
        { Private declarations }
        FSvcThread : TXPNamedThread;
        procedure AddDestinations;
        procedure CheckLogs();
    public
        function GetServiceController : TServiceController; override;
        procedure TimeCycleEvent();
        procedure SendMailNotification(const NotificationText : string);
        { Public declarations }
    end;

var
    BioFilesService : TBioFilesService;

implementation

uses
    AppLog, WinReg32, FileHnd, svclConfig, svclUtils, WinnetHnd, APIHnd, svclEditConfigForm, Str_Pas,
    IdEMailAddress, XPFileEnumerator, StrHnd;

{$R *.DFM}

const
    SUBJECT_TEMPLATE = 'BioFilesService - Versão: %s - %s - %s';

procedure ServiceController(CtrlCode : DWord); stdcall;
begin
    BioFilesService.Controller(CtrlCode);
end;

procedure InitServiceLog();
///Altera o nome do log a ser gerado para esta iniciação do serviço de modo a ser unico por dia de levantameto
var
    LogFileName : string;
begin
    LogFileName := TFileHnd.ConcatPath([GlobalConfig.PathServiceLog, APP_SERVICE_NAME + '_'
        + FormatDateTime('YYYYMMDD', Now())]) + '.log';
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
 ///<summary>
 ///Buscar por logs posteriores a data de registro, enviando todos aqueles que possuirem erros.
/// A cada envio com sucesso avancar a data de registro para a data do respectivo arquivo de log e buscar pelo mais antigo até chegar ao log atual
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
var
    Files :  IEnumerable<TFileSystemEntry>;
    f :      TFileSystemEntry;
    currLogName, sentPath : string;
    logText : TXPStringList;
    dummy :  Integer;
    sentOK : boolean;
begin
    {TODO -oroger -cdsg : verificar se a data corrente diverge da data do arquivo}
    currLogName := AppLog.TLogFile.GetDefaultLogFile.FileName;
    Files := TDirectory.FileSystemEntries(GlobalConfig.PathServiceLog, '*.log', False);
    for f in Files do begin
        if (not Sametext(f.FullName, currLogName)) then begin //Pula o arquivo em uso no momento como saida de log
            logText := TXPStringList.Create;
            try
                logText.LoadFromFile(f.FullName);
                dummy  := 1; //Sempre do inicio
                sentOk := not logText.FindPos('erro:', dummy, dummy);
                if (not sentOK) then begin
                    try
                        Self.SendMailNotification(logText.Text);
                        sentOK := True;
                    except
                        on E : Exception do begin  //Apenas logar a falha de envio e continuar com os demais arquivos
                            TLogFile.Log('Envio de notificações de erro falhou:'#13#10 + E.Message, lmtError);
                            sentOK := False;
                        end;
                    end;
                end;
                //mover arquivo para a pasta de enviados applog
                if (sentOK) then begin
                    sentPath := GlobalConfig.PathServiceLog + '\Sent\';
                    ForceDirectories(sentPath);
                    sentPath := sentPath + F.Name;
                    if (not MoveFile(PWideChar(F.FullName), PWideChar((sentPath)))) then begin
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

function TBioFilesService.GetServiceController : TServiceController;
begin
    Result := ServiceController;
end;

procedure TBioFilesService.SendMailNotification(const NotificationText : string);
begin
    mailMsgNotify.AttachmentEncoding := 'UUE';
    mailMsgNotify.Encoding      := meDefault;
    mailMsgNotify.ConvertPreamble := True;
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

    //Coletar informações de destino de mensagem com possibilidade de macros no mesmo arquivo de configuração
    Self.AddDestinations();

    Self.mailMsgNotify.Subject   := Format(SUBJECT_TEMPLATE, [Self.fvInfo.FileVersion, WinNetHnd.GetComputerName(),
        FormatDateTime('yyyyMMDDhhmm', Now())]);
    Self.mailMsgNotify.Body.Text := NotificationText;
    Self.smtpSender.Connect;
    Self.smtpSender.Send(Self.mailMsgNotify);
    Self.smtpSender.Disconnect(True);
end;

procedure TBioFilesService.ServiceAfterInstall(Sender : TService);
 /// <summary>
 ///  Registra as informações de função deste serviço
 /// </summary>
var
    Reg : TRegistryNT;
begin
    Reg := TRegistryNT.Create();
    try
        Reg.WriteFullString(
            TFileHnd.ConcatPath(['HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services', Self.Name, 'Description']),
            'Replica os arquivos de dados biométricos para máquina primária, possibilitando o transporte centralizado.', True);
    finally
        Reg.Free;
    end;
end;

procedure TBioFilesService.ServiceBeforeInstall(Sender : TService);
 ///  <summary>
 ///    Ajusta os parametros do serviço antes de sua instalação. Dentre as ações está levantar o serviço como o último da lista de
 /// serviços
 ///  </summary>
 ///  <remarks>
 ///
 ///  </remarks>
var
    reg : TRegistryNT;
    lst : TStringList;
begin

    TEditConfigForm.EditConfig; //Chama janela de configuração para exibição

    reg := TRegistryNT.Create;
    lst := TStringList.Create;
    try
        reg.ReadFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', Lst);
        if ((lst.IndexOf(APP_SERVICE_GROUP) < 0)) then begin
            lst.Add(APP_SERVICE_GROUP);
            TLogFile.Log('Alterando ordem de inicializaçao dos serviços no registro local', lmtInformation);
            if (not IsDebuggerPresent()) then begin
                reg.WriteFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', Lst, True);
            end;
        end;
    finally
        reg.Free;
        lst.Free;
    end;
    TLogFile.Log('Ordem de carga do serviço alterada com SUCESSO no computador local', lmtInformation);
end;

procedure TBioFilesService.ServiceContinue(Sender : TService; var Continued : boolean);
 ///<summary>
 ///Reincio do servico
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
begin
    Self.tmrCycleEvent.Enabled := True; //Liberar disparo de liberação de thread de serviço
    if Assigned(Self.FSvcThread) and (Self.FSvcThread.Suspended) then begin
        if Self.FSvcThread.Suspended then begin
            Self.FSvcThread.Resume;
        end;
        Continued := (Self.FSvcThread.Suspended = False);
    end else begin
        Continued := False;
    end;
end;

procedure TBioFilesService.ServiceCreate(Sender : TObject);
begin
    Self.DisplayName := APP_SERVICE_DISPLAYNAME;
    Self.LoadGroup   := APP_SERVICE_GROUP;
    if (GlobalConfig.RunAsServer) then begin
        Self.FSvcThread := TTransBioServerThread.Create(True);
    end else begin
        Self.FSvcThread := TTransBioThread.Create(True);  //Criar thread de operação primário
    end;
    Self.FSvcThread.Name := APP_SERVICE_DISPLAYNAME;  //Nome de exibição do thread primário
end;

procedure TBioFilesService.ServicePause(Sender : TService; var Paused : boolean);
 ///<summary>
 ///     Pause do servico
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
begin
    Self.tmrCycleEvent.Enabled := False; //Suspende timer de liberação do thread do serviço
    if Assigned(Self.FSvcThread) and (not Self.FSvcThread.Suspended) then begin
        Self.FSvcThread.Suspend;
        Paused := (Self.FSvcThread.Suspended = True);
    end else begin
        Paused := False;
    end;
end;

procedure TBioFilesService.ServiceStart(Sender : TService; var Started : boolean);
begin
    {TODO -oroger -cfuture : rever modo de iniciar e parar serviço, preferencialmente desaolcando tudo}
    Self.CheckLogs();
    //Rotina de inicio do servico, cria o thread da operação e o inicia
    Self.tmrCycleEvent.Interval := GlobalConfig.CycleInterval;
    Self.tmrCycleEvent.Enabled  := True;
    Self.FSvcThread.Start;
    Sleep(300);
    Self.FSvcThread.Suspended := False;
    Started := True;
end;

procedure TBioFilesService.ServiceStop(Sender : TService; var Stopped : boolean);
begin
	 Self.FSvcThread.Suspended := True;
	 Self.tmrCycleEvent.Interval := GlobalConfig.CycleInterval;
	 Self.tmrCycleEvent.Enabled  := False; //Para a reativação do thread de serviço
    {TODO -oroger -cfuture : Caso alterado o ciclo de vida do serviço, local para desalocar o thread de trabalho}
    Stopped := True;
end;

procedure TBioFilesService.TimeCycleEvent;
begin
    Self.FSvcThread.Suspended := False;
end;

procedure TBioFilesService.tmrCycleEventTimer(Sender : TObject);
begin
    Self.CheckLogs;
    Self.TimeCycleEvent();
end;

initialization
    begin
        InitServiceLog();
    end;

end.
