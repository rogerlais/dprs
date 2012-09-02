unit mrfMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, uDiskEjectConst, uDriveEjector, magfmtdisk,
    mrfConfiguration, Generics.Collections;

type

    TAppMainForm = class(TForm)
        pnlTop :      TPanel;
        btnConfig :   TBitBtn;
        btnStart :    TBitBtn;
        btnClose :    TBitBtn;
        lblStatus :   TLabel;
        memoVerbose : TMemo;
        stBar :       TStatusBar;
        procedure FormCreate(Sender : TObject);
        procedure btnCloseClick(Sender : TObject);
        procedure btnConfigClick(Sender : TObject);
        procedure btnStartClick(Sender : TObject);
        procedure FormDestroy(Sender : TObject);
        procedure FormCloseQuery(Sender : TObject; var CanClose : boolean);
        procedure FormShow(Sender : TObject);
        procedure FormClose(Sender : TObject; var Action : TCloseAction);
    private
        { Private declarations }
        FDevEjector :         TDriveEjector;
        FDevFormatter :       TMagFmtChkDsk;
        FMonitoring :         boolean;
        FFormatFlag :         Integer;
        FSessionDeviceCount : Integer;
        procedure DoDevicesChanged(Sender : TObject);
        procedure DoDevicesUnplugged(Sender : TObject);
        procedure DoFormatProgress(Percent : Integer; var Cancel : boolean);
        procedure DoFormatInfoUpdate(Info : string; var Cancel : boolean);
        procedure SetMonitoring(const Value : boolean);
        procedure ProcessDrive(ADrive : TRemovableDrive);
    public
        { Public declarations }
        property Monitoring : boolean read FMonitoring write SetMonitoring;
    end;

var
    AppMainForm : TAppMainForm;

implementation

uses
    FileHnd, StrHnd;

{$R *.dfm}

procedure TAppMainForm.btnCloseClick(Sender : TObject);
begin
    Self.Close;
end;

procedure TAppMainForm.btnConfigClick(Sender : TObject);
begin
    {TODO -oroger -croger : chamar janela de configuracao}
end;

procedure TAppMainForm.btnStartClick(Sender : TObject);
begin
    {TODO -oroger -cdsg : Iniciar monitoração e desabilitar demais controles, clicando novamente para monitoracao e reabilita controles}
    Self.FFormatFlag := 1;
    Self.Monitoring  := not Self.Monitoring;
end;

procedure TAppMainForm.DoDevicesChanged(Sender : TObject);
var
    x :   Integer;
    drv : TRemovableDrive;
begin
    {TODO -oroger -cdsg : Compara a lista original com a presente, iniciando a formatação caso obedeca as regras}
    for x := 0 to Length(Self.FDevEjector.RemovableDrives) - 1 do begin
        drv := Self.FDevEjector.RemovableDrives[x];
        if (GlobalConfig.CheckSignatureList(drv.ProductID)) then begin
            Self.ProcessDrive(drv);
        end else begin
            MessageBoxW(0,
                PChar(Format('Dispositivo %s não pertence a lista de dispositivos permitidos',
                [drv.ProductID])), PWideChar(Error), MB_OK + MB_ICONSTOP + MB_TOPMOST);
        end;
    end;
end;

procedure TAppMainForm.DoDevicesUnplugged(Sender : TObject);
begin
    if (Self.FDevEjector.DrivesCount <= 0) then begin
        if (Self.FFormatFlag mod 3 = 0) then begin
            Self.FFormatFlag := 1;
            Self.memoVerbose.Lines.Add('Insira novo dispositivo...');
        end else begin
            Inc(Self.FFormatFlag);
        end;
    end;
end;

procedure TAppMainForm.DoFormatInfoUpdate(Info : string; var Cancel : boolean);
begin
    {TODO -oroger -cdsg : Ajusta a barra de status}
    Cancel := False;
    Self.memoVerbose.Lines.Add(Info);
end;

procedure TAppMainForm.DoFormatProgress(Percent : Integer; var Cancel : boolean);
const
    INIT_LINE = 'Percentual formatação: ';
var
    s : string;
begin
    {TODO -oroger -cdsg : Ajusta a ultima linha de exibicao para refletir a situa~çao atual}
    Cancel := False;
    s      := Self.memoVerbose.Lines.Strings[Self.memoVerbose.Lines.Count - 1];
    if (TStrHnd.startsWith(s, INIT_LINE)) then begin
        Self.memoVerbose.Lines.Strings[Self.memoVerbose.Lines.Count - 1] := INIT_LINE + Format('%d', [Percent]);
    end else begin
        Self.memoVerbose.Lines.Add(INIT_LINE + Format('%d', [Percent]));
    end;
end;

procedure TAppMainForm.FormClose(Sender : TObject; var Action : TCloseAction);
var
    logName : string;
