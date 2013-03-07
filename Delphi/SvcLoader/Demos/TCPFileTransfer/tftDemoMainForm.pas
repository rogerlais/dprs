unit tftDemoMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, Mask, JvExMask, JvToolEdit, ExtCtrls;

type
    TForm3 = class(TForm)
        edtDir :          TJvDirectoryEdit;
        chkServerSwitch : TCheckBox;
        lblInputDir :     TLabel;
        edtDirOutput :    TJvDirectoryEdit;
        lblOutDir :       TLabel;
        btnStartStop :    TBitBtn;
        tmrCycle :        TTimer;
        procedure btnStartStopClick(Sender : TObject);
        procedure FormCreate(Sender : TObject);
        procedure tmrCycleTimer(Sender : TObject);
    private
        { Private declarations }
        FStarted : boolean;
        procedure StartTCPTransfer();
        procedure SetServiceStarted(startCmd : boolean);
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


procedure TForm3.FormCreate(Sender : TObject);
begin
    Self.chkServerSwitch.Checked := GlobalConfig.isPrimaryComputer;
    Self.edtDir.Directory := GlobalConfig.StationSourcePath;
    Self.edtDirOutput.Directory := GlobalConfig.PrimaryTransmittedPath;
end;

procedure TForm3.SetServiceStarted(startCmd : boolean);
begin
    if (not startCmd) then begin //Parar serviço         
        Self.btnStartStop.Caption := 'Parando...';
        Self.StartTCPTransfer();
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
        DMTCPTransfer.SetupServer();
    end else begin
        //Operação como cliente
        DMTCPTransfer.SetupClient;
    end;
end;

procedure TForm3.tmrCycleTimer(Sender : TObject);
var
    FileEnum : IEnumerable<TFileSystemEntry>;
    f :  TFileSystemEntry;
    tf : TTransferFile;
begin
    if (Self.FStarted) then begin
        FileEnum := TDirectory.FileSystemEntries(Self.edtDir.Directory, '*.bio', True);
        for f in FileEnum do begin
            if (f.Name <> '.') and (f.Name <> '..') then begin
                tf := TTransferFile.Create();
                try
                    tf.Filename := f.FullName;
                    DMTCPTransfer.SendFile(tf);
                finally
                    tf.Free;
                end;
            end;
        end;
    end;
end;

end.
