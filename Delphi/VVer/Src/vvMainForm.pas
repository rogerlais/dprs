{$IFDEF vvMainForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
{$TYPEINFO OFF}

unit vvMainForm;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Grids, EnhGrids, Buttons, vvConfig, IdBaseComponent, IdMailBox, IdComponent,
    IdSMTPBase, IdSMTP, IdMessage,
    FileInfo, IdHTTP, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient, ExtCtrls;

type
    TForm1 = class(TForm)
        btnOK :         TBitBtn;
        grdList :       TEnhStringGrid;
        lblMainLabel :  TLabel;
        btnNotifSESOP : TBitBtn;
        smtpSender :    TIdSMTP;
        mailMsgNotify : TIdMessage;
        fvVersion :     TFileVersionInfo;
        httpLoader :    TIdHTTP;
        pnlLog :        TPanel;
        procedure btnOKClick(Sender : TObject);
        procedure grdListDrawCellGetProperties(Sender : TObject; ACol, ARow : Integer; Rect : TRect; State : TGridDrawState);
        procedure btnNotifSESOPClick(Sender : TObject);
        procedure FormShow(Sender : TObject);
    private
        { Private declarations }
        procedure LoadVersionData();
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

uses
    WinNetHnd, IdEMailAddress;

{$R *.dfm}

const
    COL_DESC  = 0;
    COL_VER   = 1;
    COL_EXPEC = 2;

procedure TForm1.btnNotifSESOPClick(Sender : TObject);
var
    dst : TIdEMailAddressItem;
const
    //Modelo = VVer - Versão <1.0.2010.2> - <ZPB080STD01> - 201009242359 - Pendente';
    SUBJECT_TEMPLATE = 'VVer - Versão: %s - %s - %s - %s';
var
    sbj : string;
begin
    {TODO -oroger -cdsg : Coletar informações de detino de mensagem com possibilidade de macros no mesmo arquivo de configuração}

    Self.mailMsgNotify.ReceiptRecipient.Address := 'sesop@tre-pb.gov.br';
    Self.mailMsgNotify.ReceiptRecipient.Name    := 'SESOP - Verificador de Sistemas Eleitorais';
    Self.mailMsgNotify.ReceiptRecipient.Text    := 'SESOP <sesop@tre-pb.gov.br>';
    Self.mailMsgNotify.ReceiptRecipient.Domain  := 'tre-pb.gov.br';
    Self.mailMsgNotify.ReceiptRecipient.User    := 'sesop';

    dst      := Self.mailMsgNotify.Recipients.Add();
     {$IFDEF DEBUG}
	 dst.Address := 'roger@tre-pb.gov.br';
	 dst.Name := 'agarra essa cara - indy';
	 dst.Text := 'agarra essa cara - indy <roger@tre-pb.gov.br>';
	 dst.Domain := 'tre-pb.gov.br';
	 dst.User := 'roger';
	 {$ELSE}
    dst.Address := 'sesop@tre-pb.gov.br';
    dst.Name := 'SESOP - Verificador de Sistemas eleitorais';
    dst.Text := 'Verificador de Sistemas Eleitorais<sesop@tre-pb.gov.br>';
    dst.Domain := 'tre-pb.gov.br';
    dst.User := 'sesop';
     {$ENDIF}




    sbj := Format(SUBJECT_TEMPLATE, [Self.fvVersion.FileVersion, WinNetHnd.GetComputerName(),
        FormatDateTime('yyyyMMDDhhmm', Now()), GlobalInfo.GlobalStatus]);
    Self.mailMsgNotify.Body.Text := GlobalInfo.InfoText;
    Self.mailMsgNotify.Subject := sbj;
    Self.smtpSender.Connect;
    Self.smtpSender.Send(Self.mailMsgNotify);
    Self.smtpSender.Disconnect(True);
end;

procedure TForm1.btnOKClick(Sender : TObject);
begin
    Self.Close;
end;

procedure TForm1.FormShow(Sender : TObject);
var
    x : Integer;
    p : TProgItem;
begin
	 if not Self.pnlLog.Visible then begin

		 Self.pnlLog.Caption := 'Carregando informações sobre versões em:'#13#10 + VERSION_URL_FILE;
		 Self.pnlLog.Refresh;
		 Application.ProcessMessages;

		 try
			 Self.LoadVersionData();

			 {TODO -oroger -cdsg : Carregar arquivo de configuração via url}
			 Self.grdList.RowCount  := GlobalInfo.ProgCount + 1;
			 Self.grdList.ColCount  := 3;
			 Self.grdList.FixedRows := 1;
			 Self.grdList.Cells[COL_DESC, 0] := 'Descrição';
			 Self.grdList.Cells[COL_VER, 0] := 'Versão Instalada';
			 Self.grdList.Cells[COL_EXPEC, 0] := 'Versão Esperada';
			 for x := 1 to GlobalInfo.ProgCount do begin
				 p := GlobalInfo.Items[x - 1];
				 //Atribuição da exibição
				 Self.grdList.Cells[COL_DESC, x] := p.Desc;
				 Self.grdList.Cells[COL_VER, x] := p.CurrentVersion;
				 Self.grdList.Cells[COL_EXPEC, x] := p.ExpectedVerEx;
				 //Atibuição dos objetos
				 Self.grdList.Objects[COL_DESC, x] := p;
				 Self.grdList.Objects[COL_VER, x] := p;
				 Self.grdList.Objects[COL_EXPEC, x] := p;
			 end;
		 finally
			 Self.pnlLog.Visible := False;
		 end;
	 end;
end;

procedure TForm1.grdListDrawCellGetProperties(Sender : TObject; ACol, ARow : Integer; Rect : TRect; State : TGridDrawState);
var
	 prg : TProgItem;
begin
    prg := TProgItem(Self.grdList.Objects[ACol, ARow]);
    if Assigned(prg) then begin //pular linhas de cabecalho
        if prg.isUpdated then begin
            if (gdFocused in State) or (Self.grdList.RowCount = ARow) then begin
                Self.grdList.Canvas.DrawFocusRect(Rect);
            end else begin
                Self.grdList.Canvas.Brush.Color := clGreen;
                Self.grdList.Canvas.FillRect(Rect);
            end;
        end else begin
            if (gdFocused in State) or (Self.grdList.RowCount = ARow) then begin
                Self.grdList.Canvas.DrawFocusRect(Rect);
            end else begin
                Self.grdList.Canvas.Brush.Color := clRed;
                Self.grdList.Canvas.FillRect(Rect);
            end;
        end;
    end;
end;

procedure TForm1.LoadVersionData;
var
    MemStream :  TMemoryStream;
    FileStream : TFileStream;
    fname :      string;
begin
    {TODO -oroger -cdsg : Baixar arquivo de configuração}
    MemStream := TMemoryStream.Create;
    try
        Self.httpLoader.Get(VERSION_URL_FILE, MemStream);
        MemStream.Position := 0;
        fname      := ExtractFilePath(ParamStr(0)) + 'VVer.ini';
        FileStream := TFileStream.Create(fname, fmCreate);
        try
            MemStream.SaveToStream(FileStream);
        finally
            FileStream.Free;
        end;
    finally
        MemStream.Free;
    end;
    LoadGlobalInfo(fname);
end;

end.
