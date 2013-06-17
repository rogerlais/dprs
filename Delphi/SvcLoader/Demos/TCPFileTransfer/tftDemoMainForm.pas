unit tftDemoMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, Mask, JvExMask, JvToolEdit, ExtCtrls, AppLog;

type
    TForm3 = class(TForm)
        edtDir :          TJvDirectoryEdit;
        chkServerSwitch : TCheckBox;
        lblInputDir :     TLabel;
        edtDirOutput :    TJvDirectoryEdit;
        lblOutDir :       TLabel;
        btnStartStop :    TBitBtn;
        tmrCycle :        TTimer;
        memoLog :         TMemo;
        procedure btnStartStopClick(Sender : TObject);
        procedure FormCreate(Sender : TObject);
        procedure tmrCycleTimer(Sender : TObject);
    private
        { Private declarations }
        FStarted : boolean;
        procedure SetupTCPTransfer();
        procedure StopTCPTransfer();
        procedure SetServiceStarted(startCmd : boolean);
        procedure DoCopyLogMessage(Sender : TObject; var Text : string; MessageType : TLogMessageType; var Canceled : boolean);
    public
        { Public declarations }
    end;

var
    Form3 : TForm3;

implementation

uses
    svclTCPTransfer, svclConfig, XPFileEnumerator, FileHnd, WinNetHnd;

{$R *.dfm}

procedure TForm3.btnStartStopClick(Sender : TObject);
begin
    Self.btnStartStop.Enabled := False;
    try
        Self.SetServiceStarted(not Self.FStarted);
    finally
        Self.btnStartStop.Enabled := True;
    end;
end;


procedure TForm3.DoCopyLogMessage(Sender : TObject; var Text : string; MessageType : TLogMessageType; var Canceled : boolean);
begin
    Self.memoLog.Lines.Add(Text);
    Canceled := False;
end;

procedure TForm3.FormCreate(Sender : TObject);
begin
    Self.chkServerSwitch.Checked := GlobalConfig.isPrimaryComputer;
    Self.edtDir.Directory := GlobalConfig.PathELOBioService;
    Self.edtDirOutput.Directory := GlobalConfig.PathELOTransbioTrans;
    TLogFile.GetDefaultLogFile.OnMessageReceived := Self.DoCopyLogMessage;
     {$IFDEF DEBUG}
    TLogFile.GetDefaultLogFile.DebugLevel := DBGLEVEL_ULTIMATE;
     {$ENDIF}
end;

procedure TForm3.SetServiceStarted(startCmd : boolean);
begin
    if (not startCmd) then begin //Parar serviço         
        Self.btnStartStop.Caption := 'Parando...';
        Self.StopTCPTransfer();
        Self.tmrCycle.Enabled     := False;
        Self.btnStartStop.Caption := '&Iniciar';
        Self.chkServerSwitch.Enabled := True;
    end else begin
        //Iniciar serviço
        Self.btnStartStop.Caption := 'Iniciando...';
        Self.SetupTCPTransfer();
        Self.tmrCycle.Enabled     := True;
        Self.btnStartStop.Caption := '&Parar';
        Self.chkServerSwitch.Enabled := False;
    end;
    Self.FStarted := startCmd;
end;

procedure TForm3.SetupTCPTransfer;
begin
    if (Self.chkServerSwitch.Checked) then begin
        //Operaçao como servidor
        DMTCPTransfer.StartServer();
    end else begin
        //Operação como cliente
        DMTCPTransfer.StartClient;
    end;
end;

procedure TForm3.StopTCPTransfer;
begin
    if (Self.chkServerSwitch.Checked) then begin
        //Operaçao como servidor
        DMTCPTransfer.StopServer();
    end else begin
        //Operação como cliente
        DMTCPTransfer.StopClient;
    end;
end;

procedure TForm3.tmrCycleTimer(Sender : TObject);
var
    FileEnum : IEnumerable<TFileSystemEntry>;
    f :  TFileSystemEntry;
    tf : TTransferFile;
begin
    if (Self.FStarted) then begin
        if (Self.chkServerSwitch.Checked) then begin // Modo Servidor ativo
            {TODO -oroger -cdsg : Organizar os arquivos recebidos }
        end else begin
            //Modo cliente
            if (TFileHnd.FirstOccurrence(Self.edtDir.Directory, '*.bio') = EmptyStr) then begin
                Exit; //Nada a enviar sair do loop
            end;

            //Abrir o socket para envio
            DMTCPTransfer.tcpclnt.Connect;  {TODO -oroger -cdsg : proteger chamada com tratamento correto}
            DMTCPTransfer.tcpclnt.IOHandler.WriteLn(GetComputerName() + STR_BEGIN_SESSION_SIGNATURE);
            FileEnum := TDirectory.FileSystemEntries(Self.edtDir.Directory, '*.bio', True);
            try
                for f in FileEnum do begin
                    if (f.Name <> '.') and (f.Name <> '..') then begin
                        tf := TTransferFile.CreateOutput(f.FullName);
                        try
                            DMTCPTransfer.SendFile(tf);
                        finally
                            tf.Free;
                        end;
                    end;
                end;
            finally
                DMTCPTransfer.tcpclnt.IOHandler.WriteLn(GetComputerName() + STR_END_SESSION_SIGNATURE); //Envia msg de fim de sessão
                DMTCPTransfer.StopClient;
            end;
        end;
    end;
end;

end.
