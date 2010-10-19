{$IFDEF vvMainDataModule}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
{$TYPEINFO OFF}

unit vvMainDataModule;

interface

uses
    SysUtils, Classes, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, IdMessage,
    IdExplicitTLSClientServerBase,
    IdMessageClient, IdSMTPBase, IdSMTP, IdMailBox, FileInfo, Forms;


const
    VERSION_URL_FILE = 'http://arquivos/setores/sesop/AppData/VerificadorVersoes/VVer.ini';

type
    TdtmdMain = class(TDataModule)
        httpLoader :    TIdHTTP;
        smtpSender :    TIdSMTP;
        mailMsgNotify : TIdMessage;
        fvVersion :     TFileVersionInfo;
        procedure DataModuleCreate(Sender : TObject);
    private
        { Private declarations }
        procedure AddDestinations();
    public
        { Public declarations }
        function LoadURL(const url : string) : string;
        procedure InitInfoVersions();
        procedure SendNotification();
    end;

var
    dtmdMain : TdtmdMain;

implementation

uses
    FileHnd, vvConfig, StrHnd, IdEMailAddress, WinNetHnd, AppLog, vvMainForm;

{$R *.dfm}

{ TdtmdMain }

procedure TdtmdMain.AddDestinations;
var
    dst : TIdEMailAddressItem;
    lst : TStringList;
    x :   Integer;
begin
    lst := TStringList.Create;
    try
        lst.Delimiter     := ',';
        lst.DelimitedText := GlobalInfo.NotificationList;
        for x := 0 to lst.Count - 1 do begin
            dst      := Self.mailMsgNotify.Recipients.Add();
            dst.Address := lst.Strings[x];
            dst.Name := 'SESOP - Verificador de Sistemas eleitorais';
        end;
    finally
        lst.Free;
    end;
end;

procedure TdtmdMain.DataModuleCreate(Sender : TObject);
var
    x : Integer;
    autoMode : boolean;
begin
	 autoMode := False;
	 for x := 0 to ParamCount do begin
	 	TLogFile.Log(ParamStr(x));
		 if SameText(ParamStr(X), '/auto') then begin
			 autoMode := True;
			 Break;
		 end;
	 end;
	 if (autoMode) then begin
		Application.ShowMainForm := False;
		 try
			 Self.InitInfoVersions();
		 except
			 on E : Exception do begin
				 AppFatalError('Erro carregando informações de controle de versões'#13#10 + E.Message, 1, False);
				 Exit;
			 end;
		 end;
		 //Envio da notificação
		 Self.SendNotification();
		 Application.Terminate;
	 end else begin
		Application.CreateForm(TForm1, Form1);
    end;
end;

procedure TdtmdMain.InitInfoVersions;
{{
Rotina de inicialização para a carga dos parametros iniciais e perfil associado
}
var
    baseConfFile : string;
begin
    //Carga dos parametros iniciais
    baseConfFile := Self.LoadURL(VERSION_URL_FILE);
    LoadGlobalInfo(baseConfFile);
end;

function TdtmdMain.LoadURL(const url : string) : string;
{{
Recebe a URL e tenta salvar seu conteúdo com o mesmo nome na pasta do executável. Caso isso não seja possível será usado o temporário
}
var
    MemStream :  TMemoryStream;
    FileStream : TFileStream;
begin
    Result := TFileHnd.ChangeFileName(ParamStr(0), TStrHnd.CopyAfterLast('/', url)); //Nome final do arquivo
    try
        MemStream := TMemoryStream.Create;
        try
            try
                Self.httpLoader.Get(url, MemStream);
            except
                on E : Exception do begin //Verifica possibilidade de uso do arquivo localmente disposto
                    if FileExists(Result) then begin
                        Exit;
                    end else begin
                        raise; //Erro irrecuperável
                    end;
                end;
            end;
            //Verifica a escrita para atualizar informações de versões
            MemStream.Position := 0;
            if not TFileHnd.IsWritable(Result) then begin
                Result := FileHnd.CreateTempFileName('SESOPVVER', 1);
            end;
            if FileExists(Result) then begin
                FileStream := TFileStream.Create(Result, fmOpenWrite);
            end else begin
                FileStream := TFileStream.Create(Result, fmCreate);
            end;
            try
                MemStream.SaveToStream(FileStream);
            finally
                FileStream.Free;
            end;
        finally
            MemStream.Free;
        end;
    except
        on E : Exception do begin
            raise Exception.CreateFmt('Erro lendo arquivo de informações sobre versões:'#13#10'%s'#13#10'%s', [url, E.Message]);
        end;
    end;
end;

procedure TdtmdMain.SendNotification;
const
    //Modelo = VVer - Versão <1.0.2010.2> - <ZPB080STD01> - 201009242359 - Pendente';
    SUBJECT_TEMPLATE = 'VVer - Versão: %s - %s - %s - %s';
begin
    //Coletar informações de detino de mensagem com possibilidade de macros no mesmo arquivo de configuração
    Self.AddDestinations();
    Self.mailMsgNotify.Subject   := Format(SUBJECT_TEMPLATE, [Self.fvVersion.FileVersion, WinNetHnd.GetComputerName(),
        FormatDateTime('yyyyMMDDhhmm', Now()), GlobalInfo.GlobalStatus]);
    Self.mailMsgNotify.Body.Text := GlobalInfo.InfoText;
    Self.smtpSender.Connect;
    Self.smtpSender.Send(Self.mailMsgNotify);
    Self.smtpSender.Disconnect(True);
end;

end.
