{$IFDEF boInstMainForm}
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I boInstall.inc}

unit boInstMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, boInstUtils, StrHnd, boInstStation, WinNetHnd, boInstConfig;

type
    TForm1 = class(TForm)
        Button1 : TButton;
        procedure Button1Click(Sender : TObject);
    procedure FormCreate(Sender: TObject);
    private
        { Private declarations }
        procedure ShowSuccess;
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

uses FileHnd, boinstDataModule;

{$R *.dfm}

procedure TForm1.Button1Click(Sender : TObject);
var
    station : TBROfficeStation;
begin
    station := TBROfficeStation.Create(WinNetHnd.GetComputerName());
    try 
        try
            case station.InstallState of
                broisUnknow : begin
                   { TODO -oroger -cdsg : Chamar a equipe de suporte }
                   MessageDlg('Chamar a equipe de suporte', mtError, [mbOK], 0);
                end;
                broisNone : begin  //Realizar a instalação direta
                   station.InstallNewVersion();
                   station.UpdateAllProfiles();
                   Self.ShowSuccess;
                end;
                broisOld : begin   //Remover a versão anterior
                   station.UpdateVersion();
                   station.UpdateAllProfiles();
                   Self.ShowSuccess;
                end;
                broisUpdated : begin   //Verificar/atualizar os arquivos de modelos
                   if ( not station.isProfileUpdated ) then begin
                       station.UpdateAllProfiles();
                   end;
                   Self.ShowSuccess;
                end;
                broisInvalid : begin
                   { TODO -oroger -cdsg : Tratar o caso de primeira execução, pois o serviço OLE dispara o assistente de registro }
                   MessageDlg('Encontrado estado inválido para este computador', mtError, [mbOK], 0);
                end;
                else begin
                    raise Exception.Create('Erro inderteminado durante captura da versão instalada');
                end;
            end;
        except
            on E : Exception do begin
               raise EBROInstallException.Create('Um erro fatal ocorreu:'#13 + E.Message);
            end;
        end;
    finally
        station.Free;
    end;
end;

procedure TForm1.ShowSuccess;
begin
   MessageDlg('Instalação e atualização de perfil executada com sucesso', mtInformation, [mbOK], 0);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
   {$IFDEF DEBUG}
   Self.Caption:=Self.Caption + ' ***(Debug) ' + FileHnd.TFileHnd.VersionInfo( ParamStr(0) ) + ' ***';
   {$ELSE}
   Self.Caption:=Self.Caption + ' ' + FileHnd.TFileHnd.VersionInfo( ParamStr(0) );
   {$ENDIF}
end;

end.
