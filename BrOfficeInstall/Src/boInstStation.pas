{$IFDEF boInstStation}
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I boInstall.inc}

unit boInstStation;

interface

uses
    Windows, Classes, SysUtils, Forms, TREUtils, Variants, ComObj, Activex, boInstUtils, StrHnd, boInstConfig,
    boinstDataModule;

type
    TBrOfficeInstallState = (
        broisUnknow,    //Ainda inderterminado
        broisInvalid,   //Presente, mas invalido
        broisNone,      //Nenhuma versão presente
        broisOld,       //Desatualizada
        broisUpdated    //Igual ou superior a versão de referência
        );

    TBROfficeStation = class(TObject)
    private
        FName :         string;
        FReferenceVersion : string;
        FInstalledBrOfficeVersion : string;
        FInstallState : TBrOfficeInstallState;
        function GetInstalledBrOfficeVersion : string;
        function ReadInstalledBrOfficeVersion : string;
        function GetInstallState : TBrOfficeInstallState;
        procedure SetReferenceVersion(const Value : string);
        function HasAnyOpenOffice() : boolean;
        procedure UpdateSourceFiles();
        procedure RunSetup();
        procedure RunUninstall();
        function GetIsProfileUpdated : boolean;
        function GetServerInstallDir : string;
        function RenameOldProfile(const ProfileDir : string) : string;
    protected
        procedure UpdateProfile(const UserProfileRoot, UserFolder : string; CopyBase : boolean);
        procedure CloseBrOfficeInstances;
    public
        constructor Create(const AName : string);
        destructor Destroy; override;
        procedure InstallNewVersion();
        property Name : string read FName;
        property InstalledBrOfficeVersion : string read GetInstalledBrOfficeVersion;
        property InstallState : TBrOfficeInstallState read GetInstallState;
        property ReferenceVersion : string read FReferenceVersion write SetReferenceVersion;
        property isProfileUpdated : boolean read GetIsProfileUpdated;
        property ServerInstallDir : string read GetServerInstallDir;
        procedure UpdateVersion;
        procedure UpdateAllProfiles;
    end;


implementation

uses
    FileHnd, Str_Pas, WinHnd, WinNetHnd, APIHnd, Dialogs, JvCreateProcess;

{ TBROfficeStation }

procedure TBROfficeStation.CloseBrOfficeInstances;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.CloseBrOfficeInstances

Fecha instancias do broffice baseadas nas classes de janelas encontradas anteriormente nos computadores de desenvolvimento

Revision: 22/4/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    { TODO -oroger -cdsg : Garantir que não há instancias do BrOffice em execução antes }
    //SALFRAME ou SALCOMWND ou "SO Executer Class"

end;

