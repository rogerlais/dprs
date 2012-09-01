unit mrfMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, uDiskEjectConst, uDriveEjector, magfmtdisk, mrfConfiguration;

type
  TAppMainForm = class(TForm)
	 pnlTop: TPanel;
	 btnConfig: TBitBtn;
	 btnStart: TBitBtn;
	 btnClose: TBitBtn;
	 lblStatus: TLabel;
	 memoVerbose: TMemo;
	 stBar: TStatusBar;
	 procedure FormCreate(Sender: TObject);
	 procedure btnCloseClick(Sender: TObject);
	 procedure btnConfigClick(Sender: TObject);
	 procedure btnStartClick(Sender: TObject);
	 procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
	 { Private declarations }
	 FDevEjector : TDriveEjector;
	 FDevFormatter : TMagFmtChkDsk;
    FMonitoring: boolean;
	 procedure DoDevicesChanged( Sender: TObject);
	 procedure DoFormatProgress(Percent : Integer; var Cancel : boolean);
	 procedure DoFormatInfoUpdate( Info : string; var Cancel : boolean);
    procedure SetMonitoring(const Value: boolean);
  public
	 { Public declarations }
	 property Monitoring : boolean read FMonitoring write SetMonitoring;
  end;

var
  AppMainForm: TAppMainForm;

implementation

uses
  FileHnd;

{$R *.dfm}

procedure TAppMainForm.btnCloseClick(Sender: TObject);
begin
	Self.Close;
end;

procedure TAppMainForm.btnConfigClick(Sender: TObject);
begin
	{TODO -oroger -croger : chamar janela de configuracao}
end;

procedure TAppMainForm.btnStartClick(Sender: TObject);
begin
	{TODO -oroger -cdsg : Iniciar monitoração e desabilitar demais controles, clicando novamente para monitoracao e reabilita controles}
	Self.Monitoring:=not Self.Monitoring;
end;

procedure TAppMainForm.DoDevicesChanged(Sender: TObject);
var
	x : Integer;
	drv : TRemovableDrive;
begin
	{TODO -oroger -cdsg : Compara a lista original com a presente, iniciando a formatação caso obedeca as regras}
	for x  := 0 to Length(Self.FDevEjector.RemovableDrives) - 1 do begin
		drv := Self.FDevEjector.RemovableDrives[x];
		Self.memoVerbose.Lines.Add( drv.DriveMountPoint );
   end;
end;

procedure TAppMainForm.DoFormatInfoUpdate(Info: string; var Cancel: boolean);
begin
	{TODO -oroger -cdsg : Ajusta a barra de status}
	Cancel:=False;
end;

procedure TAppMainForm.DoFormatProgress(Percent: Integer; var Cancel: boolean);
begin
	{TODO -oroger -cdsg : Ajusta a ultima linha de exibicao para refletir a situa~çao atual}
	Cancel:=False;
end;

procedure TAppMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
	CanClose:=not Self.Monitoring;
end;

procedure TAppMainForm.FormCreate(Sender: TObject);
begin
	{$IFDEF DEBUG}
	Self.Caption:='*** Formatador(MRs) - Versão DEPURAÇÂO: %s ***';
	{$ELSE}
	Self.Caption:='Formatador(MRs) - Versão: %s' +
	{$ENDIF}
	Self.Caption:=Format( Self.Caption , [ TFileHnd.VersionInfo( ParamStr( 0 ) ) ] );

	//Componentes em runtime
	Self.FDevEjector := TDriveEjector.Create();
	Self.FDevEjector.CardPolling:=True;
	Self.FDevEjector.CardPollingInterval:=1000;
	Self.FDevFormatter := TMagFmtChkDsk.Create( Self );
end;

procedure TAppMainForm.FormDestroy(Sender: TObject);
begin
	Self.FDevEjector.Free;
end;

procedure TAppMainForm.SetMonitoring(const Value: boolean);
begin
	FMonitoring := Value;
	if ( Self.FMonitoring ) then begin
		//Liga monitores
		Self.FDevEjector.OnDrivesChanged:=Self.DoDevicesChanged;
		Self.FDevFormatter.onProgressEvent:=Self.DoFormatProgress;
		Self.FDevFormatter.onInfoEvent:=Self.DoFormatInfoUpdate;
		//Desliga controles de açao diversas
		Self.btnConfig.Enabled:=False;
		Self.btnClose.Enabled:=False;
		Self.btnStart.Caption:='&Parar';

		//Realiza a varredura
		Self.FDevEjector.RescanAllDrives;
	end else begin
		//Desliga monitores
		Self.FDevEjector.OnDrivesChanged:=nil;
		Self.FDevFormatter.onProgressEvent:=nil;
		Self.FDevFormatter.onInfoEvent:=nil;
		//Liga controles de açao diversas
		Self.btnConfig.Enabled:=True;
		Self.btnClose.Enabled:=True;
		Self.btnStart.Caption:='&Iniciar';
	end;
end;

end.
