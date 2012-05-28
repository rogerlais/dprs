{$IFDEF fuMainDataModule}
		{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

unit fuMainDataModule;

interface

uses
	 SysUtils, Classes, JvComponentBase, JvSearchFiles, AppSettings, Forms;

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
        FEmergencyLog :  TStringList;
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
		 function TakeOwership( const filename : string )  : Integer;
    public
        { Public declarations }
        property IsPatchApplied : boolean read GetIsPatchApplied write SetIsPatchApplied;
        property SourceFilePath : string read GetSourceFilePath;
        procedure CheckUpdate(List : TStrings);
        constructor Create(AOwner : TComponent); override;
        destructor Destroy; override;
    end;

var
	 DMMainController : TDMMainController;

implementation

uses
	 FileHnd, Windows, ShlObj, ActiveX, ComObj, ShellFilesHnd, AppLog, WinReg32, fuMainForm, WinNetHnd, WinHnd, StrHnd, IOUtils
	{JediWinAPI, Jwawindows};

const
    IE_GPO_FULLY_APPLIED_DATE = 'HKEY_LOCAL_MACHINE\SOFTWARE\SESOP\Patches\AppliedDates\SRH_ACESSO';
    RE_LOG_APP   = 'HKEY_CURRENT_USER\SESOP\Log\SRH_ACESSO';
    //LOG_ROOT_DIR = 'C:\Temp';
    LOG_ROOT_DIR = '\\macgyver.tre-pb.gov.br\ftp_sesop';
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
    SrcDir := ExtractFilePath(ParamStr(0));

    MessageBoxW(0, PWideChar('Copiando faltosos - origem ' + GetCurrentDir()), 'entrada', MB_OK + MB_ICONSTOP + MB_TOPMOST);


    //Copiar para a pasta padrão os modulos do Acesso
    if not (Self.FAcessoUpdated and Self.FAtualizadorUpdated) then begin
        ForceDirectories(ACESSO_PATH);
        MessageBoxW(0, 'Destino gerado', 'entrada', MB_OK + MB_ICONSTOP + MB_TOPMOST);
        CpOK := CpOK and Self.MirrorCopy(SrcDir, ACESSO_PATH, 'AcessoCli.exe');
		 CpOK := CpOK and Self.MirrorCopy(SrcDir, ACESSO_PATH, 'AcessoCli.ini');
		 CpOK := CpOK and Self.MirrorCopy(SrcDir, ACESSO_PATH, 'Atualizador.ini');
		 CpOK := CpOK and Self.MirrorCopy(SrcDir, ACESSO_PATH, 'Atualizador.exe');

        if (not CpOK) then begin
            MessageBoxW(0, 'Falha copiando arquivos do acesso cliente para caminho padrão', 'ERRO!',
                MB_OK + MB_ICONSTOP + MB_TOPMOST);
        end;

    end else begin
        MessageBoxW(0, 'Acesso atualizado durante o processo', 'entrada', MB_OK + MB_ICONSTOP + MB_TOPMOST);
    end;

    //Copiar o SRH.exe  para a sua padrão
    if (not Self.FSRHUpdated) then begin
        ForceDirectories(SRH_PATH);
        if (not Self.MirrorCopy(SrcDir, SRH_PATH, 'SRH.exe')) then begin
            MessageBoxW(0, 'Falha copiando arquivos do SRH para caminho padrão', 'ERRO!', MB_OK + MB_ICONSTOP + MB_TOPMOST);
        end else begin
            MessageBoxW(0, 'SRH atualizado COM SUCESSO', 'entrada', MB_OK + MB_ICONSTOP + MB_TOPMOST);
        end;
        MessageBoxW(0, 'SRH atualizado durante o processo', 'entrada', MB_OK + MB_ICONSTOP + MB_TOPMOST);
    end;
    MessageBoxW(0, 'Copiando faltosos', 'saída', MB_OK + MB_ICONSTOP + MB_TOPMOST);
end;


procedure TDMMainController.RunUpdates(List : TStrings);
var
    LnkPath : string;
begin
    Self.FTmpList.BeginUpdate;
    try
         {$IFNDEF DEBUG}
        TLogFile.LogDebug('Buscando na unidade C:\', DBGLEVEL_DETAILED);
        Self.FileSearcher.RootDirectory := 'C:\';
        Self.FileSearcher.Search;
         {$ENDIF}
        TLogFile.LogDebug('Buscando na unidade D:\', DBGLEVEL_DETAILED);
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

    Self.DebugLog('Checando update Saida');

end;

constructor TDMMainController.Create(AOwner : TComponent);
begin
    inherited;
    Self.InitLog();
    Self.FTmpList      := TStringList.Create;
    Self.FEmergencyLog := TStringList.Create;
end;

procedure TDMMainController.DataModuleCreate(Sender : TObject);
const
    DEBUG_TOKEN = '/DBGLVL';
var
    x :   Integer;
    vl :  string;
    dbg : Integer;
begin
    for x := 0 to ParamCount do begin
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
    for x := 0 to ParamCount do begin
        if (UpperCase(ParamStr(x)) = '/AUTO') then begin
            Self.CheckUpdate(nil);
            Exit;
        end;
    end;

    //Caso a flag /auto seja passa linhas abaixo não executadas
    Application.CreateForm(TFUMainWindow, FUMainWindow);
end;

procedure TDMMainController.DebugLog(const log : string);
begin
    Self.FEmergencyLog.Add(log);
    AppLog.TLogFile.LogDebug(log, DBGLEVEL_ULTIMATE);
end;

destructor TDMMainController.Destroy;
begin
    {TODO -oroger -curgente : remover ao final}
    ForceDirectories('C:\temp');
    Self.FEmergencyLog.SaveToFile('C:\Temp\Emergency.Log');
    Self.FEmergencyLog.Free;

    Self.FTmpList.Free;

    MessageBoxW(0, 'Aplicativo finalizado normalmente', PWideChar(Error), MB_OK + MB_ICONSTOP + MB_TOPMOST);


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
    if not SameText(ParentDir(DestName), ACESSO_PATH) then begin
        DeleteFile(PChar(DestName));
    end else begin
        Self.FAcessoUpdated := Self.MirrorCopy(Self.SourceFilePath, ACESSO_PATH, 'AcessoCli.exe');
    end;
end;

procedure TDMMainController.UpdateAtualizador(const DestName : string);
//Atualizar atualizador
begin
    if not (SameText(ParentDir(DestName), ACESSO_PATH)) then begin
        DeleteFile(PChar(DestName));
    end else begin
        Self.FAtualizadorUpdated := Self.MirrorCopy(Self.SourceFilePath, ACESSO_PATH, 'Atualizador.exe');
        //Flag de atualizador atualizado
    end;
end;

procedure TDMMainController.UpdateSRH(const DestName : string);
//Atualizar SRH
begin
    if not (SameText(ParentDir(DestName), SRH_PATH)) then begin
        DeleteFile(PChar(DestName));
    end else begin
        Self.FSRHUpdated := Self.MirrorCopy(Self.SourceFilePath, SRH_PATH, 'SRH.exe');
    end;
end;

procedure TDMMainController.InitLog;
begin
    if (WinHnd.ImpersonateAnotherUser('download@tre-pb.gov.br', 'pinico123') <> 0) then begin
        MessageBoxW(0, 'Logon alternativo download@tre-pb.gov.br falhou', 'info', MB_OK + MB_ICONSTOP + MB_TOPMOST);
    end;
    ForceDirectories(LOG_ROOT_DIR);
    TLogFile.GetDefaultLogFile.FileName   :=
        TFileHnd.ConcatPath([LOG_ROOT_DIR, 'SESOP_' + WinNetHnd.GetComputerName() + '.log']);
     {$IFDEF DEBUG}
    TLogFile.GetDefaultLogFile.DebugLevel := DBGLEVEL_ULTIMATE;
     {$ENDIF}

end;

function TDMMainController.MirrorCopy(const SrcPath, DestPath, Filename : string) : boolean;
var
	 SrcFile, DestFile : string;
	 F : TFile;
begin
	 SrcFile  := TFileHnd.ConcatPath([SrcPath, Filename]);
	 DestFile := TFileHnd.ConcatPath([DestPath, Filename]);
	 DeleteFile( PChar(DestFile) );
	 //Result   := FileHnd.FileCopy(SrcFile, DestFile, True) = ERROR_SUCCESS;
	 F.Copy( SrcFile, DestFile, True );
end;

function TDMMainController.GetIsPatchApplied : boolean;
var
    SignatureFilename : string;
    RuntimeDate, AppliedDate : TDateTime;
begin
    SignatureFilename := TFileHnd.ConcatPath([LOG_ROOT_DIR, 'OK_' + GetComputerName()]);

    RuntimeDate := TFileHnd.FileTimeChangeTime(ParamStr(0));
    if (FileExists(SignatureFilename)) then begin
        AppliedDate := TFileHnd.FileTimeChangeTime(SignatureFilename);
        Result      := (RuntimeDate < AppliedDate);
    end else begin
        Result := False;
    end;

    if (not Result) then begin
        Self.DebugLog('Detectada a necessidade de atualização');
    end else begin
        Self.DebugLog('Computador identificado como atualizado');
    end;

end;


procedure TDMMainController.SetIsPatchApplied(const Value : boolean);
var
    SignatureFilename : string;
begin
    SignatureFilename := TFileHnd.ConcatPath([LOG_ROOT_DIR, 'OK_' + GetComputerName()]);
    DeleteFile(PChar(SignatureFilename));
    if (Value) then begin
        TFileHnd.ForceFilename(SignatureFilename);
    end;
end;


 ///--------------------------- parte obsoleta ---------------------------------
 ///

function TDMMainController.GetIsPatchAppliedRegVersion : boolean;
var
    reg : TRegistryNT;
    RegDate, RunTimeDate : TDateTime;
begin
    Result := False;
    reg    := TRegistryNT.Create();
    try
        try
            if (reg.ReadFullDateTime(IE_GPO_FULLY_APPLIED_DATE, RegDate)) then begin
                TLogFile.LogDebug('Carregando runtime em ' + ParamStr(0), DBGLEVEL_ULTIMATE);
                RunTimeDate := TFileHnd.FileTimeChangeTime(ParamStr(0));
                TLogFile.LogDebug('Usando data de referência de atualização: ' + DateTimeToStr(RunTimeDate), DBGLEVEL_ULTIMATE);
                Result := (RegDate >= RunTimeDate);
            end else begin
                Result := False;
            end;
        except
            Result := False;
        end;
    finally
        reg.Free;
        if (not Result) then begin
            TLogFile.LogDebug('Atualização requerida!!!!', DBGLEVEL_NONE);
        end;
    end;
end;

function TDMMainController.GetSourceFilePath : string;
begin
	 //Result := TFileHnd.SlashRem(ExtractFilePath(ParamStr(0)));
	 {$MESSAGE WARN 'alerta de camino hc' }
	 Result:='\\macgyver.tre-pb.gov.br\ftp_sesop';
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

function TDMMainController.TakeOwership(const filename: string): Integer;
(*
var
	secureFile : TJwSecureFileObject;
	Sid : TJwSecurityId;
	Token : TJwSecurityToken;
*)
begin
(*
	 if not FileExists( filenae ) then begin
	 exit;
	 end;

	 //use any token - also from LogonUser here
	 Token := TJwSecurityToken.CreateTokenByProcess(0, TOKEN_ALL_ACCESS);
	 try
	 //thread impersonation
	 Token.ImpersonateLoggedOnUser;

	 try
	 secureFile := TJwSecureFileObject.Create(ParamStr(1));
	 try
	 //enable takeownership if available
	 JwEnablePrivilege(SE_TAKE_OWNERSHIP_NAME, pst_EnableIfAvail)

	 //use thread token user (or process token if none exists)
	 Sid := JwSecurityCurrentThreadUserSID;
	 secureFile.SetOwner(Sid);
	 Writeln('Success: Set ',ParamStr(0), ' to owner',Sid.GetText(true));
	 finally
	 Sid.Free;
	 secureFile.Free;
end;
	 finally

	 end;
end;

*)
end;


end.
