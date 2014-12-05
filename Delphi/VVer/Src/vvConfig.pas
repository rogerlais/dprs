{$IFDEF vvConfig}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
{$TYPEINFO OFF} //tentativa de não serializar classes desta unit

unit vvConfig;

interface

uses
	Classes, SysUtils, Windows, FileHnd, AppSettings, Contnrs, AppLog, WinReg32, vvsConsts, vvProgItem,
	IdBaseComponent, IdComponent,
	IdTCPConnection, IdTCPClient, IdHTTP;

const
	STR_DEFAULT_VALUE       = '<default>';
	STR_DEFAULT_NET_INSTSEG = STR_DEFAULT_VALUE;
	VERSION_INFO_FILENAME   = 'VVER.ini';

type
	EVVException        = class(ELoggedException);
	EVVMonitorException = class(EVVException);

	TVVProfileInfo = class(TBaseStartSettings)
	private
		FProgList: TObjectList;
		function GetPrograms(index: Integer): TProgItem;
		function GetCount: Integer;
	public
		constructor Create(const Filename: string; const AKeyPrefix: string = ''); override;
		destructor Destroy; override;
		property Programs[index: Integer]: TProgItem read GetPrograms;
		property Count: Integer read GetCount;
	end;

	TVVStartupConfig = class(TBaseStartSettings)
	private
		FHTTPLoader : TIdHTTP;
		FProfileName: string;
		FStartTime  : TDateTime;
		function GetGlobalStatus: string;
		function GetClientName: string;
		function GetInfoText: string;
		function GetAutoMode: boolean;
		function GetNotificationList: string;
		function GetSenderAddress: string;
		function GetSenderDescription: string;
		function GetEnsureNotification: boolean;
		procedure InitDownloader();
		function GetCycleInterval: Integer;
		function GetIsUpdated: TVVUpdateStatus;
		function GetPathLocalRepository: string;
		function GetIsPrimaryPC: boolean;
		function GetPrimaryPC: string;
		function GetRootBaseConfigFilename: string;
		function GetRemoteRepositoryPath: string;
		function GetLocalUNC: string;
		function GetRegisterServer: string;
		function GetNetClientPort: Integer;
		function GetPathServiceLog: string;
		function GetDebugLevel: Integer;
		function GetPublicationInstSegPath: string;
		function GetPublicationParentServer: string;
		function GetPublicationRootServer: string;
		function GetBlockSize: Integer;
		function GetPathClientInfo: string;
		function GetPathLocalTempDir: string;
		function GetInstanceName: string;
		function GetSenderSMTP: string;
	protected
		_ProfileInfo: TVVProfileInfo;
		function GetProfileInfo: TVVProfileInfo; virtual;
	public
		constructor Create(const Filename: string; const AKeyPrefix: string = ''); override;
		destructor Destroy; override;
		function ToString(): string; override;
		function LoadHTTPContent(const URL, DestFilename: string): boolean;
		class function GetBlockHash(AStrm: TMemoryStream; ALength: Integer): string;
		property GlobalStatus: string read GetGlobalStatus;
		property BlockSize: Integer read GetBlockSize;
		property InfoText: string read GetInfoText;
		property ProfileInfo: TVVProfileInfo read GetProfileInfo;
		property AutoMode: boolean read GetAutoMode;
		property ProfileName: string read FProfileName;
		property NotificationList: string read GetNotificationList;
		property SenderAddress: string read GetSenderAddress;
		property SenderDescription: string read GetSenderDescription;
		property SenderSMTP: string read GetSenderSMTP;
		property EnsureNotification: boolean read GetEnsureNotification;
		property ClientName: string read GetClientName;
		property CycleInterval: Integer read GetCycleInterval;
		property PathClientInfo: string read GetPathClientInfo;
		property PathLocalTempDir: string read GetPathLocalTempDir;
		property UpdateStatus: TVVUpdateStatus read GetIsUpdated;
		property PathLocalRepository: string read GetPathLocalRepository;
		property IsPrimaryPC: boolean read GetIsPrimaryPC;
		property PrimaryPC: string read GetPrimaryPC;
		property RootBaseConfigFilename: string read GetRootBaseConfigFilename;
		property RemoteRepositoryPath: string read GetRemoteRepositoryPath;
		property LocalUNC: string read GetLocalUNC;
		property RegisterServer: string read GetRegisterServer;
		property NetClientPort: Integer read GetNetClientPort;
		property PathServiceLog: string read GetPathServiceLog;
		property DebugLevel: Integer read GetDebugLevel;
		property PathPublicationInstSeg: string read GetPublicationInstSegPath;
		property PublicationParentServer: string read GetPublicationParentServer;
		property PublicationRootServer: string read GetPublicationRootServer;
		property InstanceName: string read GetInstanceName;
	end;