constructor TBROfficeStation.Create(const AName : string);
{{
TBROfficeStation.Create

Inicia a estação de trabalho para a operação de instalação/atualização do BrOffice

Revision: 12/2/2010 - roger
}
begin
    inherited Create;
    Self.FName := AName;
    Self.ReferenceVersion := Config.MinVersion;
    Self.FInstallState := broisUnknow;
end;

destructor TBROfficeStation.Destroy;
{{
TBROfficeStation.Destroy

Libera instancia normalmente

Revision: 12/2/2010 - roger
}
begin
    inherited;
end;

function TBROfficeStation.GetInstalledBrOfficeVersion : string;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.GetInstalledBrOfficeVersion

Retorna a versão instalado do BrOffice no computador em execução

Revision: 12/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
var
    AppDataDir, BROProfile : string;
begin
    if (Self.FInstalledBrOfficeVersion = EmptyStr) then begin
        //Verifica se existe BrOffice instalado/registrado
        if (Self.HasAnyOpenOffice) then begin
            //Checar se perfil existe para a conta de execução
            AppDataDir := TApiHnd.GetEnvironmentVar('APPDATA');
            if (AppDataDir = EmptyStr) then begin
                AppDataDir := TApiHnd.GetEnvironmentVar('UserProfile');
                if (AppDataDir = EmptyStr) then begin
                    raise Exception.Create('Impossível determinar perfil da conta em uso neste momento');
                end else begin
                    BROProfile := TFileHnd.ConcatPath([AppDataDir, 'Dados de aplicativos', 'BrOffice.org']);
                end;
            end else begin
                BROProfile := TFileHnd.ConcatPath([AppDataDir, 'BrOffice.org']);
            end;
            if (not DirectoryExists(BROProfile)) then begin
                if (not CopyFile(PAnsiChar(Config.BaseProfileSourcePath), PAnsiChar(BROProfile), False)) then begin
                    raise Exception.CreateFmt('Falha preparando ambiente para execução de determinação de versão.'#13'%s',
                        [SysErrorMessage(GetLastError())]);
                end;
            end;
        end;
        try
            Self.FInstalledBrOfficeVersion := Self.ReadInstalledBrOfficeVersion();
        except
            Self.FInstalledBrOfficeVersion := EmptyStr;
        end;
    end;
    Result := Self.FInstalledBrOfficeVersion;
end;

function TBROfficeStation.GetInstallState : TBrOfficeInstallState;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.GetInstallState

Informa a situação da instalação em relação a versão de referência. Caso a versão de referência seja nula sempre teremos um estado
desconhecido

Revision: 12/2/2010 - roger
}
var
    v1, v2 : string;
    ret :    Integer;
begin
    if (Self.FInstallState = broisUnknow) then begin //determinar a versão presente
        v1 := Self.GetInstalledBrOfficeVersion;
        if (v1 = EmptyStr) then begin
            if (Self.HasAnyOpenOffice) then begin
                Self.FInstallState := broisInvalid;
            end else begin
                Self.FInstallState := broisNone;
            end;
        end else begin
            v2  := Config.MinVersion;
            ret := CompareVersionStrings(v1, v2);
            case ret of
                0 : begin
                    Self.FInstallState := broisUpdated;
                end;
                1 : begin
                    Self.FInstallState := broisUpdated;
                end;
                2 : begin
                    Self.FInstallState := broisOld;
                end;
                else begin
                    raise Exception.Create('Comparação de versões inválida.');
                end;
            end;
        end;
    end;
    Result := Self.FInstallState;
end;

function TBROfficeStation.GetIsProfileUpdated : boolean;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.GetIsProfileUpdated

Retorna o registro sinalizador de que o perfil foi atualizado para uma determinada versão

Revision: 23/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    Result := (Config.CurrentProfileDate >= Config.BaseProfileDate );
end;

function TBROfficeStation.GetServerInstallDir : string;
begin

end;

function TBROfficeStation.HasAnyOpenOffice : boolean;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.HasAnyOpenOffice

Retorna indicador de que existe qualquer versão do BrOffice registrada neste computador.
Testa-se buscando-se por registro na lista de programas instalados

Revision: 23/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
var
    list : TStringList;
    x :    Integer;
begin
    Result := False;
    //Pegar lista de aplicativos instalados no computador
    list   := TStringList.Create;
    try
        GetInstalledApps(list);
        for x := 0 to list.Count - 1 do begin
            if (TStrHnd.startsWith(list.Strings[x], 'BrOffice.org')) then begin
                Result := True;
                Exit;
            end;
        end;
    finally
        list.Free;
    end;
end;

procedure TBROfficeStation.InstallNewVersion;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.InstallNewVersion

Realiza a instalação da nova versão.

Revision: 22/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    //Garantir integridade arquivos localizados na subpasta BrOfficeInstFiles com localizada na pasta temporaria local do computador
    Self.UpdateSourceFiles();
    //Lança MSI com a linha de comando passada
    Self.RunSetup();
end;

function TBROfficeStation.ReadInstalledBrOfficeVersion : string;
var
    SManager, CoreRef : variant;
    A, Args, aSettings, aConfigProvider, OOOVersion : variant;
begin

    //********** TESTE
    //Self.FInstalledBrOfficeVersion := '3.1.0.teste';
    //********** FIM TESTE


    if (Self.FInstalledBrOfficeVersion = EmptyStr) then begin
        Args     := VarArrayCreate([0, 0], varVariant);
        SManager := CreateOleObject('com.sun.star.ServiceManager');
        CoreRef  := SManager.createInstance('com.sun.star.reflection.CoreReflection');
        CoreRef.forName('com.sun.star.beans.PropertyValue').createObject(A);
        A.Name     := 'nodepath';
        A.Value    := '/org.openoffice.Setup/Product';
        Args[0]    := A;
        aConfigProvider := SManager.createInstance('com.sun.star.configuration.ConfigurationProvider');
        aSettings  := aConfigProvider.createInstanceWithArguments('com.sun.star.configuration.ConfigurationAccess', Args);
        OOOVersion := aSettings.getByName('ooSetupVersionAboutBox');
        Self.FInstalledBrOfficeVersion := OOOVersion;
    end;
    Result := Self.FInstalledBrOfficeVersion;
end;

function TBROfficeStation.RenameOldProfile(const ProfileDir : string) : string;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.RenameOldProfile

Renomeia ProdfileDir para padrão "ProfileDir(n) onde n será formatado com 2 dígitos

Revision: 11/3/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    Result := NextFamilyFilename2(ProfileDir);
end;

procedure TBROfficeStation.RunSetup;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.RunSetup

Inicia o processo do MSI e aguarda seu termino com o error_level para verificar seu sucesso

Revision: 22/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
var
    args :     string;
    DestFree : int64;
begin
    DestFree := FileHnd.SpaceFree(Config.InstallDestination);
    if (Config.MinDiskSpace > DestFree) then begin //Verificar o espaco em disco necessario para continuar
        raise Exception.CreateFmt('Espaço em disco insuficiente para instalação continuar'#13'%s Livres'#13'Requeridos: %s',
            [Str_Pas.FormatMemSize(DestFree), Str_Pas.FormatMemSize(Config.MinDiskSpace)]);
    end;
    MainDM.InstallProcess.ApplicationName := 'c:\windows\system32\msiexec.exe';
    //***NOTA: MANTER o espaço no inicio da cadeia de argumentos e %% para as macros!!!!
    args := Format(
        ' /passive /norestart /i %s ADDLOCAL=ALL REMOVE=gm_o_Quickstart ALLUSERS=1 ' +
        'INSTALLLOCATION="%s"',
        [TFileHnd.ConcatPath([Config.InstallTempDir, Config.InstallPackageName]), Config.InstallDestination]);
    MainDM.InstallProcess.CommandLine := args;
    MainDM.InstallProcess.WaitForTerminate := True;
    MainDM.InstallProcess.CurrentDirectory := Config.InstallTempDir;

    MainDM.InstallProcess.Run;
    { TODO -oroger -cdsg : Colocar tempo máximo para a execução do processo de instalação }
    Sleep(1000);
    while (MainDM.InstallProcess.State = psWaiting) do begin
        //Espera finalizar o processo de instalação
        Application.ProcessMessages();
        SwitchToThread();
    end;
    {$IFDEF DEBUG}
    MessageDlg(Format('Texto=%s'#13'Retorno=%d'#13'Msg=%s',
        [MainDM.InstallProcess.ConsoleOutput.Text, MainDM.InstallExitCode, SysErrorMessage(MainDM.InstallExitCode)]),
        mtInformation, [mbOK], 0);
    {$ENDIF}
    if ( MainDM.InstallExitCode <> 0 ) then begin
       raise Exception.CreateFmt('Falha durante instalação:'#13'%s', [ SysErrorMessage( MainDM.InstallExitCode ) ]);
    end;
end;

procedure TBROfficeStation.RunUninstall;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.RunUninstall

Remove a versão anterior do BrOffice pela execução de seu desinstalador

Revision: 11/3/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
var
    interactiveCmdLine, cmdLine, args : string;
    p : Integer;
begin
    Self.CloseBrOfficeInstances;
    //Algo do tipo MsiExec.exe /I{C5DB712E-4D93-46BC-8F0E-5E6274870F1C} trocando /I por /X e inserindo /passive ao final
    //Deve-se localizar commandline via registro
    interactiveCmdLine := boInstUtils.GetUninstallBrOfficeString();
    cmdLine := ReplaceSubString(interactiveCmdLine, '/I{', '/X{');
    if (SameText(cmdLine, interactiveCmdLine)) then begin
        //Inclui falha de captura de linha de comando
        raise Exception.CreateFmt('Cadeia de desinstalação não obedece o padrão esperado'#13'"%s"', [cmdLine]);
    end else begin
        p := Pos('/X', cmdLine);
        if (p = 0) then begin
            raise Exception.Create('Comando de desinstalação para esta versão mal formada.');
        end else begin
            cmdLine := Copy(cmdLine, p, Length(cmdLine));
        end;
    end;

    MainDM.UninstallProcess.ApplicationName := 'c:\windows\system32\msiexec.exe '; //Espaço ao final necessário
    //***NOTA: MANTER o espaço no inicio da cadeia de argumentos e %% para as macros!!!!
    args := ' ' + cmdLine + ' /passive /norestart';
    MainDM.UninstallProcess.CommandLine := args;
    MainDM.UninstallProcess.WaitForTerminate := True;
    MainDM.UninstallProcess.CurrentDirectory := Config.InstallTempDir;
    MainDM.UninstallProcess.Run;
    { TODO -oroger -cdsg : Colocar tempo máximo para a execução do processo de instalação }
    Sleep(1000);
    while (MainDM.UninstallProcess.State = psWaiting) do begin
        //Espera finalizar o processo de instalação
        Application.ProcessMessages();
        SwitchToThread();
    end;

    if ( MainDM.UninstallExitCode <> 0 ) then begin
       raise Exception.CreateFmt('Necessária a intervenção do usuário.'#13'%s', [ SysErrorMessage( MainDM.UninstallExitCode ) ] );
    end else begin
       MessageDlg(Format('Texto=%s'#13'Retorno=%d'#13'Msg=%s'#13'Preparando-se para instalar nova versão...',
           [MainDM.UninstallProcess.ConsoleOutput.Text, MainDM.UninstallExitCode, SysErrorMessage(MainDM.UninstallExitCode)]),
           mtInformation, [mbOK], 0);
    end;  
end;

procedure TBROfficeStation.SetReferenceVersion(const Value : string);
{{
TBROfficeStation.SetReferenceVersion

Ajusta a versão de referência.
Ao realizar o ajuste o status da instalação é atualizado e invalidar o status da instalação para recalcular depois 

Revision: 12/2/2010 - roger
}
begin
    Self.FReferenceVersion := Value;
    Self.FInstallState     := broisUnknow;
end;

procedure TBROfficeStation.UpdateAllProfiles;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.UpdateAllProfiles

Renomeia perfil atual do BrOffice para "BrOffice(n)" de todas as contas presentes de modo a preservar a anterior
e copia o perfil padrão para as contas "localservice" e "Default User" que serão usadas futuramente


Revision: 10/3/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
var
    X :    Integer;
    ProfileRoot, CurrentUser : string;
    list : TStringList;
begin
    if (Config.BaseProfileDate > Config.CurrentProfileDate) then begin

        ProfileRoot := ExtractFilePath(TApiHnd.GetEnvironmentVar('ALLUSERSPROFILE'));
        if (ProfileRoot = EmptyStr) then begin
            raise Exception.Create('Erro lendo valor para pasta de perfis de usuários');
        end;

        list := TStringList.Create;
        try
            { TODO -oroger -clib : Procurar correção para a mascara usada, pois VCL farrapa com *.* }
            FileHnd.ListDirFilesNames(ProfileRoot, '*', faDirectory, False, list);
            for X := 0 to list.Count - 1 do begin
                CurrentUser := ExtractFileName(list.Strings[x]);
                //Checar conta LocalService e "Defaul User"
                Self.UpdateProfile(ProfileRoot, CurrentUser,
                    not TStrHnd.IsPertinent(CurrentUser, ['Administrador', 'All Users', 'ghost', 'NetworkService'], False));
            end;
        finally
            list.Free;
        end;
        //Atualiza a data do perfil registrado no computador
        Config.CurrentProfileDate:=Config.BaseProfileDate;
    end;
end;

procedure TBROfficeStation.UpdateProfile(const UserProfileRoot, UserFolder : string; CopyBase : boolean);
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.UpdateProfile

Renomeia perfil atual do BrOffice para "BrOffice(n)" e copia o perfil padrão para as contas "localservice" e "Default User"

Revision: 23/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
var
    ProfilePath, BakProfilePath : string;
    ret : Integer;
begin
    ProfilePath := TFileHnd.ConcatPath([UserProfileRoot, UserFolder, 'Dados de Aplicativos', 'BrOffice.Org']);
    if (DirectoryExists(ProfilePath)) then begin
        try
            BakProfilePath := Self.RenameOldProfile(ProfilePath); //Gera novo nome
            if (not MoveFile(PAnsiChar(ProfilePath), PAnsiChar(BakProfilePath))) then begin
                TApiHnd.CheckAPI(GetLastError());
            end;
        except
            on E : Exception do begin
                raise Exception.CreateFmt('Impossível salvar perfil anterior para a conta %s'#13'%s', [UserFolder, E.Message]);
            end;
        end;
    end;
    if (CopyBase) then begin   //Copia perfil base para a conta
        if (not ForceDirectories(ProfilePath)) then begin
            raise Exception.CreateFmt('Erro criando novo perfil para "%s"'#13'%s', [UserFolder, SysErrorMessage(GetLastError())]);
        end;
        ret := TFileHnd.CopyDir(Config.BaseProfileSourcePath, ProfilePath);
        TApiHnd.CheckAPI(ret);
    end;
end;

procedure TBROfficeStation.UpdateSourceFiles;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.UpdateSourceFiles

Atualiza todos os arquivos localizados na subpasta BrOfficeInstFiles para a pasta temporaria local de mesmo nome

Revision: 22/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
var
    Source, dest : string;
    ret : Integer;
begin
    //--copia todos os arquivos da pasta de origem para a pasta de destino e lançar instalador
    Source := Config.InstallSourcePath;
    Source := SysUtils.ExpandFileName(Source);
    dest   := Config.InstallTempDir;
    ret    := 0;
    { TODO -oroger -cDESEJAVEL : Tentar localizar chamada para apenas atualizar arquivos de modo a reduzir trafego de rede }
    if (FileHnd.FindFirstChildFile(dest) = EmptyStr) then begin
        ret := TFileHnd.CopyDir(Source, dest);
    end;
    if (ret <> ERROR_SUCCESS) then begin
        TAPIHnd.CheckAPI(ret);
    end;
end;

procedure TBROfficeStation.UpdateVersion;
{{--------------------------------------------------------------------------------------------------------------------------------
TBROfficeStation.UpdateVersion

Realiza a desinstalação da versão anterior e instalação da nova

Revision: 23/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    Self.RunUninstall;
    Self.RunSetup;
end;

end.
