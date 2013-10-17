{$IFDEF svclEditConfigForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclEditConfigForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, svclConfig, Mask, JvToolEdit, Spin, JvExMask;

type
    TEditConfigForm = class(TForm)
        pnlBottom :       TPanel;
        btnOk :           TBitBtn;
        btnCancel :       TBitBtn;
        pnlTop :          TPanel;
        chkServerMode :   TCheckBox;
        tbcConfig :       TPageControl;
        tsClientConfig :  TTabSheet;
        tsServerConfig :  TTabSheet;
        lblClientSourceBioService : TLabel;
        edtDirClientBioServicePath : TJvDirectoryEdit;
        edtDirClientTransBioTrans : TJvDirectoryEdit;
        lblClientTransBioTrans : TLabel;
        edtDirClientTransBioRetrans : TJvDirectoryEdit;
        lblClientTransBioRetrans : TLabel;
        edtDirClientTransBioError : TJvDirectoryEdit;
        lblClientTransBioError : TLabel;
        edtDirClientELO2TransBioBio : TJvDirectoryEdit;
        lblClientELO2TransBio : TLabel;
        lblClientServername : TLabel;
        edtClientServername : TEdit;
        tsCommon :        TTabSheet;
        edtTCPPort :      TSpinEdit;
        lblTCPPort :      TLabel;
        edtNotificationList : TEdit;
        lblNotificationList : TLabel;
        seClientTimeInterval : TSpinEdit;
        lblClientTimeInterval : TLabel;
        edtEmailEmitter : TEdit;
        lblEmailEmitter : TLabel;
        lblServerPathPrimaryBackup : TLabel;
        lblServerPathOrderlyBackup : TLabel;
        edtDirServerPathTransBio : TJvDirectoryEdit;
        edtDirServerPathOrderlyBackup : TJvDirectoryEdit;
        edtfTransBioConfigFile : TJvFilenameEdit;
        lblTransBioConfigFile : TLabel;
        lblClientPathFullyBackup : TLabel;
        lblClientPathOrderedBackup : TLabel;
        edtDirClientPathFullyBackup : TJvDirectoryEdit;
        edtDirClientPathOrderedBackup : TJvDirectoryEdit;
        edtDirServerPathFullyBackup : TJvDirectoryEdit;
        lbledtDirServerPathFullyBackup : TLabel;
        seDebugLevel :    TSpinEdit;
        lblDebugLevel :   TLabel;
    private
        { Private declarations }
        procedure LoadConfig();
        procedure SaveConfig();
    public
        { Public declarations }
        class procedure EditConfig;
    end;

var
    EditConfigForm : TEditConfigForm;

implementation

uses svclBiometricFiles, SvcMgr;

{$R *.dfm}

{ TEditConfigForm }

class procedure TEditConfigForm.EditConfig;
var
    frm : TEditConfigForm;
begin
    if (GlobalConfig.isHotKeyPressed()) then begin
		 Application.CreateForm(TEditConfigForm, frm);
		 try
			 frm.LoadConfig();
			 frm.ShowModal();
			 if (frm.ModalResult = mrOk) then begin
				 frm.SaveConfig();
			 end else begin
				 raise Exception.Create('Operação cancelada pelo usuário');
			 end;
		 finally
			 frm.Free;
		 end;
	 end;
end;

procedure TEditConfigForm.LoadConfig;
 ///<summary>
 ///    Carrega as configurações para os controles
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
begin
    //Modo de trabalho
    Self.chkServerMode.Checked := GlobalConfig.RunAsServer;
    //Conf. cliente
    Self.edtDirClientBioServicePath.Text := GlobalConfig.PathClientBioService;
    Self.edtDirClientELO2TransBioBio.Text := GlobalConfig.TransbioConfig.PathBio;
    Self.edtDirClientTransBioTrans.Text := GlobalConfig.TransbioConfig.PathTransmitted;
    Self.edtDirClientTransBioRetrans.Text := GlobalConfig.TransbioConfig.PathRetrans;
    Self.edtDirClientTransBioError.Text := GlobalConfig.TransbioConfig.PathError;
    Self.edtDirClientPathFullyBackup.Text := GlobalConfig.PathClientFullyBackup;
    Self.edtDirClientPathOrderedBackup.Text := GlobalConfig.PathClientOrderlyBackup;
    Self.edtClientServername.Text := GlobalConfig.ServerName;
    Self.seClientTimeInterval.Value := GlobalConfig.CycleInterval;
    //Conf. Server
    Self.edtDirServerPathTransBio.Text := GlobalConfig.PathServerTransBio;
    Self.edtDirServerPathOrderlyBackup.Text := GlobalConfig.PathServerOrderedBackup;
    Self.edtDirServerPathFullyBackup.Text := GlobalConfig.PathServerFullyBackup;
    //Conf. Comum
    Self.edtTCPPort.Value     := GlobalConfig.NetServicePort;
    Self.edtNotificationList.Text := GlobalConfig.NotificationList;
    Self.edtEmailEmitter.Text := GlobalConfig.NotificationSender;
    Self.edtfTransBioConfigFile.Text := GlobalConfig.PathTransbioConfigFile;
    Self.seDebugLevel.Value   := GlobalConfig.DebugLevel;
end;

procedure TEditConfigForm.SaveConfig;
 ///<summary>
 ///Salva as configurações dos controles para o arquivo
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
begin
    //Modo de trabalho
    GlobalConfig.RunAsServer    := Self.chkServerMode.Checked;
    //Conf. cliente
    GlobalConfig.PathClientBioService := Self.edtDirClientBioServicePath.Text;
    GlobalConfig.TransbioConfig.PathBio := Self.edtDirClientELO2TransBioBio.Text;
    GlobalConfig.TransbioConfig.PathTransmitted := Self.edtDirClientTransBioTrans.Text;
    GlobalConfig.TransbioConfig.PathRetrans := Self.edtDirClientTransBioRetrans.Text;
    GlobalConfig.TransbioConfig.PathError := Self.edtDirClientTransBioError.Text;
    GlobalConfig.PathClientFullyBackup := Self.edtDirClientPathFullyBackup.Text;
    GlobalConfig.PathClientOrderlyBackup := Self.edtDirClientPathOrderedBackup.Text;
    GlobalConfig.ServerName     := Self.edtClientServername.Text;
    GlobalConfig.CycleInterval  := Self.seClientTimeInterval.Value;
    //Conf. Server
    GlobalConfig.PathServerTransBio := Self.edtDirServerPathTransBio.Text;
    GlobalConfig.PathServerOrderedBackup := Self.edtDirServerPathOrderlyBackup.Text;
    GlobalConfig.PathServerFullyBackup := Self.edtDirServerPathFullyBackup.Text;
    //Conf. Comum
    GlobalConfig.NetServicePort := Self.edtTCPPort.Value;
    GlobalConfig.NotificationList := Self.edtNotificationList.Text;
    GlobalConfig.NotificationSender := Self.edtEmailEmitter.Text;
    GlobalConfig.PathTransbioConfigFile := Self.edtfTransBioConfigFile.Text;
    GlobalConfig.DebugLevel     := Self.seDebugLevel.Value;
end;

end.