var
	GlobalInfo: TVVStartupConfig = nil;

implementation

uses
	WinNetHnd, StrHnd, vvMainDataModule, FileInfo, TREConsts, JclSysInfo, TREUtils, StreamHnd;

const
	IE_DEBUG_CLIENT_NAME = 'Debug\ClientName'; //nome forçado para depuração deste cliente

	IE_NOTIFICATION_LIST = 'NotificationList';
	DV_NOTIFICATION_LIST = 'sesop.l@tre-pb.jus.br';

	IE_SENDER_SMTP = 'SMTPSender';
	DV_SENDER_SMTP = 'smtp.tre-pb.jus.br';

	IE_CYCLE_INTERVAL = 'CycleInterval';
	DV_CYCLE_INTERVAL = 60000;

	IE_BLOCK_SIZE = 'BlockSize';
	DV_BLOCK_SIZE = 4096;

	IE_CLIENT_INFO_PATH = 'ClientInfoPath';
	DV_CLIENT_INFO_PATH = '.\ClientInfo';

	IE_LOCAL_REPOSITORY = 'InstSegPath';
	DV_LOCAL_REPOSITORY = 'D:\Comum\InstSeg';

	IE_LOCAL_TEMPDIR = 'LocalTempDir';
	DV_LOCAL_TEMPDIR = '.\Temp';

	IE_REMOTE_REPOSITORY = 'NetInstSeg';
	DV_REMOTE_REPOSITORY = STR_DEFAULT_NET_INSTSEG;

	IE_VERSION_SERVER = 'VersionServer';
	DV_VERSION_SERVER = 'vver.tre-pb.gov.br';

	IE_NET_TCP_PORT = 'TCPPort';
	DV_NET_TCP_PORT = 12014;

	IE_DEBUG_LEVEL = 'Debug\DebugLevel';
	{$IFDEF DEBUG}
	DV_DEBUG_LEVEL = 10;
	{$ELSE}
	DV_DEBUG_LEVEL = 0;
	{$ENDIF}
	IE_PUBLICATION_PATH_INSTSEG = 'InstSegPubPath';
	DV_PUBLICATION_PATH_INSTSEG = 'D:\Comum\Instseg';
	IE_PUB_PARENT_SERVER        = 'DSync\ParentServer';
	DV_PUB_PARENT_SERVER        = STR_DEFAULT_VALUE;
	IE_PUB_ROOT_SERVER          = 'DSync\RootServer';
	DV_PUB_ROOT_SERVER          = DV_VERSION_SERVER;

	{ TVVInfo }

constructor TVVStartupConfig.Create(const Filename, AKeyPrefix: string);
///
///Cria e carrega o perfil deste computador de acordo com o nome do mesmo.
///Monta o nome prefixando o sistema operacional com o tipo da estação
var
	ct: TTREComputerType;
begin
	{ TODO -oroger -cdsg : Pegar o nome do perfil atraves do AD do controlador de domínio, exceto para os casos onde não houve o mesmo }
	{ TODO -oroger -cdsg : Opção para o caso acima é contato com o servidor configurado para o serviço }
	inherited;
	Self.FStartTime := Now();

	Self.InitDownloader();


	//impede salvamento de valores padrao
	{$IFDEF DEBUG}
	Self.AutoCreate := True;
	{$ELSE}
	Self.AutoCreate := False;
	{$ENDIF}
	//Identifica o perfil baseado no ordinal do nome do computador. Para id > 10 -> PCT, cc máquina zona
	ct := TTREUtils.GetComputerTypeByName(Self.ClientName);
	case ct of
		ctUnknow, ctCentralPDC, ctZonePDC, ctTREWKS: begin
				Self.FProfileName := 'Outros';
			end;
		ctCentralWKS, ctZoneWKS, ctZoneSTD: begin
				Self.FProfileName := 'ZE';
			end;
		ctNATT: begin
				Self.FProfileName := 'NATT';
			end;
		ctNATU: begin
				Self.FProfileName := 'NATU';
			end;
		ctDFE: begin
				Self.FProfileName := 'DFE';
			end;
		ctVirtual: begin
				Self.FProfileName := 'VM';
			end;
	end;
	if (GetWindowsVersion() = wvWin7) then begin
		Self.FProfileName := 'W7.' + Self.FProfileName;
	end else begin
		if (GetWindowsVersion() = wvWinXP) then begin
			Self.FProfileName := 'XP.' + Self.FProfileName;
		end else begin
			//Resolver para caso de SO não identificado
			Self.FProfileName := 'Outros.' + Self.FProfileName;
		end;
	end;
