unit vvsmMainDatamodule;

interface

uses
    SysUtils, Classes, FileInfo, ExtCtrls, ImgList, Controls, Menus, Forms, vvsFileMgmt, IdBaseComponent, IdComponent,
    IdTCPConnection, IdTCPClient, vvConfig, IdHTTP, vvProgItem;

const
    STR_DEFAULT_NET_INSTSEG = '<default>';
    VERSION_INFO_FILENAME   = 'VVER.ini';


type
    TVVSMMainDM = class(TDataModule)
        fvVersion :       TFileVersionInfo;
        TrayIcon :        TTrayIcon;
        tmrTrigger :      TTimer;
        ilIcons :         TImageList;
        pmMenuTray :      TPopupMenu;
        Mostrar1 :        TMenuItem;
        Atualizar1 :      TMenuItem;
        Sair1 :           TMenuItem;
        tcpclntRegister : TIdTCPClient;
        procedure TrayIconMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);
        procedure DataModuleCreate(Sender : TObject);
        procedure tmrTriggerTimer(Sender : TObject);
        procedure Mostrar1Click(Sender : TObject);
        procedure Atualizar1Click(Sender : TObject);
        procedure Sair1Click(Sender : TObject);
        procedure tcpclntDisconnected(Sender : TObject);
        procedure tcpclntConnected(Sender : TObject);
    private
        { Private declarations }
        FStartTime :   TDateTime;
        FLasOKSended : TDateTime;
        FLastStatus :  TVVUpdateStatus;
        function GlobalStatusStr() : string;
        procedure InitStartupConfig;
        procedure LoadGlobalInfo(const Filename : string);
        procedure EndSession();
        procedure StartSession();
        procedure StartClient();
        procedure RegisterStatusServer(CurrentStatus : TVVUpdateStatus);
        procedure PostRequest(Args : array of string);
        procedure InitSettings();
        procedure StopClient();
        function ReadResponse() : string;
        procedure PostStatus(CurrentStatus : TVVUpdateStatus);
        //function LoadURL(const url, DestFilename : string) : string;
    public
        { Public declarations }
        procedure ShowNotification(StatusOK : TVVUpdateStatus);
        procedure UpdateFiles();
    end;

var
    VVSMMainDM : TVVSMMainDM;

implementation

{$R *.dfm}


uses
    FileHnd, StrHnd, IdContext, IdCustomTCPServer,
    IdTCPServer,
    IdEMailAddress, WinNetHnd, AppLog, vvMainForm, Str_Pas, TREUtils, XPFileEnumerator,
    vvsConsts, IdGlobal, Rtti, TypInfo;

const
    ICON_UPDATED     = 0;
    ICON_NOT_UPDATED = 1;
    ICON_UNKNOW      = 2;


procedure TVVSMMainDM.Atualizar1Click(Sender : TObject);
begin
    Self.tmrTriggerTimer(Self);
end;

