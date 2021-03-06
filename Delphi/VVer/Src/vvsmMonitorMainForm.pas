{$IFDEF vvsmMonitorMainForm}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
unit vvsmMonitorMainForm;

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
	Dialogs, StdCtrls, ExtCtrls, ComCtrls, Buttons;

type
	TVVMMonitorMainForm = class(TForm)
		btnOK: TBitBtn;
		grdList: TListView;
		pnlLog: TPanel;
		pnlTop: TPanel;
		lblMainLabel: TLabel;
		lblProfLabel: TLabel;
		lblProfile: TLabel;
		lblStatus: TLabel;
		procedure FormCreate(Sender: TObject);
		procedure btnOKClick(Sender: TObject);
		procedure FormActivate(Sender: TObject);
		procedure grdListAdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
			Stage: TCustomDrawStage; var DefaultDraw: boolean);
		procedure grdListClick(Sender: TObject);
		procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
	private
		{ Private declarations }
		FSessionClosure: boolean;
	protected
		procedure WMQueryEndSession(var Msg: TWMQueryEndSession); message WM_QUERYENDSESSION;
	public
		{ Public declarations }
	end;

var
	VVMMonitorMainForm: TVVMMonitorMainForm;

implementation

{$R *.dfm}

uses
	vvsmMainDatamodule, vvConfig, vvProgItem, AppLog, System.UITypes;

procedure TVVMMonitorMainForm.btnOKClick(Sender: TObject);
begin
	Self.Close;
end;

procedure TVVMMonitorMainForm.FormActivate(Sender: TObject);
{ TODO -oroger -cdsg : Recarrega todas as aplica��es }
var
	x      : Integer;
	p      : TProgItem;
	lstCol : TListColumn;
	lstItem: TListItem;
begin
	if not Self.pnlLog.Visible then begin //Visibilidade do painel indica carga de todos os parametros
		{ TODO -oroger -cdsg : Transformar constante em campo dinamico }
		Self.lblStatus.Caption  := 'Carregando informa��es sobre vers�es em:'#13#10 + GlobalInfo.ProfileName;
		Self.lblProfile.Caption := GlobalInfo.ProfileName;
		Self.pnlLog.Refresh;
		Application.ProcessMessages;
		try
			//;;Self.grdList.RowCount  := GlobalInfo.ProfileInfo.Count + 1;
			//;;Self.grdList.ColCount  := 3;
			//;Self.grdList.FixedRows := 1;
			lstCol         := Self.grdList.Columns.Add;
			lstCol.Caption := 'Descri��o';
			lstCol.Width   := ColumnHeaderWidth;
			lstCol         := Self.grdList.Columns.Add;
			lstCol.Caption := 'Vers�o Instalada';
			lstCol.Width   := ColumnHeaderWidth;
			lstCol         := Self.grdList.Columns.Add;
			lstCol.Caption := 'Vers�o Esperada';
			lstCol.Width   := ColumnHeaderWidth;

			TLogfile.LogDebug('Carregando items para exibi��o', DBGLEVEL_ULTIMATE);
			Self.grdList.Items.BeginUpdate;
			try
				if (not Assigned(GlobalInfo.ProfileInfo)) then begin
					raise Exception.Create('Informa��es das vers�es para este perfil n�o puderam ser obtidas');
				end;
				Self.grdList.Items.Clear;
				for x := 1 to GlobalInfo.ProfileInfo.Count do begin
					p := GlobalInfo.ProfileInfo.Programs[x - 1];
					//Atribui��o da exibi��o
					lstItem         := Self.grdList.Items.Add;
					lstItem.Caption := p.Desc;
					lstItem.SubItems.Add(p.CurrentVersionDisplay);
					lstItem.SubItems.Add(p.ExpectedVerEx);
					lstItem.Data := p;
				end;
			finally
				Self.grdList.Items.EndUpdate;
				Self.pnlLog.Visible := False;
			end;
		except
			on E: Exception do begin
				Self.pnlLog.Visible    := True;
				Self.lblStatus.Caption := 'Informa��es de vers�es n�o puderam ser carregadas.'#13#10 + E.Message;
			end;
		end;
	end;
end;

procedure TVVMMonitorMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
	Self.Visible := False;
	CanClose     := Self.FSessionClosure;
end;

procedure TVVMMonitorMainForm.FormCreate(Sender: TObject);
begin
	TThread.CurrentThread.NameThreadForDebugging('MainThread' );
	TLogfile.LogDebug('Carregando perfil para este computador', DBGLEVEL_ULTIMATE);
	Application.Title         := 'VVerMonitor - Verificador de Aplica��es seguras - ' + VVSMMainDM.fvVersion.FileVersion;
	Self.lblMainLabel.Caption := 'SESOP - Verificador de Aplica��es Seguras(SiS)';
	{$IFDEF DEBUG}
	Self.Caption := Self.Caption + ' *** Depura��o ***  - ' + VVSMMainDM.fvVersion.FileVersion;
	{$ELSE}
	Self.Caption := Self.Caption + ' Vers�o: ' + VVSMMainDM.fvVersion.FileVersion;
	{$ENDIF}
	{$WARN SYMBOL_PLATFORM OFF}
	if (System.DebugHook <> 0) then begin
		Self.Show(); { TODO -oroger -cdsg : mostrar acima das outras }
	end;
	{$WARN SYMBOL_PLATFORM ON}
end;

procedure TVVMMonitorMainForm.grdListAdvancedCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState;
	Stage: TCustomDrawStage; var DefaultDraw: boolean);
var
	prg: TProgItem;
begin
	if (Item.Focused or Item.Selected) and (Stage in [cdPreErase, cdPostErase]) then begin
		Sender.Canvas.Brush.Color := clHighlight;
		Sender.Canvas.Font.Color  := clYellow;
	end else begin
		{$WARN UNSAFE_CAST OFF}
		prg := TProgItem(Item.Data);
		{$WARN UNSAFE_CAST ON}
		if Assigned(prg) then begin //pular linhas de cabecalho
			if not prg.isUpdated then begin
				Self.grdList.Canvas.Brush.Color := clRed;
				Self.grdList.Canvas.Font.Color  := clWhite;
			end else begin
				Self.grdList.Canvas.Brush.Color := clGreen;
			end;
		end;
	end;
end;

procedure TVVMMonitorMainForm.grdListClick(Sender: TObject);
begin
	case MessageDlg('Deseja baixar os pacotes do computador prim�rio agora?', mtConfirmation, [mbYes, mbNo], 0) of
		mrYes: begin
				MessageDlg('Esta opera��o pode demorar alguns minutos.'#13#10 + 'Ao final um aviso lhe ser� enviado'#13#10 +
					'Evite desligar o computador durante o processo', mtInformation, [mbOK], 0);
				Self.Visible := False;
				VVSMMainDM.UpdateFiles();
				MessageDlg('Opera��o de c�pia dos pacotes conclu�da.'#13#10 +
					'Efetue a instala��o atrav�s do usu�rio INSTALADOR pelo caminho padr�o', mtInformation, [mbOK], 0);
			end;
	end;

end;

procedure TVVMMonitorMainForm.WMQueryEndSession(var Msg: TWMQueryEndSession);
const
	ABORT_WINDOWS_SHUTDOWN    = 0;
	CONTINUE_WINDOWS_SHUTDOWN = 1;
begin
	Self.FSessionClosure := True;
	Msg.Result           := CONTINUE_WINDOWS_SHUTDOWN;
end;

end.