end;

destructor TVVStartupConfig.Destroy;
var
	tmpDir: string;
begin
	//Testa se arquivo foi gerado em temporario
	Self.FHTTPLoader.Free;
	tmpDir := FileHnd.GetTempDir;
	if TStrHnd.startsWith(Self.FIni.Filename, tmpDir) then begin
		DeleteFile(PWideChar(Self.FIni.Filename));
	end;
	inherited;
end;

function TVVStartupConfig.GetPathClientInfo: string;
begin
	Result := Self.ReadStringDefault(IE_CLIENT_INFO_PATH, DV_CLIENT_INFO_PATH);
	Result := ExpandFileName(Result);
	if (not ForceDirectories(Result)) then begin
		Result := GetCurrentDir();
	end;
end;

function TVVStartupConfig.GetClientName: string;
begin
	Result := Self.ReadString(IE_DEBUG_CLIENT_NAME);
	if (Result = EmptyStr) then begin
		{$WARN SYMBOL_PLATFORM OFF}
		if (System.DebugHook <> 0) then begin
			Result := DBG_CLIENT_NAME;
		end else begin
			Result := WinNetHnd.GetComputerName();
		end;
		{$WARN SYMBOL_PLATFORM ON}
	end;
end;

function TVVStartupConfig.GetCycleInterval: Integer;
begin
	Result := ReadIntegerDefault(IE_CYCLE_INTERVAL, DV_CYCLE_INTERVAL);
end;

function TVVStartupConfig.GetDebugLevel: Integer;
begin
	Result := Self.ReadIntegerDefault(IE_DEBUG_LEVEL, DV_DEBUG_LEVEL);
end;

function TVVStartupConfig.GetAutoMode: boolean;
var
	x: Integer;
begin
	//Identifica o modo de operação
	Result := False;
	for x  := 0 to ParamCount do begin
		if SameText(ParamStr(x), '/auto') then begin
			Result := True;
			Exit;
		end;
	end;
end;

class function TVVStartupConfig.GetBlockHash(AStrm: TMemoryStream; ALength: Integer): string;
//calcula o hash do bloco
var
	pbesta                : array of byte;
	compl                 : Integer;
	oldPos, oldSize, delta: int64;
begin
	oldPos  := AStrm.Position;
	oldSize := AStrm.Size;
	try
		//Ajusta tamanho
		delta := AStrm.Size mod ALength;
		if (delta <> 0) then begin //necessita de alinhamento
			AStrm.Size := AStrm.Size + (ALength - delta);
		end;
		//Preenche complemento
		compl := AStrm.Size - oldPos;
		if ((compl > 0) and (AStrm.Position > 0)) then begin
			SetLength(pbesta, compl + 1);
			{$WARN UNSAFE_CODE OFF}
			AStrm.Write(PByte(pbesta)^, compl);
			{$WARN UNSAFE_CODE ON}
		end;
		//calcula o hash
		Result := THashHnd.MD5(AStrm);
	finally
		AStrm.Size     := oldSize;
		AStrm.Position := oldPos;
	end;
end;

function TVVStartupConfig.GetBlockSize: Integer;
begin
	Result := Self.ReadIntegerDefault(IE_BLOCK_SIZE, DV_BLOCK_SIZE);
end;

function TVVStartupConfig.GetEnsureNotification: boolean;
var
	enDefault: TDefaultSettingValue;
begin
	enDefault := TDefaultSettingValue.Create();
	try
		enDefault.AsBoolean := False;
		Result              := Self.ReadBoolean('EnsureNotification', enDefault);
	finally
		enDefault.Free;
	end;
