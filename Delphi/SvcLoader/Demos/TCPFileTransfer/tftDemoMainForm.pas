{$IFDEF tftDemoMainForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I ..\..\Src\SvcLoader.inc}

unit tftDemoMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, Mask, JvExMask, JvToolEdit, ExtCtrls, AppLog, svclTransBio;

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
        procedure tmrCycleTimer2(Sender : TObject);
        procedure chkServerSwitchClick(Sender : TObject);
    procedure tmrCycleTimer(Sender: TObject);
    private
        { Private declarations }
        FStarted :      boolean;
        FClientThread : TTransBioThread;
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
	 svclTCPTransfer, svclConfig, XPFileEnumerator, FileHnd, WinNetHnd, svclBiometricFiles;

{$R *.dfm}

procedure TForm3.btnStartStopClick(Sender : TObject);
var
	 ret : boolean;
begin
	 Self.btnStartStop.Enabled := False;
	 try
		 if (GlobalConfig.RunAsServer) then begin //modo servidor
			 Self.SetServiceStarted(not Self.FStarted);
		 end else begin  //modo cliente
			 ret := False;
			 BioFilesService.ServiceStart(BioFilesService, ret);
			 BioFilesService.TimeCycleEvent();
			 Self.tmrCycle.Enabled := True;
		 end;
	 finally
		 Self.btnStartStop.Enabled := True;
	 end;
end;


procedure TForm3.chkServerSwitchClick(Sender : TObject);
begin
    Self.edtDir.Enabled      := not Self.chkServerSwitch.Checked;
    GlobalConfig.RunAsServer := Self.chkServerSwitch.Checked;
end;

procedure TForm3.DoCopyLogMessage(Sender : TObject; var Text : string; MessageType : TLogMessageType; var Canceled : boolean);
begin
    Self.memoLog.Lines.Add(Text);
    Canceled := False;
end;

procedure TForm3.FormCreate(Sender : TObject);
begin
    Self.chkServerSwitch.Checked := GlobalConfig.RunAsServer;
    Self.edtDir.Directory := GlobalConfig.PathClientBioService;
    Self.edtDirOutput.Directory := GlobalConfig.PathServerTransBio;
    TLogFile.GetDefaultLogFile.OnMessageReceived := Self.DoCopyLogMessage;
     {$IFDEF DEBUG}
    TLogFile.GetDefaultLogFile.DebugLevel := DBGLEVEL_ULTIMATE;
      {$ENDIF}
    Self.chkServerSwitchClick(Self);
end;

procedure TForm3.SetServiceStarted(startCmd : boolean);
begin
    if (not startCmd) then begin //Parar serviço
        Self.btnStartStop.Caption := 'Parando...';
        try
            Self.StopTCPTransfer();
        finally
            Self.tmrCycle.Enabled     := False;
            Self.btnStartStop.Caption := '&Iniciar';
            Self.chkServerSwitch.Enabled := True;
        end;
    end else begin
        //Iniciar serviço
        Self.btnStartStop.Caption := 'Iniciando...';
        try
            Self.SetupTCPTransfer();
        finally
            Self.tmrCycle.Enabled     := True;
            Self.btnStartStop.Caption := '&Parar';
            Self.chkServerSwitch.Enabled := False;
        end;
    end;
    Self.FStarted := startCmd;
end;

procedure TForm3.SetupTCPTransfer;
begin
    if (GlobalConfig.RunAsServer) then begin
        //Operaçao como servidor
        DMTCPTransfer.StartServer();
    end else begin
        //Operação como cliente
        DMTCPTransfer.StartClient;
    end;
end;

procedure TForm3.StopTCPTransfer;
begin
    if (GlobalConfig.RunAsServer) then begin
        //Operaçao como servidor
        DMTCPTransfer.StopServer();
    end else begin
        //Operação como cliente
        DMTCPTransfer.StopClient;
    end;
end;

procedure TForm3.tmrCycleTimer(Sender: TObject);
begin
   //codigo original para tmrCycleTimer2(Sender : TObject);
	BioFilesService.TimeCycleEvent();
end;

procedure TForm3.tmrCycleTimer2(Sender : TObject);
var
    FileEnum : IEnumerable<TFileSystemEntry>;
    f :  TFileSystemEntry;
    tf : TTransferFile;
begin
    if (Self.FStarted) then begin
        if (GlobalConfig.RunAsServer) then begin // Modo Servidor ativo
            {TODO -oroger -cdsg : Organizar os arquivos recebidos }
        end else begin
			 if (Assigned(Self.FClientThread) and ( Self.FClientThread.Suspended ) )then begin
				 Self.FClientThread.Start;
            end;
             {
             //Modo cliente
             if (TFileHnd.FirstOccurrence(Self.edtDir.Directory, '*.bio') = EmptyStr) then begin
                 Exit; //Nada a enviar sair do loop
             end;

             //Abrir o socket para envio
             DMTCPTransfer.tcpclnt.Connect;
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
                 DMTCPTransfer.tcpclnt.IOHandler.WriteLn(GetComputerName() + STR_END_SESSION_SIGNATURE);
                 //Envia msg de fim de sessão
                 DMTCPTransfer.StopClient;
             end;
             }
        end;
    end;
end;

end.