begin
    logName := TFileHnd.ConcatPath([ExtractFilePath(ParamStr(0)), 'Logs', FormatDateTime('YYYYMMDDHHmmss', Now())]) + '.log';
    ForceDirectories(ExtractFilePath(logName));
    Self.memoVerbose.Lines.SaveToFile(logName);
end;

procedure TAppMainForm.FormCloseQuery(Sender : TObject; var CanClose : boolean);
begin
    CanClose := not Self.Monitoring;
end;

procedure TAppMainForm.FormCreate(Sender : TObject);
var
    s : string;
begin
    {$IFDEF DEBUG}
    s := '*** Formatador(MRs) - Versão DEPURAÇÂO: %s ***';
    {$ELSE}
    s := 'Formatador(MRs) - Versão: %s';
    {$ENDIF}
    Self.Caption := Format(s, [TFileHnd.VersionInfo(ParamStr(0))]);

    //Componentes em runtime
    Self.FDevEjector   := TDriveEjector.Create();
    Self.FDevEjector.CardPolling := True;
    Self.FDevEjector.CardPollingInterval := 1000;
    Self.FDevFormatter := TMagFmtChkDsk.Create(Self);

    Self.FFormatFlag := 1;
end;

procedure TAppMainForm.FormDestroy(Sender : TObject);
begin
    Self.FDevEjector.Free;
end;

procedure TAppMainForm.FormShow(Sender : TObject);
begin
    {TODO -oroger -cdsg : Verificar /auto para iniciara a monitoração diretamente }
    if (SysUtils.FindCmdLineSwitch('AUTO', ['/'], True)) then begin
        Self.btnStartClick(Self);
    end;
end;

procedure TAppMainForm.ProcessDrive(ADrive : TRemovableDrive);
var
    ECode : Integer;
begin
    {TODO -oroger -cdsg : Registra o evento de nova unidade inserida, formata e ejeta}
    Self.FFormatFlag := -1;
    try
        try
            Self.memoVerbose.Lines.Add(
                Format('Detectado dispositivo (%S) na unidade %s'#13#10
                + 'iniciando formatação...', [ADrive.ProductID, ADrive.DriveMountPoint]));
            try
		   {$IFDEF DEBUG}
				 if ( not Self.FDevFormatter.FormatDisk(ADrive.DriveMountPoint, mtRemovable, fsFAT32, 'JE_DEBUG', False, 0) ) then begin
					raise Exception.Create('Falha de midia');
				 end;
		   {$ELSE}
			   if ( not Self.FDevFormatter.FormatDisk(ADrive.DriveMountPoint, mtRemovable, fsFAT32, 'JE', False, 0) ) then begin
					raise Exception.Create('Falha de midia');
			   end;
		   {$ENDIF}
			 finally
                Self.FDevEjector.RemoveDrive(ADrive.DriveMountPoint, ECode, False, False, False, False);
            end;
            Inc(Self.FSessionDeviceCount);
            Self.stBar.Panels[0].Text := 'Contador = ' + IntToStr(Self.FSessionDeviceCount);

            Self.memoVerbose.Lines.Add('Remova o dispositivo....');
            MessageBeep(MB_ICONASTERISK);
            Self.FDevEjector.RescanAllDrives;

        finally
            Self.FFormatFlag := 1;
        end;
    except
        on E : Exception do begin
            MessageBoxW(0, 'Mídia falhou - Procure o responsável pelo processo!', PWideChar(Error), MB_OK + MB_ICONSTOP + MB_TOPMOST);
        end;
    end;
end;

procedure TAppMainForm.SetMonitoring(const Value : boolean);
begin
    FMonitoring := Value;
    if (Self.FMonitoring) then begin
        //Liga monitores
        Self.FDevEjector.OnDrivesChanged := Self.DoDevicesChanged;
        Self.FDevEjector.OnDeviceUnplugged := Self.DoDevicesUnplugged;
        Self.FDevFormatter.onProgressEvent := Self.DoFormatProgress;
        Self.FDevFormatter.onInfoEvent := Self.DoFormatInfoUpdate;
        //Desliga controles de açao diversas
        Self.btnConfig.Enabled := False;
        Self.btnClose.Enabled  := False;
        Self.btnStart.Caption  := '&Parar';

        //Realiza a varredura
        Self.FDevEjector.RescanAllDrives;
    end else begin
        //Desliga monitores
        Self.FDevEjector.OnDrivesChanged := nil;
        Self.FDevFormatter.onProgressEvent := nil;
        Self.FDevFormatter.onInfoEvent := nil;
        //Liga controles de açao diversas
        Self.btnConfig.Enabled := False;  {TODO -oroger -cdsg : Habilitar apos gerada a janela de configuração}
        Self.btnClose.Enabled  := True;
        Self.btnStart.Caption  := '&Iniciar';
    end;
end;

end.
