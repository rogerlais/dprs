{$IFDEF fuMainDataModule}
         {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

unit fuMainDataModule;

interface

uses
    SysUtils, Classes, JvComponentBase, JvSearchFiles, AppSettings, Forms, fuUserSwitcher;

type
    TDMMainController = class(TDataModule)
        FileSearcher : TJvSearchFiles;
        procedure FileSearcherFindFile(Sender : TObject; const AName : string);
        procedure DataModuleCreate(Sender : TObject);
    private
        { Private declarations }
        FTmpList :       TStrings;
        FSRHUpdated :    boolean;
        FAcessoUpdated : boolean;
        FAtualizadorUpdated : boolean;
        FNetToken :      THandle;
        FSwitcher :      TFUUserSwitcher;
        procedure UpdateAcesso(const DestName : string);
        procedure UpdateSRH(const DestName : string);
        procedure UpdateAtualizador(const DestName : string);
        procedure FixMissingFiles();
        procedure SaveLink(const TargetName, LinkFileName, IconFilename : WideString; IconIndex : Integer = 0);
        procedure InitLog;
        function GetIsPatchApplied : boolean;
        procedure SetIsPatchApplied(const Value : boolean);
        function GetIsPatchAppliedRegVersion : boolean;
        procedure SetIsPatchAppliedRegVersion(const Value : boolean);
        procedure RunUpdates(List : TStrings);
        procedure DebugLog(const log : string);
        function GetSourceFilePath : string;
        function MirrorCopy(const SrcPath, DestPath, Filename : string) : boolean;
        function GetNetworkUserToken(const UserName, Pwd : string) : Integer;
        function GetLogFilename : string;
        function GetSignatureFilename : string;
    public
        { Public declarations }
        property IsPatchApplied : boolean read GetIsPatchApplied write SetIsPatchApplied;
        property SourceFilePath : string read GetSourceFilePath;
        property LogFilename : string read GetLogFilename;
        property SignatureFilename : string read GetSignatureFilename;
        procedure CheckUpdate(List : TStrings);
        constructor Create(AOwner : TComponent); override;
        destructor Destroy; override;
    end;

var
    DMMainController : TDMMainController;

implementation

uses
    FileHnd, Windows, ShlObj, ActiveX, ComObj, ShellFilesHnd, AppLog, WinReg32, fuMainForm, WinNetHnd,
    WinHnd, StrHnd, IOUtils, fuCustomLog, ShellAPI, fuConfiguration
    {JediWinAPI, Jwawindows};

const
    IE_GPO_FULLY_APPLIED_DATE = 'HKEY_LOCAL_MACHINE\SOFTWARE\SESOP\Patches\AppliedDates\SRH_ACESSO';
    //RE_LOG_APP   = 'HKEY_CURRENT_USER\SESOP\Log\SRH_ACESSO';
    //LOG_ROOT_DIR = 'C:\Temp';
    SOURCE_FILES_ROOT_DIR = '\\macgyver.tre-pb.gov.br\ftp_sesop\FileUpdate\Files';
    LOG_ROOT_DIR = '\\macgyver.tre-pb.gov.br\ftp_sesop\FileUpdate\Logs';
    ACESSO_PATH  = 'D:\AplicTRE\AcessoCliente';
    SRH_PATH     = 'D:\AplicTRE\SGRH';

{$R *.dfm}

procedure TDMMainController.FixMissingFiles;
///Caso não se encontre os arquivos nos caminhos padroes deve-se instalar nestes locais
var
    CpOK :   boolean;
    SrcDir : string;
begin
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

procedure TDMMainController.RunUpdates(List : TStrings);
var
    LnkPath : string;
begin
    GlobalConfig.ReadOperations;
    Self.FTmpList.BeginUpdate;
	 try

		 {$IFNDEF DEBUG} //dispensa C:\ na depuração
		 TLogFile.LogDebug('Buscando na unidade C:\', DBGLEVEL_NONE);
		 Self.FileSearcher.RootDirectory := 'C:\';
		 Self.FileSearcher.Search;
		 {$ENDIF}
		 TLogFile.LogDebug('Buscando na unidade D:\', DBGLEVEL_NONE);
		 Self.FileSearcher.RootDirectory := 'D:\';
		 Self.FileSearcher.Search;
		 Self.FixMissingFiles;

        LnkPath := ShellFilesHnd.TShellHnd.GetAllUsersDesktop();
        Self.SaveLink('D:\AplicTRE\SGRH\SRH.exe', TFileHnd.ConcatPath([LnkPath, 'SRH.lnk']), '');
        Self.SaveLink('D:\AplicTRE\AcessoCliente\Atualizador.exe',
            TFileHnd.ConcatPath([LnkPath, 'AcessoCliente.lnk']), 'D:\AplicTRE\AcessoCliente\AcessoCli.exe', 0);

    finally
        Self.FTmpList.EndUpdate;
        if (Assigned(List)) then begin
            List.Assign(Self.FTmpList);
        end;
    end;
end;

procedure TDMMainController.SaveLink(const TargetName, LinkFileName, IconFilename : WideString; IconIndex : Integer = 0);
var
    IObject : IUnknown;
    ISLink :  IShellLink;
    IPFile :  IPersistFile;
begin

    //Apaga link anterior com o mesmo nome
    DeleteFile(PWChar(LinkFileName));

    IObject := CreateComObject(CLSID_ShellLink);
    ISLink  := IObject as IShellLink;
    IPFile  := IObject as IPersistFile;

    ISLink.SetPath(PChar(TargetName));
    ISLink.SetWorkingDirectory(PChar(ExtractFilePath(TargetName)));
    if (IconFilename = EmptyStr) then begin
        ISLink.SetIconLocation(PWideChar(TargetName), IconIndex);
    end else begin
        ISLink.SetIconLocation(PWideChar(IconFilename), IconIndex);
    end;
    IPFile.Save(PWChar(LinkFileName), False);
end;

procedure TDMMainController.CheckUpdate(List : TStrings);
begin
    if (not Self.IsPatchApplied) then begin
        TLogFile.LogDebug('Iniciando a aplicação da atualização SRH+Acesso', DBGLEVEL_NONE);
        Self.RunUpdates(List);
        TLogFile.LogDebug('Finalizada aplicação da atualização SRH+Acesso', DBGLEVEL_NONE);
        Self.IsPatchApplied := True;
    end;
end;

constructor TDMMainController.Create(AOwner : TComponent);
begin
    inherited;
    Self.FTmpList  := TStringList.Create;
    Self.FSwitcher := TFUUserSwitcher.Create('SYSTEM');
    Self.InitLog();
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
            Self.CheckUpdate(Self.FTmpList);
            Exit;
        end;
    end;

    //Caso a flag /auto seja passa linhas abaixo não executadas
    Application.CreateForm(TFUMainWindow, FUMainWindow);
end;

procedure TDMMainController.DebugLog(const log : string);
begin
    AppLog.TLogFile.LogDebug(log, DBGLEVEL_ULTIMATE);
end;

destructor TDMMainController.Destroy;
begin
    Self.FTmpList.Free;
    TLogFile.Log('Aplicativo finalizado normalmente');
    inherited;
end;

procedure TDMMainController.FileSearcherFindFile(Sender : TObject; const AName : string);
 ///Evento de localização de arquivo que obedece as regras de atualização
 /// Identifica o arquivo e aplica sua atualização/deleção
var
    UpName : string;
begin
    TLogFile.LogDebug('Encontrado arquivo com a máscara correspondente: ' + AName, DBGLEVEL_NONE);
    UpName := UpperCase(ExtractFileName(AName));
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
    Self.FTmpList.Add('Encontrei em: ' + AName);
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

    Self.FSwitcher.AddUserCrendentials(APP_NET_USER, APP_NET_PWD);
    (*
    if (GetNetworkUserToken('download@tre-pb.gov.br', 'pinico123') <> 0) then begin
         raise Exception.Create('Logon alternativo download@tre-pb.gov.br falhou para a atualização de sistemas(Acess, SRH).');
     end;
     Self.GetNetAcess();

     *)
    Self.FSwitcher.SwitchTo(APP_NET_USER);
    try
        ForceDirectories(LOG_ROOT_DIR);
        Log := TFULog.Create(Self.LogFilename, False, Self.FSwitcher);
        TLogFile.SetDefaultLogFile(Log);
          {$IFDEF DEBUG}
        TLogFile.GetDefaultLogFile.DebugLevel := DBGLEVEL_ULTIMATE;
          {$ENDIF}
    finally
        Self.FSwitcher.RevertToPrevious();
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
    Self.FSwitcher.SwitchTo(APP_NET_USER);
    try
        Result := FileHnd.FileCopy(SrcFile, DestFile, True) = ERROR_SUCCESS;
    finally
        Self.FSwitcher.RevertToPrevious();
    end;
end;

function TDMMainController.GetIsPatchApplied : boolean;
var
    RuntimeDate, AppliedDate : TDateTime;
begin
    Result := Self.GetIsPatchAppliedRegVersion();
    if (not Result) then begin
        Self.FSwitcher.SwitchTo(APP_NET_USER);
        try
            RuntimeDate := TFileHnd.FileTimeChangeTime(ParamStr(0));
            if (FileExists(Self.SignatureFilename)) then begin
                AppliedDate := TFileHnd.FileTimeChangeTime(Self.SignatureFilename);
                Result      := (RuntimeDate < AppliedDate);
            end else begin
                Result := False;
            end;
        finally
            Self.FSwitcher.RevertToPrevious();
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
        Self.FSwitcher.SwitchTo(APP_NET_USER);
        try
            TFileHnd.ForceFilename(Self.SignatureFilename);
        finally
            Self.FSwitcher.RevertToPrevious();
        end;
    end else begin
        Self.FSwitcher.SwitchTo(APP_NET_USER);
        try
            DeleteFile(PChar(Self.SignatureFilename));
        finally
            Self.FSwitcher.RevertToPrevious();
        end;
    end;
end;


 ///--------------------------- parte obsoleta ---------------------------------
 ///

function TDMMainController.GetIsPatchAppliedRegVersion : boolean;
var
    reg : TRegistryNT;
    RegDate, RunTimeDate : TDateTime;
    suc : boolean;
begin
    Result := False;
    reg    := TRegistryNT.Create();
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

procedure TDMMainController.SetIsPatchAppliedRegVersion(const Value : boolean);
var
    reg : TRegistryNT;
begin
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
