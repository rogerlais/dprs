{$IFDEF svclBiometricFiles}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclBiometricFiles;

interface

uses
	 Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs, svclTransBio, ExtCtrls;

type
	 TBioFilesService = class(TService)
		 tmrCycleEvent : TTimer;
		 procedure ServiceStart(Sender : TService; var Started : boolean);
		 procedure ServiceCreate(Sender : TObject);
		 procedure ServiceAfterInstall(Sender : TService);
		 procedure ServiceStop(Sender : TService; var Stopped : boolean);
		 procedure tmrCycleEventTimer(Sender : TObject);
		 procedure ServiceBeforeInstall(Sender : TService);
	 private
		 { Private declarations }
		 FSvcThread : TTransBioThread;
	 public
		 function GetServiceController : TServiceController; override;
		 procedure TimeCycleEvent();
		 { Public declarations }
	 end;

var
    BioFilesService : TBioFilesService;

implementation

uses
    AppLog, WinReg32, FileHnd, svclConfig, svclUtils, WinnetHnd, APIHnd;

{$R *.DFM}

procedure ServiceController(CtrlCode : DWord); stdcall;
begin
    BioFilesService.Controller(CtrlCode);
end;

function TBioFilesService.GetServiceController : TServiceController;
begin
    Result := ServiceController;
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
	 reg := TRegistryNT.Create;
    lst := TStringList.Create;
    try
        reg.ReadFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', Lst);
        if lst.IndexOf(Self.Name) < 0 then begin
            lst.Add(APP_SERVICE_NAME);
            lst.Add('SESOP TransBio Replicator');
            TLogFile.Log('Alterando ordem de inicializaçao dos serviços no registro local', lmtInformation);
            reg.WriteFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', Lst, True);
        end;
    finally
        reg.Free;
        lst.Free;
    end;
	 TLogFile.Log('Ordem de carga do serviço alterada com SUCESSO no computador local', lmtInformation);
end;

procedure TBioFilesService.ServiceCreate(Sender : TObject);
var
    x, ret : Integer;
begin
	 /// <remarks>
	 /// Alterado para sempre usar a conta system, ou seja Self.ServiceStartName não atribuido
	 /// </remarks>
	 //Dados para a execução dos threads de serviço
    //Self.Password := GlobalConfig.NetAccountPassword;
    //Self.ServiceStartName := GlobalConfig.NetAccessUserName;

    Self.FSvcThread      := TTransBioThread.Create(True);  //Criar thread de operação primário
    Self.FSvcThread.Name := 'SESOP TransBio Replicator';  //Nome de exibição do thread primário

	 x := 0;
	 ret:=ERROR_SUCCESS;
	 while x < 10 do begin
		Inc(x); 
		 ret :=
			 Self.FSvcThread.InitNetUserAccess(GlobalConfig.NetAccessUserName, GlobalConfig.NetAccesstPassword);
		 if (ret <> ERROR_SUCCESS) then begin
			 TLogFile.Log(Format('Erro de autenticação de conta %s.'#13 + 'Tentativa %d de %d'#13'Erro code = %d',
				 [Globalconfig.NetAccessUserName, x, 10, ret]));
			 Sleep( 30000 ); //30 segundos de espera
		 end else begin  //Conseguiu acesso
			 System.Break;
		 end;
	 end;
	 if (x >= 10) then begin
		 raise ESVCLException.Create('Erro fatal autenticando a conta de replicação dos arquivos biométricos'#13 +
			 SysErrorMessage(ret));
	 end;
end;

procedure TBioFilesService.ServiceStart(Sender : TService; var Started : boolean);
begin
    //Rotina de inicio do servico, cria o thread da operação e o inicia
    Self.tmrCycleEvent.Interval := GlobalConfig.CycleInterval;
    Self.FSvcThread.Start;
    Sleep(300);
    Self.FSvcThread.Suspended := False;
    Started := True;
end;

procedure TBioFilesService.ServiceStop(Sender : TService; var Stopped : boolean);
begin
    Self.FSvcThread.Suspended := True;
end;

procedure TBioFilesService.TimeCycleEvent;
begin
    Self.FSvcThread.Suspended := False;
end;

procedure TBioFilesService.tmrCycleEventTimer(Sender : TObject);
begin
    Self.TimeCycleEvent();
end;

end.
