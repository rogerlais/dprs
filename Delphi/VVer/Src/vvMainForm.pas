{$IFDEF vvMainForm}
     {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
{$TYPEINFO OFF}

unit vvMainForm;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Grids, EnhGrids, Buttons, vvConfig, IdBaseComponent, IdComponent,
    FileInfo, ExtCtrls, ComCtrls;

type
    TForm1 = class(TForm)
        btnOK :         TBitBtn;
        grdList :       TListView;
        btnNotifSESOP : TBitBtn;
        pnlLog :        TPanel;
        pnlTop :        TPanel;
        lblMainLabel :  TLabel;
        lblProfLabel :  TLabel;
        lblProfile :    TLabel;
        procedure btnOKClick(Sender : TObject);
        procedure btnNotifSESOPClick(Sender : TObject);
        procedure FormShow(Sender : TObject);
        procedure FormCreate(Sender : TObject);
        procedure FormCloseQuery(Sender : TObject; var CanClose : boolean);
        procedure grdListDblClick(Sender : TObject);
        procedure grdListAdvancedCustomDrawItem(Sender : TCustomListView; Item : TListItem; State : TCustomDrawState;
            Stage : TCustomDrawStage; var DefaultDraw : boolean);
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

uses
    WinNetHnd, FileHnd, vvMainDataModule, AppLog, ShellAPI, CommCtrl;

{$R *.dfm}

const
    COL_DESC  = 0;
    COL_VER   = 1;
    COL_EXPEC = 2;

procedure TForm1.btnNotifSESOPClick(Sender : TObject);
begin
    Self.btnNotifSESOP.Enabled := False;
    dtmdMain.SendNotification();
    if Sender <> nil then begin
        MessageDlg('Notificação enviada com sucesso!!', mtInformation, [mbOK], 0);
    end;
end;

procedure TForm1.btnOKClick(Sender : TObject);
begin
    Self.Close;
end;

procedure TForm1.FormCloseQuery(Sender : TObject; var CanClose : boolean);
begin
    if Self.btnNotifSESOP.Enabled and GlobalInfo.EnsureNotification then begin
        //para o caso da notificação ser desejada, mas não enviada
        Self.btnNotifSESOPClick(nil); //Passa Sender nulo para não informar do sucesso do envio
    end;
end;

procedure TForm1.FormCreate(Sender : TObject);
begin
    Application.Title := 'VVer - Verificador de sistemas 2012 - T1';
    Self.lblMainLabel.Caption := 'SESOP - Verificador de Versões de Sistemas 2012 - T1';
    {$IFDEF DEBUG}
    Self.Caption      := 'Verificador de Versões 2012-T1 *** Depuração ***  - ' + dtmdMain.fvVersion.FileVersion;
    {$ELSE}
    Self.Caption      := 'Verificador de Versões 2012-T1 Versão: ' + dtmdMain.fvVersion.FileVersion;
    {$ENDIF}
end;

procedure TForm1.FormShow(Sender : TObject);
var
    x :      Integer;
    p :      TProgItem;
    lstCol : TListColumn;
    lstItem : TListItem;
begin
    if not Self.pnlLog.Visible then begin //Visibilidade do painel indica carga de todos os parametros

        Self.pnlLog.Caption := 'Carregando informações sobre versões em:'#13#10 + VERSION_URL_FILE;
        Self.pnlLog.Refresh;
        Application.ProcessMessages;
        try
            try
                dtmdMain.InitInfoVersions();
                Self.lblProfile.Caption := GlobalInfo.ProfileName;
            except
                on E : Exception do begin
                    AppFatalError('Erro carregando informações de controle de versões'#13#10 + E.Message);
                    Exit;
                end;
            end;

            //;;Self.grdList.RowCount  := GlobalInfo.ProfileInfo.Count + 1;
            //;;Self.grdList.ColCount  := 3;
            //;Self.grdList.FixedRows := 1;
            lstCol := Self.grdList.Columns.Add;
            lstCol.Caption := 'Descrição';
            lstCol.Width := ColumnHeaderWidth;
            lstCol := Self.grdList.Columns.Add;
            lstCol.Caption := 'Versão Instalada';
            lstCol.Width := ColumnHeaderWidth;
            lstCol := Self.grdList.Columns.Add;
            lstCol.Caption := 'Versão Esperada';
            lstCol.Width := ColumnHeaderWidth;

            for x := 1 to GlobalInfo.ProfileInfo.Count do begin
                p := GlobalInfo.ProfileInfo.Programs[x - 1];
                //Atribuição da exibição
                lstItem := Self.grdList.Items.Add;
                lstItem.Caption := p.Desc;
                lstItem.SubItems.Add(p.CurrentVersionDisplay);
                lstItem.SubItems.Add(p.ExpectedVerEx);
                lstItem.Data := p;
            end;
        finally
            Self.pnlLog.Visible := False;
        end;
    end;
end;

procedure TForm1.grdListDblClick(Sender : TObject);
var
    prg : TProgItem;
begin
    { TODO -oroger -cdsg : Dispara navegador com a url carregada para download }
    if (Assigned(Self.grdList.Selected)) then begin
        prg := TProgItem(Self.grdList.Selected.Data);
        if Assigned(prg) then begin //pular linhas de cabecalho
            if ((not prg.isUpdated) and (prg.DownloadURL <> EmptyStr)) then begin
                ShellAPI.ShellExecute(self.WindowHandle, 'open', PChar(prg.DownloadURL), nil, nil, SW_SHOWNORMAL);
            end;
        end;
    end;
end;

procedure TForm1.grdListAdvancedCustomDrawItem(Sender : TCustomListView; Item : TListItem; State : TCustomDrawState;
    Stage : TCustomDrawStage; var DefaultDraw : boolean);
var
	 prg : TProgItem;
begin
	 if (Item.Focused or Item.Selected) and (Stage in [cdPreErase, cdPostErase]) then begin
		 Sender.Canvas.Brush.Color := clHighlight;
		 Sender.Canvas.Font.Color := clYellow;
	 end else begin
        prg := TProgItem(Item.Data);
        if Assigned(prg) then begin //pular linhas de cabecalho
            if not prg.isUpdated then begin
                Self.grdList.Canvas.Brush.Color := clRed;
            end;
        end;
    end;
end;


end.
