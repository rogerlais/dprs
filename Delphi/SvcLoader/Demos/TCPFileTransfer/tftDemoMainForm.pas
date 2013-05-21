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
        procedure StartTCPTransfer();
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
    svclTCPTransfer, svclConfig, XPFileEnumerator;

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
    Self.edtDir.Directory := GlobalConfig.StationSourcePath;
    Self.edtDirOutput.Directory := GlobalConfig.PrimaryTransmittedPath;
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
        Self.StartTCPTransfer();
        Self.tmrCycle.Enabled     := True;
        Self.btnStartStop.Caption := '&Parar';
        Self.chkServerSwitch.Enabled := False;
    end;
    Self.FStarted := startCmd;
end;

procedure TForm3.StartTCPTransfer;
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
    lastClientState : boolean;
begin
    if (Self.FStarted) then begin
        if (Self.chkServerSwitch.Checked) then begin // Modo Servidor ativo
            {TODO -oroger -cdsg : Organizar os arquivos recebidos }
        end else begin
            //Modo cliente
            {TODO -oroger -cdsg : Abrir o socket para envio}
            FileEnum := TDirectory.FileSystemEntries(Self.edtDir.Directory, '*.bio', True);
            lastClientState := DMTCPTransfer.tcpclnt.Connected;
            try
                if (not DMTCPTransfer.tcpclnt.Connected) then begin
                    DMTCPTransfer.tcpclnt.Connect;
                end;
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
                if (not lastClientState) then begin
                    DMTCPTransfer.tcpclnt.Disconnect;
                end;
            end;
        end;
    end;
end;

end.
