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
    AppLog, WinReg32, FileHnd, svclConfig;

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
var
    reg : TRegistryNT;
    lst : TStringList;
begin
    //Ajusta as credenciais para instalação do serviço
    { TODO -oroger -cURGENTE : Rever pois apenas system deu ok }
    //Self.Password := GlobalConfig.ServiceAccountPassword;
    //Self.ServiceStartName := GlobalConfig.ServiceAccountName;



    TLogFile.Log(Format('Registrando o registro do serviço com as credenciais:'#13'Conta: %s'#13'Senha: %s',
        [Self.ServiceStartName, Self.Password]), lmtInformation);
    reg := TRegistryNT.Create;
    lst := TStringList.Create;
    try
        reg.ReadFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', Lst);
        if lst.IndexOf(Self.Name) < 0 then begin
           lst.Add('BioFilesService');
           lst.Add('SESOP TransBio Replicator');
           TLogFile.Log('Alterando ordem de inicializalçao dos serviços no registro local');
           reg.WriteFullMultiSZ('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ServiceGroupOrder\List', Lst, True );
        end;
    finally
        reg.Free;
        lst.Free;
    end;
end;

procedure TBioFilesService.ServiceCreate(Sender : TObject);
begin
    {TODO -oroger -cdsg : Ajustar o StartName e o Password de acordo com a configuração ou linha de comando}
    Self.FSvcThread := TTransBioThread.Create(True);
    Self.FSvcThread.Name := 'SESOP TransBio Replicator';
    Self.Password := GlobalConfig.ServiceAccountPassword;
    Self.ServiceStartName := GlobalConfig.ServiceAccountName;
    TLogFile.Log(Format('Iniciando o registro do serviço com as credenciais:'#13'Conta: %s'#13'Senha: %s',
        [Self.ServiceStartName, Self.Password]), lmtInformation );
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
