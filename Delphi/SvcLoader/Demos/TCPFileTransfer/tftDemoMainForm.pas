unit tftDemoMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, Mask, JvExMask, JvToolEdit;

type
    TForm3 = class(TForm)
        edtDir :          TJvDirectoryEdit;
        chkServerSwitch : TCheckBox;
        lblInputDir :     TLabel;
        edtDirOutput :    TJvDirectoryEdit;
        lblOutDir :       TLabel;
        btnStartStop :    TBitBtn;
		 procedure btnStartStopClick(Sender : TObject);
    	procedure FormCreate(Sender: TObject);
	 private
		 { Private declarations }
		 FStarted : boolean;
		 procedure StartTCPTransfer();
    public
        { Public declarations }
    end;

var
    Form3 : TForm3;

implementation

uses
  svclTCPTransfer, svclConfig;

{$R *.dfm}

procedure TForm3.btnStartStopClick(Sender : TObject);
begin
	 Self.btnStartStop.Enabled := False;
	 try
		 if (Self.FStarted) then begin //Parar serviço
			 Self.btnStartStop.Caption := 'Parando...';
			 Self.StartTCPTransfer();
		 end else begin
			//Iniciar serviço
			Self.btnStartStop.Caption := 'Iniciando...';
			Self.StartTCPTransfer();

        end;
    finally
        Self.btnStartStop.Enabled := True;
    end;
end;


procedure TForm3.FormCreate(Sender: TObject);
begin
	Self.edtDir.Directory:=GlobalConfig.StationSourcePath;
	Self.edtDirOutput.Directory:=GlobalConfig.PrimaryTransmittedPath;
end;

procedure TForm3.StartTCPTransfer;
begin
	if ( Self.chkServerSwitch.Checked ) then begin
		//Operaçao como servidor
		DMTCPTransfer.SetupServer();
	end else begin
		//Operação como cliente
		DMTCPTransfer.SetupClient;
	end;
end;

end.