procedure TVVSMMainDM.DataModuleCreate(Sender : TObject);
begin
    Self.FStartTime := Now();

    //carrega as informações de versão
    try
        Self.InitStartupConfig();
    except
        on E : Exception do begin
            AppLog.AppFatalError('Erro carregando configurações base: '#13#10 + E.Message, 2, True );
        end;
    end;
    //Inicia componentes internos
    Self.tmrTrigger.Enabled  := True;
	 Self.tmrTrigger.Interval := GlobalInfo.CycleInterval;
    Self.tmrTrigger.OnTimer  := Self.tmrTriggerTimer;

    Application.ShowMainForm := False;
end;

procedure TVVSMMainDM.EndSession;
var
    idx : Integer;
begin
    //Envia a finalização de sessão para o servidor
    Self.tcpclntRegister.IOHandler.WriteLn(STR_END_SESSION_SIGNATURE + GlobalInfo.ClientName); //Envia msg de fim de sessão
end;

function TVVSMMainDM.GlobalStatusStr : string;
begin
    {TODO -oroger -cdsg : retorna cadeia com o status das aplicações}
    if (GlobalInfo.UpdateStatus = usOK) then begin
        Result := 'Atualizados';
    end else begin
        Result := 'DESATUALIZADOS PARA SEU PERFIL';
    end;
end;

procedure TVVSMMainDM.InitStartupConfig;
{{
Rotina de inicialização para a carga dos parametros iniciais e perfil associado
}
var
    baseCfgURL, remoteConfFile, localConfFile, sURLContent : string;
    sl : TStringList;
begin
	TLogFile.LogDebug( 'Iniciando configurações do aplicativo', DBGLEVEL_ULTIMATE );
	 localConfFile := TFileHnd.ConcatPath([GlobalInfo.LocalRepositoryPath, VERSION_INFO_FILENAME]); //caminho local
	 //Sempre ser carregado por este caminho
	 //tenta atualizar arquivo de configuração base
	 if (GlobalInfo.IsPrimaryPC) then begin
		 baseCfgURL  := GlobalInfo.RootBaseConfigFilename; //arquivo base
		 {TODO -oroger -cdsg : baixar versão atual do arquivo de configuração antes de usar a local }
		 if ( not GlobalInfo.LoadHTTPContent( baseCfgURL, localConfFile ) ) then begin
			if ( not FileExists( localConfFile ) ) then begin
				raise Exception.CreateFmt('Arquivo (%s) de configuração inicial não pode ser carregado', [ localConfFile ]);
			end;
		 end;
	 end else begin  //tenta atualizar a partir do pc primario
		 remoteConfFile := TFileHnd.ConcatPath([GlobalInfo.RemoteRepositoryPath, VERSION_INFO_FILENAME]);
        //Sempre ser carregado por este caminho
        ForceDirectories(GlobalInfo.LocalRepositoryPath);
        FileCopy(remoteConfFile, localConfFile, True);
    end;
    if (not FileExists(localConfFile)) then begin
        raise Exception.Create('Arquivo de configuração base não encontrado');
	 end;
	 GlobalInfo.InitInfoVersions( localConfFile ); // VersionConfig := TVVConfig.Create(filename, 'VVer'); //carrega o arquivo de versões atualizado/valido
end;

procedure TVVSMMainDM.InitSettings;
begin
    SysUtils.DecimalSeparator  := '.';
    SysUtils.ThousandSeparator := ' ';
end;

procedure TVVSMMainDM.LoadGlobalInfo(const Filename : string);
 ///Monta rotina de carga das configurações iniciais, na ordem:
 /// 1 - Arquivo local de onde serão carregados os dados remotos
 ///
 /// Máquina primária no caminho do repositório
begin
    {TODO -oroger -cdsg : Carga dinamica do arquivo de configurações do serviço}
end;

procedure TVVSMMainDM.Mostrar1Click(Sender : TObject);
begin
    Application.MainForm.Show;
end;

procedure TVVSMMainDM.PostRequest(Args : array of string);
var
    req, s : string;
begin
    req := EmptyStr;
    for s in Args do begin
        req := req + s + TOKEN_DELIMITER;
    end;
    try
        TLogFile.LogDebug(STR_CMD_VERB + req, DBGLEVEL_ULTIMATE);
        Self.tcpclntRegister.IOHandler.Write(STR_CMD_VERB + req); //write -> cadeia possui fim de linha
    except
        on E : Exception do begin
            raise Exception.Create('Erro enviando solicitação ao servidor: ' + E.Message);
        end;
    end;
end;

procedure TVVSMMainDM.PostStatus(CurrentStatus : TVVUpdateStatus);
var
    p :    TProgItem;
    Data : string;
    I :    Integer;
begin
    //Calcula valor a postar
    Data := EmptyStr;
	 for I := 0 to GlobalInfo.ProfileInfo.Count - 1 do begin
		 p := GlobalInfo.ProfileInfo.Programs[I];
        if (not p.isUpdated) then begin
            Data := Data + p.Desc + '[' +
                GetEnumName(TypeInfo(TVVUpdateStatus), Integer(p.UpdateStatus)) + ']' + TOKEN_DELIMITER;
        end;
    end;

    //Postar o resgistro do status
    Self.PostRequest([Verb2String(vvvRegisterStatus), HTTPEncode(Data)]);
    Data := Self.ReadResponse();
    if (SameText(Data, STR_OK_PACK)) then begin
        Self.FLasOKSended := Now();
        Self.FLastStatus  := CurrentStatus;
    end;

end;

function TVVSMMainDM.ReadResponse : string;
var
    ret : string;
begin
    try
        Result := HTTPDecode(Self.tcpclntRegister.IOHandler.ReadLn(TEncoding.UTF8)); //leitura da resposta em si
    except
        on E : Exception do begin
            raise Exception.Create('Erro lendo resposta do servidor.' + E.Message);
        end;
    end;
    try //Leitura da checagem da resposta
        ret := Self.tcpclntRegister.IOHandler.ReadLn(); //codigo de retorno
        if (ret <> STR_OK_PACK) then begin
            raise Exception.CreateFmt('Operação falhou(%s):'#13#10'%s', [ret, Result]);
        end;
    except
        on E : Exception do begin {TODO -oroger -cdsg : verificar e garantir o envio recebimento nesta codificação}
            raise Exception.Create('Resposta de leitura de conteúdo não foi completa ou falha.'#13#10 + E.Message);
        end;
    end;
end;

procedure TVVSMMainDM.RegisterStatusServer(CurrentStatus : TVVUpdateStatus);
begin
    if ((Self.FLasOKSended <> 0) and (Self.FLastStatus = CurrentStatus)) then begin
        Exit;
    end;
    try
        Self.StartClient();
        try
            Self.StartSession();
            try
                Self.PostStatus(CurrentStatus);
            finally
                Self.EndSession;
            end;
        finally
            Self.StopClient();
        end;
    except
        on E : Exception do begin
            TLogFile.Log('Erro durante registro de status no servidor: ' + E.Message, lmtError);
        end;
    end;
end;

procedure TVVSMMainDM.Sair1Click(Sender : TObject);
begin
    Application.Terminate;
end;

procedure TVVSMMainDM.ShowNotification(StatusOK : TVVUpdateStatus);
begin
    Self.TrayIcon.Visible := True;
    case StatusOK of
        usUnknow : begin
            Self.TrayIcon.IconIndex := ICON_UPDATED;
        end;
        usOld : begin
            Self.TrayIcon.IconIndex := ICON_UNKNOW;
        end;
        usOK : begin
            Self.TrayIcon.IconIndex := ICON_UPDATED;
        end;
    end;
end;

procedure TVVSMMainDM.StartClient;
begin
    Self.InitSettings();

	 Self.tcpclntRegister.Host      := GlobalInfo.RegisterServer;
	 Self.tcpclntRegister.Port      := GlobalInfo.NetClientPort;
	 Self.tcpclntRegister.OnDisconnected := tcpclntDisconnected;
	 Self.tcpclntRegister.OnConnected := tcpclntConnected;
	 Self.tcpclntRegister.ConnectTimeout := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
	 Self.tcpclntRegister.IPVersion := Id_IPv4;
	 Self.tcpclntRegister.ReadTimeout := 0;  //usa o valor dado por  IdTimeoutDefault
	 //Self.TrayIcon.IconIndex := II_CLIENT_IDLE;
    TLogFile.LogDebug(Format('Falando na porta:(%d) - Servidor:(%s)', [GlobalInfo.NetClientPort, GlobalInfo.RegisterServer]),
        DBGLEVEL_DETAILED);
end;

procedure TVVSMMainDM.StartSession;
var
    SessionName, ret, msg : string;
begin
    try
		 SessionName := GlobalInfo.ClientName;
        //Envia a abertura de sessão para o servidor
        Self.tcpclntRegister.Connect;
        //passa valores obrigatorios para inicio de sessão
        Self.tcpclntRegister.IOHandler.WriteLn(STR_BEGIN_SESSION_SIGNATURE + SessionName); //cabecalho da sessão
        Self.tcpclntRegister.IOHandler.WriteLn(Self.fvVersion.FileVersion); //versão do cliente
        Self.tcpclntRegister.IOHandler.WriteLn(GlobalInfo.ClientName); //Nome do computador cliente
        Self.tcpclntRegister.IOHandler.WriteLn(STR_BEGIN_SESSION_SIGNATURE + SessionName); //repete cabecalho da sessão
        ret := Self.tcpclntRegister.IOHandler.ReadLn();
        if (not SameText(ret, STR_OK_PACK)) then begin
            try
                msg := Self.tcpclntRegister.IOHandler.ReadLn();
            except
                on E : Exception do begin
                    msg := '"' + msg + '"'#13#10 + E.Message;
                end;
            end;
            raise Exception.Create('Sessão não pode ser iniciada: ' + msg);
        end;
    except
        on E : Exception do begin //colocar como registro de depuração, por se tratar de erro comum
            TLogFile.LogDebug(Format
                ('Falha de comunicação com o servidor pai desta instância(%s) na porta(%d).'#13#10,
                [Self.tcpclntRegister.Host, Self.tcpclntRegister.Port]) +
                E.Message, DBGLEVEL_ALERT_ONLY);
            raise;
        end;
    end;
end;

procedure TVVSMMainDM.StopClient;
 ///<summary>
 ///Atividade opcional, pois o processamento por sessão é rápido
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
begin
    if (Self.tcpclntRegister.Connected()) then begin
        Self.tcpclntRegister.Disconnect;
    end;
end;

procedure TVVSMMainDM.tcpclntConnected(Sender : TObject);
begin
    TLogFile.LogDebug('Conectado ao servidor', DBGLEVEL_DETAILED);
end;

procedure TVVSMMainDM.tcpclntDisconnected(Sender : TObject);
begin
    TLogFile.LogDebug('Desconectado do servidor', DBGLEVEL_DETAILED);
end;

procedure TVVSMMainDM.tmrTriggerTimer(Sender : TObject);
var
    bUpd : TVVUpdateStatus;
begin
    {TODO -oroger -cdsg : verifica se a carencia foi ultrapassada}

    {TODO -oroger -cdsg : repete o ciclo de comparações}
    bUpd := GlobalInfo.UpdateStatus;
    VVSMMainDM.ShowNotification(bUpd); //atualiza icone de status
    Self.RegisterStatusServer(usOld);
end;

procedure TVVSMMainDM.TrayIconMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);
var
    rtVersion : string;
    hint :      string;
begin
    rtVersion := 'Versão: ' + Self.fvVersion.FileVersion;
    hint      := 'SESOP - VVER Monitor' + #13#10 + rtVersion + #13#10;
    //if (Assigned(VVMConfig.VersionConfig)) then begin
    hint      := Hint + 'Perfil = ' + GlobalInfo.ProfileName + #13#10;
    //end else begin
    //     hint := Hint + 'Perfil = ' + 'Indeterminado' + #13#10;
    //end;
    hint      := Hint + 'Status dos sistemas = ' + Self.GlobalStatusStr;
    Self.TrayIcon.Hint := Hint;
end;

procedure TVVSMMainDM.UpdateFiles;
var
{
     IFiles :  IEnumerable<TFileSystemEntry>;
     f :      TFileSystemEntry;
     rootDest, rootSource : string;
}
    dest, src : TManagedFolder;
    list : TVVSFileList;
    f : TVVsFile;
    newName : string;
begin
	 dest := TManagedFolder.CreateLocal(GlobalInfo.LocalRepositoryPath);
    src  := TManagedFolder.CreateLocal(GlobalInfo.RemoteRepositoryPath);
    list := TVVSFileList.Create;
    try
        dest.Diff(src, list);
        for f in list do begin
            if (f.Parent = dest) then begin
                f.Delete;
            end else begin
                newName := TFileHnd.ConcatPath([dest.RootDir, Copy(f.Filename, 2, Length(f.Filename))]);
                FileCopy(f.FullFilename, newName, True);
            end;
        end;
    finally
        list.Free;
    end;
end;

end.
