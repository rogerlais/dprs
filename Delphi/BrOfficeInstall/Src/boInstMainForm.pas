{$IFDEF boInstMainForm}
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I boInstall.inc}

unit boInstMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, boInstUtils, StrHnd, boInstStation, WinNetHnd, boInstConfig,
    JvExMask, JvToolEdit, JvMaskEdit, JvCheckedMaskEdit, JvDatePickerEdit, JvDBDatePickerEdit, ExtCtrls, Mask, Buttons;

type
    TForm1 = class(TForm)
        btnExecInstall :     TBitBtn;
        pnlMainConfig :      TPanel;
        btnSaveConfig :      TBitBtn;
        edtSourceInstall :   TJvDirectoryEdit;
        edtBaseProfile :     TJvDirectoryEdit;
        lblSourceInstall :   TLabel;
        lblInstallPckName :  TLabel;
        edtProfileDate :     TJvDBDatePickerEdit;
        lblProfileDate :     TLabel;
        edtDestionationDir : TJvDirectoryEdit;
        lblDestinationDir :  TLabel;
        btnCancelConfig :    TBitBtn;
        edtMSIName :         TLabeledEdit;
        edtMinSpace :        TLabeledEdit;
        edtMinVersion :      TLabeledEdit;
        procedure btnExecInstallClick(Sender : TObject);
        procedure FormCreate(Sender : TObject);
        procedure btnSaveConfigClick(Sender : TObject);
        procedure btnCancelConfigClick(Sender : TObject);
        procedure edtConfigControlsChange(Sender : TObject);
    private
        { Private declarations }
        procedure ShowSuccess;
        procedure LoadConfigValues;
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

uses FileHnd, boinstDataModule;

{$R *.dfm}

procedure TForm1.btnCancelConfigClick(Sender : TObject);
begin
    Self.LoadConfigValues;
end;

procedure TForm1.btnSaveConfigClick(Sender : TObject);
begin
    config.MinDiskSpace := StrToInt(Self.edtMinSpace.Text);
    config.InstallSourcePath := Self.edtSourceInstall.Text;
    config.BaseProfileSourcePath := Self.edtBaseProfile.Text;
    config.BaseProfileDate := Self.edtProfileDate.Date;
    config.InstallDestination := Self.edtDestionationDir.Text;
    config.InstallPackageName := Self.edtMSIName.Text;
    config.MinVersion := Self.edtMinVersion.Text;

    //Informa que valores foram salvos
    Self.btnSaveConfig.Enabled   := False;
    Self.btnCancelConfig.Enabled := False;
end;

procedure TForm1.btnExecInstallClick(Sender : TObject);
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
                    if (not station.isProfileUpdated) then begin
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

procedure TForm1.edtConfigControlsChange(Sender : TObject);
begin
    Self.btnSaveConfig.Enabled   := True;
    Self.btnCancelConfig.Enabled := True;
end;

procedure TForm1.ShowSuccess;
begin
    MessageDlg('Instalação e atualização de perfil executada com sucesso', mtInformation, [mbOK], 0);
end;

procedure TForm1.FormCreate(Sender : TObject);
var
    x : Integer;
begin
    //Testa o modo automatico, executa e finaliza
    for x := 0 to ParamCount do begin
        if SameText('/auto', ParamStr(x)) then begin
            try
                Self.btnExecInstallClick(nil);
            finally
                Application.ShowMainForm := False;
                Self.Visible := False;
                Application.Terminate;
            end;
            Exit;
        end;
    end;


    {$IFDEF DEBUG}
	Self.Caption:=Self.Caption + ' ***(Debug) ' + FileHnd.TFileHnd.VersionInfo( ParamStr(0) ) + ' ***';
	{$ELSE}
    Self.Caption := Self.Caption + ' ' + FileHnd.TFileHnd.VersionInfo(ParamStr(0));
    {$ENDIF}

    //Carga dos valores de edição
    Self.LoadConfigValues;
end;

procedure TForm1.LoadConfigValues;
begin
    Self.edtSourceInstall.Text := config.InstallSourcePath;
    Self.edtBaseProfile.Text := config.BaseProfileSourcePath;
    Self.edtProfileDate.Date := config.BaseProfileDate;
    Self.edtDestionationDir.Text := config.InstallDestination;
    Self.edtMinSpace.Text   := IntToStr(config.MinDiskSpace);
    Self.edtMSIName.Text    := config.InstallPackageName;
    Self.edtMinVersion.Text := config.MinVersion;
    //Indica valores carregados da persistência
    Self.btnSaveConfig.Enabled := False;
    Self.btnCancelConfig.Enabled := False;
end;

end.