end;

function TVVStartupConfig.GetGlobalStatus: string;
var
	x: Integer;
begin
	if (Assigned(Self.ProfileInfo)) then begin
		Result := 'OK';
		for x  := 0 to Self.ProfileInfo.Count - 1 do begin
			if not Self._ProfileInfo.Programs[x].isUpdated then begin
				Result := 'Pendente';
				Exit;
			end;
		end;
	end else begin
		Result := 'Erro!';
	end;
end;

function TVVStartupConfig.GetInfoText: string;
var
	x: Integer;
	p: TProgItem;
begin
	if (Assigned(Self.ProfileInfo)) then begin
		Result     := 'Resumo da verficação das versões'#13#10;
		Result     := Result + 'Computador: ' + WinNetHnd.GetComputerName();
		for x      := 0 to Self.ProfileInfo.Count - 1 do begin
			Result := Result + #13#10;
			p      := Self._ProfileInfo.Programs[x];
			Result := Result + 'Sistema: ' + p.Desc + #13#10;
			Result := Result + 'Versão instalada: ' + p.CurrentVersion + #13#10;
			Result := Result + 'Versão esperada: ' + p.ExpectedVerEx + #13#10;
			if p.isUpdated then begin
				Result := Result + 'Situação: Atualizado'#13#10;
			end else begin
				Result := Result + 'Situação: Pendente'#13#10;
			end;
		end;
	end else begin
		Result := 'Sem perfil identificado para este computador';
	end;
end;

function TVVStartupConfig.GetInstanceName: string;
begin
	Result := Self.ClientName + '-' + FormatDateTime('yyyymmddhhmmss', Self.FStartTime);
end;

function TVVStartupConfig.GetIsPrimaryPC: boolean;
begin
	Result := SameText(Self.ClientName, Self.PrimaryPC);
end;

function TVVStartupConfig.GetIsUpdated: TVVUpdateStatus;
//Varre configurações para indicar atualizações
var
	prof: TVVProfileInfo;
	p   : TProgItem;
	I   : Integer;
begin
	prof := Self.ProfileInfo;
	if (Assigned(prof)) then begin
		Result := usOK;
		try
			for I := 0 to prof.Count - 1 do begin
				p := prof.Programs[I];
				case p.UpdateStatus of
					usUnknow: begin
							Result := usUnknow;
						end;
					usOld: begin
							Result := usOld;
							Exit;
						end;
				end;
			end;
		except
			on E: Exception do
				Result := usUnknow;
		end;
	end else begin
		Result := usUnknow;
	end;
end;

function TVVStartupConfig.GetPathLocalRepository: string;
//local para armazenamento local dos arquivos
begin
	Result := Self.ReadStringDefault(IE_LOCAL_REPOSITORY, DV_LOCAL_REPOSITORY);
end;

function TVVStartupConfig.GetPathLocalTempDir: string;
begin
	Result := Self.ReadStringDefault(IE_LOCAL_TEMPDIR, DV_LOCAL_TEMPDIR);
	Result := ExpandFileName(Result);
	if (not ForceDirectories(Result)) then begin
		raise EVVException.CreateFmt('Caminho para conteúdo temporário (%s) não pode ser acessado.', [Result]);
	end;
end;

function TVVStartupConfig.GetLocalUNC: string;
begin
	{$WARN SYMBOL_PLATFORM OFF}
	if (System.DebugHook <> 0) then begin
		Result := '\\' + WinNetHnd.GetComputerName() + '\Documentos\suporte\publico\espelho';
	end else begin
		Result := '\\' + Self.PrimaryPC + '\Documentos\suporte\publico\espelho';
	end;
	{$WARN SYMBOL_PLATFORM ON}
end;

function TVVStartupConfig.GetNetClientPort: Integer;
begin
	Result := Self.ReadIntegerDefault(IE_NET_TCP_PORT, DV_NET_TCP_PORT);
end;

function TVVStartupConfig.GetNotificationList: string;
begin
	Result := Self.ReadStringDefault(IE_NOTIFICATION_LIST, DV_NOTIFICATION_LIST);
end;

function TVVStartupConfig.GetPathServiceLog: string;
begin
	Result := TFileHnd.ConcatPath([TFileHnd.ParentDir(ParamStr(0)), 'Logs']);
end;

