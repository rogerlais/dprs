{$IFDEF svclEditConfigForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclEditConfigForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, svclConfig, Mask, JvExMask, JvToolEdit, Spin;

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
        edtDirServerPathPrimaryBackup : TJvDirectoryEdit;
        edtDirServerPathOrderlyBackup : TJvDirectoryEdit;
        edtfTransBioConfigFile : TJvFilenameEdit;
        lblTransBioConfigFile : TLabel;
        lblClientPathFullyBackup : TLabel;
        lblClientPathOrderedBackup : TLabel;
        edtDirClientPathFullyBackup : TJvDirectoryEdit;
        edtDirClientPathOrderedBackup : TJvDirectoryEdit;
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

{$R *.dfm}

{ TEditConfigForm }

class procedure TEditConfigForm.EditConfig;
var
    frm : TEditConfigForm;
begin
    Application.CreateForm(TEditConfigForm, frm);
    try
        frm.LoadConfig();
        frm.ShowModal();
        if (frm.ModalResult = mrOk) then begin
            frm.SaveConfig();
        end;
    finally
        frm.Free;
    end;
end;

procedure TEditConfigForm.LoadConfig;
begin
    {TODO -oroger -cdsg : Carrega as configurações para os controles}

    //Modo de trabalho
    Self.chkServerMode.Checked := GlobalConfig.RunAsServer;
    //Conf. cliente
    Self.edtDirClientBioServicePath.Text := GlobalConfig.PathBioService;
    Self.edtDirClientELO2TransBioBio.Text := GlobalConfig.TransbioConfig.PathBio;
    Self.edtDirClientTransBioTrans.Text := GlobalConfig.TransbioConfig.PathTransmitted;
    Self.edtDirClientTransBioRetrans.Text := GlobalConfig.TransbioConfig.PathRetrans;
    Self.edtDirClientTransBioError.Text := GlobalConfig.TransbioConfig.PathError;
    Self.edtDirClientPathFullyBackup.Text := GlobalConfig.PathClientFullyBackup;
    Self.edtDirClientPathOrderedBackup.Text := GlobalConfig.PathClientOrderlyBackup;
    Self.edtClientServername.Text := GlobalConfig.ServerName;
    Self.seClientTimeInterval.Value := GlobalConfig.CycleInterval;
    //Conf. Server
    Self.edtDirServerPathPrimaryBackup.Text := GlobalConfig.PathServerTransbioCapture;
    Self.edtDirServerPathOrderlyBackup.Text := GlobalConfig.PathServerOrderedBackup;
    //Conf. Comum
    Self.edtTCPPort.Value     := GlobalConfig.NetServicePort;
    Self.edtNotificationList.Text := GlobalConfig.NotificationList;
    Self.edtEmailEmitter.Text := GlobalConfig.NotificationSender;
    Self.edtfTransBioConfigFile.Text := GlobalConfig.PathTransbioConfigFile;

end;

procedure TEditConfigForm.SaveConfig;
begin
    {TODO -oroger -cdsg : Salva as configurações dos controles para o arquivo}
    //Modo de trabalho
    GlobalConfig.RunAsServer    := Self.chkServerMode.Checked;
    //Conf. cliente
    GlobalConfig.PathBioService := Self.edtDirClientBioServicePath.Text;
    GlobalConfig.TransbioConfig.PathBio := Self.edtDirClientELO2TransBioBio.Text;
    GlobalConfig.TransbioConfig.PathTransmitted := Self.edtDirClientTransBioTrans.Text;
    GlobalConfig.TransbioConfig.PathRetrans := Self.edtDirClientTransBioRetrans.Text;
    GlobalConfig.TransbioConfig.PathError := Self.edtDirClientTransBioError.Text;
    GlobalConfig.PathClientFullyBackup := Self.edtDirClientPathFullyBackup.Text;
    GlobalConfig.PathClientOrderlyBackup := Self.edtDirClientPathOrderedBackup.Text;
    GlobalConfig.ServerName     := Self.edtClientServername.Text;
    GlobalConfig.CycleInterval  := Self.seClientTimeInterval.Value;
    //Conf. Server
    GlobalConfig.PathServerTransbioCapture := Self.edtDirServerPathPrimaryBackup.Text;
    GlobalConfig.PathServerOrderedBackup:= Self.edtDirServerPathOrderlyBackup.Text;
    //Conf. Comum
    GlobalConfig.NetServicePort := Self.edtTCPPort.Value;
    GlobalConfig.NotificationList := Self.edtNotificationList.Text;
    GlobalConfig.NotificationSender := Self.edtEmailEmitter.Text;
    GlobalConfig.PathTransbioConfigFile := Self.edtfTransBioConfigFile.Text;
end;

end.
