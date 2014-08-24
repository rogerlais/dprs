{$IFDEF fuMainDataModule}
          {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

unit fuMainDataModule;

interface

uses
    SysUtils, Classes, JvComponentBase, JvSearchFiles, Forms, fuUserSwitcher, AppLog, IdBaseComponent,
    IdComponent, IdTCPConnection,
    IdTCPClient, IdHTTP;

type
    TDMMainController = class(TDataModule)
        FileSearcher : TJvSearchFiles;
        httpNotifier : TIdHTTP;
        procedure FileSearcherFindFile(Sender : TObject; const AName : string);
        procedure DataModuleCreate(Sender : TObject);
        procedure DataModuleDestroy(Sender : TObject);
    private
        { Private declarations }
        //FTmpList :       TStrings;
        FSRHUpdated :         boolean;
        FAcessoUpdated :      boolean;
        FHEUpdated :          boolean;
        FAtualizadorUpdated : boolean;
        FNetToken :           THandle;
        FOldLogger :          TLogFile;
        FAutoMode :           boolean;
        procedure UpdateAcesso(const DestName : string);
        procedure UpdateSRH(const DestName : string);
        procedure UpdateHE(const DestName : string);
        procedure UpdateAtualizador(const DestName : string);
        procedure FixMissingFiles();
        procedure InitLog;
        function GetIsPatchApplied : boolean;
        procedure SetIsPatchApplied(const Value : boolean);
        function GetIsPatchAppliedRegVersion : boolean;
        procedure CheckUserCredentials(const Username : string);
        procedure SetIsPatchAppliedRegVersion(const Value : boolean);
        procedure RunUpdates();
        procedure DebugLog(const log : string);
        function GetSourceFilePath : string;
        function MirrorCopy(const SrcPath, DestPath, Filename : string) : boolean;
        procedure FinalizeLog();
        function GetNetworkUserToken(const UserName, Pwd : string) : Integer;
        function GetLogFilename : string;
        function GetSignatureFilename : string;
        procedure HTTPLogRegister(const VarText : string);
    public
        { Public declarations }
        property IsPatchApplied : boolean read GetIsPatchApplied write SetIsPatchApplied;
        property SourceFilePath : string read GetSourceFilePath;
        property LogFilename : string read GetLogFilename;
        property SignatureFilename : string read GetSignatureFilename;
        procedure CheckUpdate(List : TStrings);
        constructor Create(AOwner : TComponent); override;
    end;

var
    DMMainController : TDMMainController;

implementation

uses
    FileHnd, Windows, ShlObj, ActiveX, ComObj, ShellFilesHnd, WinReg32, fuMainForm, WinNetHnd,
    WinHnd, StrHnd, IOUtils, fuCustomLog, ShellAPI, HTTPApp
    {JediWinAPI, Jwawindows};

const
    IE_GPO_FULLY_APPLIED_DATE = 'HKEY_LOCAL_MACHINE\SOFTWARE\SESOP\Patches\AppliedDates\SRH_ACESSO';
    //RE_LOG_APP   = 'HKEY_CURRENT_USER\SESOP\Log\SRH_ACESSO';
    //LOG_ROOT_DIR = 'C:\Temp';
    SOURCE_FILES_ROOT_DIR = '\\macgyver.tre-pb.gov.br\ftp_sesop\FileUpdate\Files';
    LOG_ROOT_DIR = '\\macgyver.tre-pb.gov.br\ftp_sesop\FileUpdate\Logs';
    ACESSO_PATH  = 'D:\AplicTRE\AcessoCliente';
    SRH_PATH     = 'D:\AplicTRE\SGRH';
    HE_PATH      = 'D:\AplicTRE\HE';
    URL_PREFIX   = 'http://desenv:8085/gpo/log?';

{$R *.dfm}

procedure TDMMainController.FixMissingFiles;
///Caso não se encontre os arquivos nos caminhos padroes deve-se instalar nestes locais
var
    CpOK :   boolean;
    SrcDir : string;
begin
    {$IFDEF HORAS_EXTRAS }
    Exit;
     {$ENDIF}
    CpOK   := True;
    SrcDir := Self.GetSourceFilePath();
    //Copiar para a pasta padrão os modulos do Acesso
    if not (Self.FAcessoUpdated and Self.FAtualizadorUpdated) then begin
        ForceDirectories(ACESSO_PATH);
        CpOK := CpOK and Self.MirrorCopy(SrcDir, ACESSO_PATH, 'AcessoCli.exe');
        CpOK := CpOK and Self.MirrorCopy(SrcDir, ACESSO_PATH, 'AcessoCli.ini');
        CpOK := CpOK and Self.MirrorCopy(SrcDir, ACESSO_PATH, 'Atualizador.ini');
        CpOK := CpOK and Self.MirrorCopy(SrcDir, ACESSO_PATH, 'Atualizador.exe');
        if (not CpOK) then begin
            raise Exception.Create('Falha na reposição dos arquivos obrigatórios');
        end;
    end;

    //Copiar o SRH.exe  para a sua padrão
    if (not Self.FSRHUpdated) then begin
        ForceDirectories(SRH_PATH);
        if (not Self.MirrorCopy(SrcDir, SRH_PATH, 'SRH.exe')) then begin
            TLogFile.Log('Falha copiando arquivos do SRH para caminho padrão');
        end else begin
            TLogFile.Log('SRH atualizado COM SUCESSO');
        end;
    end;
end;

procedure TDMMainController.RunUpdates();
var
	 LnkPath : string;
begin
    {$IFNDEF DEBUG}//dispensa C:\ na depuração
    TLogFile.LogDebug('Buscando na unidade C:\', DBGLEVEL_NONE);
    Self.FileSearcher.RootDirectory := 'C:\';
    Self.FileSearcher.Search;
    {$ENDIF}

    TLogFile.LogDebug('Buscando na unidade D:\', DBGLEVEL_NONE);
    Self.FileSearcher.RootDirectory := 'D:\';
    Self.FileSearcher.Search;

    Self.FixMissingFiles; //Para o caso de se forçar o caminho de alguns aplicativos(não se aplica para HE.exe)

    {$IFNDEF HORAS_EXTRAS }
    LnkPath := ShellFilesHnd.TShellHnd.GetAllUsersDesktop();
    TShellHnd.CreateShellShortCut('D:\AplicTRE\SGRH\SRH.exe', TFileHnd.ConcatPath([LnkPath, 'SRH.lnk']), '');
    TShellHnd.CreateShellShortCut('D:\AplicTRE\AcessoCliente\Atualizador.exe',
        TFileHnd.ConcatPath([LnkPath, 'AcessoCliente.lnk']), 'D:\AplicTRE\AcessoCliente\AcessoCli.exe', 0);
     {$ENDIF}
end;

procedure TDMMainController.CheckUpdate(List : TStrings);
///Método de interface para a execução da atualiação
begin
    try
        try
            try
                if (not Self.IsPatchApplied) then begin
                    TLogFile.Log('Iniciando a aplicação da atualização SRH+Acesso+HE', lmtInformation);
                    try
                        Self.RunUpdates();
                        TLogFile.LogDebug('Finalizada aplicação da atualização SRH+Acesso+HE', DBGLEVEL_NONE);
                        Self.IsPatchApplied := True;
                    except
                        on E : Exception do begin
                            TLogFile.LogDebug('Falha na aplicação da GPO:'#13 + E.Message, DBGLEVEL_NONE);
                        end;
                    end;
                end;
            except
                on E : Exception do begin
                    TLogFile.Log(E.Message);
                end;
            end;
        finally
            if (Assigned(List)) then begin //repassa log da operação
                List.Text := TLogFile.GetDefaultLogFile.BufferText;
            end;
        end;
    except
        on E : Exception do begin
            MessageBoxW(0, PChar(E.Message), PWideChar(Error), MB_OK + MB_ICONSTOP + MB_TOPMOST);
            raise E;
        end;
    end;
end;

procedure TDMMainController.CheckUserCredentials(const Username : string);
var
    un : string;
begin
    un := GetUserName();
    if (not TStrHnd.startsWith(UpperCase(UserName), UpperCase(un))) then begin
        if (Self.FAutoMode) then begin
            raise Exception.CreateFmt('Credencial encontrada "%s" diverge da requerida "%s" para esta operação', [un, Username]);
        end;
    end;
end;

constructor TDMMainController.Create(AOwner : TComponent);
begin
    inherited;
    Self.InitLog();

    {Não usar esa porcaria no momento}
    //GlobalConfig.ReadOperations;

    //Ajusta os parametros do pesquisador
    Self.FileSearcher.RootDirectory := 'd:\';
    Self.FileSearcher.Options    := [soAllowDuplicates, soCheckRootDirValid, soSearchDirs, soSearchFiles,
        soIncludeSystemHiddenFiles];
    Self.FileSearcher.FileParams.SearchTypes := [stFileMask];
     {$IFDEF HORAS_EXTRAS}
    Self.FileSearcher.FileParams.FileMasks.Text := 'HE.exe'#13;
     {$ELSE}
    Self.FileSearcher.FileParams.FileMasks.Text := 'AcessoCli.exe'#13 + 'Atualizador.exe'#13 + 'SRH.exe'#13;
     {$ENDIF}
    Self.FileSearcher.OnFindFile := FileSearcherFindFile;
end;

procedure TDMMainController.DataModuleCreate(Sender : TObject);
const
    DEBUG_TOKEN = '/DBGLVL';
var
    x :   Integer;
    vl :  string;
    dbg : Integer;
begin

    //Ajusta o nivel de depuração do aplicativo
    for x := 1 to ParamCount do begin
        if (TStrHnd.startsWith(UpperCase(ParamStr(x)), DEBUG_TOKEN)) then begin
            vl := Copy(ParamStr(x), Length(DEBUG_TOKEN) + 2, 30);
            try
                TryStrToInt(vl, dbg);
            except
                dbg := 0;
            end;
            TLogFile.GetDefaultLogFile.DebugLevel := dbg;
        end;
    end;

    //Carrega a lista de operações a ser feita


    //Identifica se trabalho sera no modo automatico
    for x := 1 to ParamCount do begin
        if (UpperCase(ParamStr(x)) = '/AUTO') then begin
            Self.FAutoMode := True;
            Self.CheckUpdate(nil {Self.FTmpList });
            Exit;    //Impede a criação da janela abaixo
        end;
    end;

    //Caso a flag /auto seja passa linhas abaixo não executadas
    Application.CreateForm(TFUMainWindow, FUMainWindow);
end;

procedure TDMMainController.DataModuleDestroy(Sender : TObject);
begin
    Self.FinalizeLog();
end;

procedure TDMMainController.DebugLog(const log : string);
begin
    AppLog.TLogFile.LogDebug(log, DBGLEVEL_ULTIMATE);
end;

procedure TDMMainController.FileSearcherFindFile(Sender : TObject; const AName : string);
 ///Evento de localização de arquivo que obedece as regras de atualização
 /// Identifica o arquivo e aplica sua atualização/deleção
var
    UpName : string;
begin
    TLogFile.LogDebug('Encontrado arquivo com a máscara correspondente: ' + AName, DBGLEVEL_NONE);
    UpName := UpperCase(ExtractFileName(AName));
    //Abaixo a lista passada de arquivos procurados

     {$IFNDEF HORAS_EXTRAS}
    if (UpName = 'ACESSOCLI.EXE') then begin
        Self.UpdateAcesso(AName);
    end else begin
        if (UpName = 'ATUALIZADOR.EXE') then begin
            Self.UpdateAtualizador(AName);
        end else begin
            if (UpName = 'SRH.EXE') then begin
                Self.UpdateSRH(AName);
            end;
        end;
    end;
     {$ENDIF}

    //Lista de arquivos atualmente procurados
    if (UpName = 'HE.EXE') then begin
        Self.UpdateHE(AName);
    end;
    TLogFile.Log('Encontrei em: ' + AName, lmtInformation); //Sempre registra
    //Self.FTmpList.Add();
end;

procedure TDMMainController.FinalizeLog;
var
    CustomLog : TLogFile;
begin
    TLogFile.Log('Aplicativo finalizado normalmente', lmtInformation);
    CustomLog := TLogFile.GetDefaultLogFile();
    Self.HTTPLogRegister(CustomLog.BufferText);
    CustomLog.Buffered := False;
    TLogFile.GetDefaultLogFile.SetDefaultLogFile(Self.FOldLogger);
    CustomLog.Free; //astalavista baby
end;

procedure TDMMainController.UpdateAcesso(const DestName : string);
//Atualizar acesso cliente
begin
    if not SameText(TFileHnd.ParentDir(DestName), ACESSO_PATH) then begin
        DeleteFile(PChar(DestName));
    end else begin
        Self.FAcessoUpdated := Self.MirrorCopy(Self.SourceFilePath, ACESSO_PATH, 'AcessoCli.exe');
    end;
end;

procedure TDMMainController.UpdateAtualizador(const DestName : string);
//Atualizar atualizador
var
    admPath : string;
begin
    admPath := TFileHnd.ChangeFileName(DestName, 'Acessoadm.exe');
    if ((not FileExists(admPath)) and (not (SameText(TFileHnd.ParentDir(DestName), ACESSO_PATH)))) then begin
        DeleteFile(PChar(DestName));
    end else begin
        Self.FAtualizadorUpdated := (not FileExists(admPath)) and Self.MirrorCopy(Self.SourceFilePath,
            ACESSO_PATH, 'Atualizador.exe');
        //Flag de atualizador atualizado
    end;
end;

procedure TDMMainController.UpdateHE(const DestName : string);
begin
    DeleteFile(PChar(DestName));
    TLogFile.Log(Format('Atualizando "%s" por "%s"', [DestName, Self.SourceFilePath]), lmtInformation);
    Self.FHEUpdated := Self.MirrorCopy(Self.SourceFilePath, HE_PATH, 'HE.exe');
end;

procedure TDMMainController.UpdateSRH(const DestName : string);
//Atualizar SRH
begin
    if not (SameText(TFileHnd.ParentDir(DestName), SRH_PATH)) then begin
        DeleteFile(PChar(DestName));
    end else begin
        Self.FSRHUpdated := Self.MirrorCopy(Self.SourceFilePath, SRH_PATH, 'SRH.exe');
    end;
end;

procedure TDMMainController.InitLog;
var
    Log : TFULog;
begin
    try
        ForceDirectories(LOG_ROOT_DIR);
        Log := TFULog.Create(Self.LogFilename, False);
        Log.FreeOnRelease := False;
        Self.FOldLogger := TLogFile.GetDefaultLogFile();
        Self.FOldLogger.FreeOnRelease := False;
        TLogFile.SetDefaultLogFile(Log);
        Log.Buffered := True; //Ajusta como bufferizado
          {$IFDEF DEBUG}
        TLogFile.GetDefaultLogFile.DebugLevel := DBGLEVEL_ULTIMATE;
          {$ENDIF}
    finally
        GlobalSwitcher.RevertToPrevious();
    end;
end;

function TDMMainController.MirrorCopy(const SrcPath, DestPath, Filename : string) : boolean;
var
    SrcFile, DestFile : string;
begin
    SrcFile  := TFileHnd.ConcatPath([SrcPath, Filename]);
    DestFile := TFileHnd.ConcatPath([DestPath, Filename]);
    if (FileExists(DestFile)) then begin
        DeleteFile(PChar(DestFile));
    end;
    GlobalSwitcher.SwitchTo(APP_NET_USER);
    try
        Result := FileHnd.FileCopy(SrcFile, DestFile, True) = ERROR_SUCCESS;
    finally
        GlobalSwitcher.RevertToPrevious();
    end;
end;

function TDMMainController.GetIsPatchApplied : boolean;
var
    RuntimeDate, AppliedDate : TDateTime;
begin
    Result := Self.GetIsPatchAppliedRegVersion();
    if (not Result) then begin
        GlobalSwitcher.SwitchTo(APP_NET_USER);
        try
            RuntimeDate := TFileHnd.FileTimeChangeTime(ParamStr(0));
            if (FileExists(Self.SignatureFilename)) then begin
                AppliedDate := TFileHnd.FileTimeChangeTime(Self.SignatureFilename);
                Result      := (RuntimeDate < AppliedDate);
            end else begin
                Result := False;
            end;
        finally
            GlobalSwitcher.RevertToPrevious();
        end;
        if (not Result) then begin
            Self.DebugLog('Detectada a necessidade de atualização');
        end;
    end;
end;


procedure TDMMainController.SetIsPatchApplied(const Value : boolean);
begin
    Self.SetIsPatchAppliedRegVersion(Value);
    if (Value) then begin
        GlobalSwitcher.SwitchTo(APP_NET_USER);
        try
            TFileHnd.ForceFilename(Self.SignatureFilename);
        finally
            GlobalSwitcher.RevertToPrevious();
        end;
    end else begin
        GlobalSwitcher.SwitchTo(APP_NET_USER);
        try
            DeleteFile(PChar(Self.SignatureFilename));
        finally
            GlobalSwitcher.RevertToPrevious();
        end;
    end;
end;

function TDMMainController.GetIsPatchAppliedRegVersion : boolean;
var
    reg : TRegistryNT;
    RegDate, RunTimeDate : TDateTime;
    suc : boolean;
begin
    Result := False;

    Self.CheckUserCredentials(APP_SYS_USER);

    reg := TRegistryNT.Create();
    try
        try
            suc := reg.ReadFullDateTime(IE_GPO_FULLY_APPLIED_DATE, RegDate);
        except
            suc := False;
        end;
        if (suc) then begin
            TLogFile.LogDebug('Carregando runtime em ' + ParamStr(0), DBGLEVEL_ULTIMATE);
            RunTimeDate := TFileHnd.FileTimeChangeTime(ParamStr(0));
            TLogFile.LogDebug('Usando data de referência de atualização: ' + DateTimeToStr(RunTimeDate), DBGLEVEL_ULTIMATE);
            Result := (RegDate >= RunTimeDate);
        end else begin
            Result := False;
        end;
    finally
        reg.Free;
        if (not Result) then begin
            TLogFile.LogDebug('Atualização requerida!!!!', DBGLEVEL_NONE);
        end;
    end;
end;

function TDMMainController.GetLogFilename : string;
begin
    Result := TFileHnd.ConcatPath([LOG_ROOT_DIR, WinNetHnd.GetComputerName() + '_LOG.log']);
end;

function TDMMainController.GetSignatureFilename : string;
begin
    Result := TFileHnd.ConcatPath([LOG_ROOT_DIR, GetComputerName() + '_OK.sig']);
end;

function TDMMainController.GetSourceFilePath : string;
begin
    //Result := TFileHnd.SlashRem(ExtractFilePath(ParamStr(0)));
       {$MESSAGE WARN 'alerta de camino hc' }
    Result := SOURCE_FILES_ROOT_DIR;
end;

procedure TDMMainController.HTTPLogRegister(const VarText : string);
var
    url : string;
    ms :  TStringStream;
begin
    {TODO -oroger -cdsg : Montar a URL com o texto passado e o nome do computador }
	 url := URL_PREFIX + 'v1=' + WinNetHnd.GetComputerName + '&v2=' + HTTPApp.HTTPEncode(VarText);
	 ms  := TStringStream.Create;
    try
		 Self.httpNotifier.Get(url, ms);
        ms.Position := 0;
        url := ms.DataString;
        if (url[1] <> '0') then begin
            raise Exception.CreateFmt('Registro de log em HTTP falhou - código: %s ', [url]);
        end;
    finally
        ms.Free;
    end;
end;

procedure TDMMainController.SetIsPatchAppliedRegVersion(const Value : boolean);
var
    reg : TRegistryNT;
begin
    //Esta chamada nunca pode ser feita por conta da rede
    Self.CheckUserCredentials(APP_SYS_USER);
    try
        reg := TRegistryNT.Create();
        try
            if (Value) then begin
                reg.WriteFullDateTime(IE_GPO_FULLY_APPLIED_DATE, Now(), True);
            end else begin
                reg.WriteFullDateTime(IE_GPO_FULLY_APPLIED_DATE, 0, True);
            end;
        finally
            reg.Free;
        end;
    except
        on E : Exception do begin
            MessageBoxW(0, PWideChar(E.Message + #13 + SysErrorMessage(GetLastError())), 'Registro de erro',
                MB_OK + MB_ICONSTOP + MB_TOPMOST);
        end;
    end;
end;

function TDMMainController.GetNetworkUserToken(const UserName, Pwd : string) : Integer;
    //----------------------------------------------------------------------------------------------------------------------------------
var
    User, Pass : PChar;
begin
    User   := PChar(UserName);
    Pass   := PChar(Pwd);
    Result := ERROR_SUCCESS;
    SetLastError(Result);
    if not LogonUser(User, nil, Pass, LOGON32_LOGON_INTERACTIVE, LOGON32_PROVIDER_DEFAULT, Self.FNetToken) then begin
        Result := GetLastError();
    end;
end;

end.
