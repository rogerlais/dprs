{$IFDEF svclEditConfigForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclEditConfigForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, svclConfig, Mask, JvExMask, JvToolEdit;

type
  TEditConfigForm = class(TForm)
	 pnlBottom: TPanel;
	 btnOk: TBitBtn;
	 btnCancel: TBitBtn;
	 pnlTop: TPanel;
	 chkServerMode: TCheckBox;
	 tbcConfig: TTabControl;
    edtDirCapturePath: TJvDirectoryEdit;
    lblSourceFilePath: TLabel;
  private
	 { Private declarations }
	 procedure LoadConfig();
	 procedure SaveConfig();
  public
	 { Public declarations }
	 class procedure EditConfig;
  end;

var
  EditConfigForm: TEditConfigForm;

implementation

{$R *.dfm}

{ TEditConfigForm }

class procedure TEditConfigForm.EditConfig;
var
	frm : TEditConfigForm;
begin
	Application.CreateForm(  TEditConfigForm, frm  );
	try
		frm.LoadConfig();
		frm.ShowModal();
		if ( frm.ModalResult = mrOk  ) then begin
			frm.SaveConfig();
		end;
	finally
		frm.Free;
	end;
end;

procedure TEditConfigForm.LoadConfig;
begin
	{TODO -oroger -cdsg : Carrega as configurações para os controles}


	 Self.edtDirCapturePath.Text:=GlobalConfig.PathServiceCapture;


{
		 //Atributos privativos da estação
		 property StationLocalTransPath : string read GetStationLocalTransPath;
		 property StationBackupPath : string read GetStationBackupPath;
		 property StationRemoteTransPath : string read GetStationRemoteTransPath;
		 //Atributos privativos do computador primario
		 property PrimaryBackupPath : string read GetPrimaryBackupPath;
		 property PrimaryTransmittedPath : string read GetPrimaryTransmittedPath;
		 //Atributos do servico
		 property NetAccesstPassword : string read GetNetAccountPassword;
		 property EncryptNetAccessPassword : string read GetEncryptNetAccessPassword;
		 property NetAccessUserName : string read GetNetAccessUsername;
		 property CycleInterval : Integer read GetCycleInterval;
		 property ServiceUsername : string read GetServiceUsername;
		 property ServicePassword : string read GetServicePassword;
		 property EncryptServicePassword : string read GetEncryptServicePassword;
		 property NetServicePort : Integer read GetNetServicePort;
		 //Atributos da sessão
		 property isPrimaryComputer : boolean read GetIsPrimaryComputer;
		 property DebugLevel : Integer read GetDebugLevel;
		 property PrimaryComputerName : string read GetPrimaryComputerName;
}


end;

procedure TEditConfigForm.SaveConfig;
begin
	{TODO -oroger -cdsg : Salva as configurações dos controles para o arquivo}
end;

end.