function TVVStartupConfig.GetPrimaryPC: string;
begin
	Result := TTREUtils.GetZonePrimaryComputer(Self.ClientName);
end;

function TVVStartupConfig.GetProfileInfo: TVVProfileInfo;
var
	profileURL, profileFilename: string;
begin
	if (not Assigned(Self._ProfileInfo)) then begin
		//Tenta com o SO explicito
		profileURL := Self.ReadString('Profiles\' + Self.ProfileName + '\VerInfo');
		if (profileURL <> EmptyStr) then begin
			profileFilename := TStrHnd.CopyAfterLast('/', profileURL);
			profileFilename := TFileHnd.ConcatPath([Self.PathLocalRepository, profileFilename]);

			TLogFile.LogDebug('Baixando perfil remoto em ' + profileURL, DBGLEVEL_DETAILED);
			if (not Self.LoadHTTPContent(profileURL, profileFilename)) then begin
				if (not FileExists(profileFilename)) then begin
					raise EVVMonitorException.CreateFmt('Arquivo para o perfil %s não pode ser obtido e salvo em %s',
						[Self.ProfileName, profileFilename]);
				end;
			end;
			//Buscar a entrada correta para a URL do perfil
			Self._ProfileInfo := TVVProfileInfo.Create(profileFilename);
		end;
	end;
	Result := Self._ProfileInfo;
end;

function TVVStartupConfig.GetPublicationInstSegPath: string;
//Caminho da publicação InstSeg(a unica ao momento)
begin
	Result := Self.ReadStringDefault(IE_PUBLICATION_PATH_INSTSEG, DV_PUBLICATION_PATH_INSTSEG);
end;

function TVVStartupConfig.GetPublicationParentServer: string;
begin
	Result := Self.ReadStringDefault(IE_PUB_PARENT_SERVER, DV_PUB_PARENT_SERVER);
	if (SameText(Result, STR_DEFAULT_VALUE)) then begin
		if (Self.IsPrimaryPC) then begin
			Result := Self.RegisterServer;
		end else begin
			Result := TTREUtils.GetZonePrimaryComputer(Self.ClientName); { TODO -oroger -cdsg : Validar retorno }
		end;
	end;
end;

function TVVStartupConfig.GetPublicationRootServer: string;
begin
	Result := Self.ReadStringDefault(IE_PUB_ROOT_SERVER, DV_PUB_ROOT_SERVER);
end;

function TVVStartupConfig.GetRegisterServer: string;
begin
	Result := Self.ReadStringDefault(IE_VERSION_SERVER, DV_VERSION_SERVER);
end;

function TVVStartupConfig.GetRemoteRepositoryPath: string;
//local para baixar todos os arquivos
begin
	Result := Self.ReadStringDefault(IE_REMOTE_REPOSITORY, DV_REMOTE_REPOSITORY);
	if (SameText(Result, DV_REMOTE_REPOSITORY)) then begin
		Result := Self.LocalUNC;
	end;
end;

function TVVStartupConfig.GetRootBaseConfigFilename: string;
begin
	Result := VERSION_URL_FILE;
end;

function TVVStartupConfig.GetSenderAddress: string;
begin
	{ TODO -oroger -cfuture : manifestas a criar }
	Result := Self.ReadStringDefault(IE_NOTIFICATION_LIST , DV_NOTIFICATION_LIST);
end;

function TVVStartupConfig.GetSenderDescription: string;
begin
	{ TODO -oroger -cfuture : manifestas a criar }
	Result := Self.ReadStringDefault('SenderDescription', 'SESOP - Seção de Suporte Operacional');
end;

function TVVStartupConfig.GetSenderSMTP: string;
begin
	Result := Self.ReadStringDefault(IE_SENDER_SMTP, DV_SENDER_SMTP);
end;

procedure TVVStartupConfig.InitDownloader;
begin
	Self.FHTTPLoader                                 := TIdHTTP.Create(nil);
	Self.FHTTPLoader.AllowCookies                    := True;
	Self.FHTTPLoader.ProxyParams.BasicAuthentication := False;
	Self.FHTTPLoader.ProxyParams.ProxyPort           := 0;
	Self.FHTTPLoader.Request.ContentLength           := -1;
	Self.FHTTPLoader.Request.Accept                  := 'text/html, */*';
	Self.FHTTPLoader.Request.BasicAuthentication     := False;
	Self.FHTTPLoader.Request.UserAgent               := 'Mozilla/3.0 (compatible; Indy Library)';
	Self.FHTTPLoader.HTTPOptions                     := [hoForceEncodeParams];
end;

function TVVStartupConfig.LoadHTTPContent(const URL, DestFilename: string): boolean;
var
	MemStream : TMemoryStream;
	FileStream: TFileStream;
begin
	Result := True;
	try
		MemStream := TMemoryStream.Create;
		try
			Self.FHTTPLoader.Get(URL, MemStream);
			//Verifica a escrita para atualizar informações de versões
			MemStream.Position := 0;
			if not TFileHnd.IsWritable(DestFilename) then begin
				ForceDirectories(TFileHnd.ParentDir(DestFilename));
				if (not TFileHnd.IsWritable(DestFilename)) then begin
					raise EVVMonitorException.CreateFmt('Falha salvando arquivo de configuração atualizado em %s', [DestFilename]);
				end;
			end;
			if FileExists(DestFilename) then begin
				FileStream := TFileStream.Create(DestFilename, fmOpenWrite);
			end else begin
				FileStream := TFileStream.Create(DestFilename, fmCreate);
			end;
			try
				MemStream.SaveToStream(FileStream);
				FileStream.Size := FileStream.Position; //trunca o excesso
			finally
				FileStream.Free;
			end;
		finally
			MemStream.Free;
		end;
	except
		on E: Exception do begin
			Result := False;
			TLogFile.Log(Format('Recurso localizado em %s não pode ser carregado para %s'#13#10'%s', [URL, DestFilename, E.Message]
				), lmtError);
		end;
	end;
end;

function TVVStartupConfig.ToString: string;
var
	Lines: TStringList;
begin
	Lines := TStringList.Create;
	try
		Lines.LoadFromFile(Self.FIni.Filename);
		Result := Lines.Text;
	finally
		Lines.Free;
	end;
end;

{ TVVProgInfo }

constructor TVVProfileInfo.Create(const Filename, AKeyPrefix: string);
var
	progs                           : TStringList;
	x                               : Integer;
	Desc, Hive, VerKey, VerKeyEx    : string;
	ExpectedVer, ExpectedVerEx, DURL: string;
	prg                             : TProgItem;
begin
	inherited;
	Self.FProgList             := TObjectList.Create;
	Self.FProgList.OwnsObjects := True;
	progs                      := TStringList.Create;
	try
		Self.FIni.ReadSections(progs);
		for x := 0 to progs.Count - 1 do begin
			//Descrição e nome da seção(não pode começar com "@" )
			Desc := progs.Strings[x];
			//nome da chave para acesso aos atributos
			Hive := Self.FIni.ReadString(Desc, 'hive', '');
			//Entrada da versão simples
			VerKey := Self.FIni.ReadString(Desc, 'Entry1', '');
			//Entrada da versão detalhada
			VerKeyEx := Self.FIni.ReadString(Desc, 'Entry2', '');
			//Entrada do valor esperado para a versão simples
			ExpectedVer := Self.FIni.ReadString(Desc, 'Expected1', '');
			//Entrada do valor esperado para a versão detalhada
			ExpectedVerEx := Self.FIni.ReadString(Desc, 'Expected2', '');
			//Caminho do download para atualizar/instalar
			DURL := Self.FIni.ReadString(Desc, 'URL', '');
			prg  := TProgItem.Create(Desc, Hive, VerKey, VerKeyEx, ExpectedVer, ExpectedVerEx, DURL);
			Self.FProgList.Add(prg);
		end;
	finally
		progs.Free;
	end;
end;

function TVVProfileInfo.GetPrograms(index: Integer): TProgItem;
begin
	Result := TProgItem(Self.FProgList.Items[index]);
end;

destructor TVVProfileInfo.Destroy;
var
	tmpDir: string;
begin
	//Testa se arquivo foi gerado em temporario
	tmpDir := FileHnd.GetTempDir;
	if TStrHnd.startsWith(Self.FIni.Filename, tmpDir) then begin
		DeleteFile(PWideChar(Self.FIni.Filename));
	end;
	inherited;
end;

function TVVProfileInfo.GetCount: Integer;
begin
	Result := Self.FProgList.Count;
end;

end.
