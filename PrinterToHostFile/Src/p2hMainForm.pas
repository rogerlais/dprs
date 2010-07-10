unit p2hMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, ExtCtrls, Buttons, FileInfo, JvComponentBase, JvCreateProcess;

type
    THostFile = class(TStringList)
    private
        function SetIPLink(const Name, ip : string) : Integer;
    public
				constructor Create;
				function GetZoneSubNet(zone : integer) : integer;
        function GetScannerHost(zone : Integer) : string;
        function SetPrinters(zone : Integer) : Integer;
        procedure SetSCX4828ScannerPort(zoneId : Integer);
    end;

    TPthfMainForm = class(TForm)
        btnOK :           TBitBtn;
        btnCancel :       TBitBtn;
        edtZoneId :       TLabeledEdit;
        fileVerMain :     TFileVersionInfo;
        chkSetScannerPort : TCheckBox;
        btnOpenHost :     TBitBtn;
        JvCreateProcess : TJvCreateProcess;
        procedure btnOKClick(Sender : TObject);
        procedure btnCancelClick(Sender : TObject);
        procedure btnOpenHostClick(Sender : TObject);
    private
        { Private declarations }
        hostFile : THostFile;
    public
        { Public declarations }
        constructor Create(AOwner : TComponent); override;
        destructor Destroy; override;
    end;

var
    PthfMainForm : TPthfMainForm;

implementation

{$R *.dfm}

uses
    StrHnd, Super, TREUtils, WinNetHnd, WinReg32;

const
    HOSTS_FILE = 'C:\Windows\System32\Drivers\etc\hosts';
    BASE_MAINFORM_CAPTION = 'Ajuste de Endereços fixos Zona eleitoral - ';
    REG_HKDU_SAMSUNG_ENTRY = 'HKEY_USERS\.DEFAULT\Software\SSScan\Samsung SCX-4x28 Series';
    REG_HKCU_SAMSUNG_ENTRY = 'HKEY_CURRENT_USER\Software\SSScan\Samsung SCX-4x28 Series';


procedure TPthfMainForm.btnCancelClick(Sender : TObject);
begin
    Self.Close;
end;

procedure TPthfMainForm.btnOKClick(Sender : TObject);
var
    changeCount, zoneId : Integer;
begin
    try
        zoneId := StrToInt(Self.edtZoneId.Text);
        {TODO -oroger -cfuture : manifestas a criar}
        if not InRange(zoneId, 1, 77) then begin
            raise Exception.Create('Valor fora da faixa');
        end;
    except
        raise Exception.Create('Valor inteiro entre 1 e 77 requerido');
    end;
    try
        changeCount := Self.hostFile.SetPrinters(zoneId);
        MessageDlg('Operação concluída com sucesso'#13 +
            'Foram alteradas ' + Format('%d', [changeCount]) + ' linha(s)',
            mtInformation, [mbOK], 0);
        if Self.chkSetScannerPort.Checked then begin
            Self.hostFile.SetSCX4828ScannerPort(zoneId);
        end;
    except
        on E : Exception do begin
            raise Exception.Create('Operação falhou!'#13 + E.Message);
        end;
    end;
end;

procedure TPthfMainForm.btnOpenHostClick(Sender : TObject);
begin
    Self.JvCreateProcess.ApplicationName := 'C:\Windows\notepad.exe';
    Self.JvCreateProcess.CommandLine     := ' ' + HOSTS_FILE;
    Self.JvCreateProcess.Run;
end;

 /// <summary>
 /// Constroi e carrega arquivo de host 
 /// </summary> 
constructor THostFile.Create;
begin
    inherited;
    Self.LoadFromFile(HOSTS_FILE);
end;

function THostFile.GetScannerHost(zone : Integer) : string;
begin
    Result := 'Z' + Format('%2.2d', [zone]) + '-S4828';
end;

function THostFile.GetZoneSubNet(zone: integer): integer;
begin
	{TODO -oroger -cdsg : Traduzir para qual subrede a zona vai trabalhar, exemplo: 66->32 }
	{TODO -oroger -cdsg : Após implementado realizar a tradução ao longo do codigo}
end;

function THostFile.SetIPLink(const Name, ip : string) : Integer;
var
    x : Integer;
    newLine, curLine : string;
begin
    Result  := 0;
    newLine := ip + '       ' + Name; // salva a linha com 5 espacos de separação 
    for x := 0 to Self.Count - 1 do begin
        curLine := Self.Strings[x];
        if TStrHnd.startsWith(curLine, ip) then begin //Verifica alteração do valor
            if newLine <> curLine then begin
                Self.Strings[x] := newLine;
                Inc(Result);
            end;
            Exit;
        end;
    end;
    Self.Add(newLine); // adiciona a nova linha com 5 espacos de separação 
    Inc(Result);
end;

 /// <summary> 
 /// Ajusta arquivo para conter todas as impressoras da zona corretamente relacionadas 
 /// </summary> 
 /// <param name="zone">Indentificador da zona </param> 
function THostFile.SetPrinters(zone : Integer) : Integer;
var
    prtName, ipBase, prtIp : string;
begin
    Result  := 0;
    ipBase  := '10.183.' + IntToStr(zone);
    // Xerox
    prtName := 'Z' + Format('%2.2d', [zone]) + '-X3428';
    prtIp   := ipBase + '.90';
    Result  := Result + Self.SetIPLink(prtName, prtIp);

    // Samsung  ML-3050
    prtName := 'Z' + Format('%2.2d', [zone]) + '-S3050';
    prtIp   := ipBase + '.94';
    Result  := Result + Self.SetIPLink(prtName, prtIp);

    // Samsung  SCX-4828
    prtName := 'Z' + Format('%2.2d', [zone]) + '-S4828';
    prtIp   := ipBase + '.92';
    Result  := Result + Self.SetIPLink(prtName, prtIp);

    if Result > 0 then begin
        Self.SaveToFile(HOSTS_FILE); // atualiza arquivo             
    end;
end;

procedure THostFile.SetSCX4828ScannerPort(zoneId : Integer);

    procedure LSRSetReg(RegInstance : TRegistryNT);
    begin
        RegInstance.WriteString('TwainLocation', 'C:\WINDOWS\Twain_32\Samsung\SCX4x28');
        RegInstance.WriteInteger('ConnectionType', 1);
        RegInstance.WriteString('TwCntCode', 'BP');
        RegInstance.WriteString('Location', 'Z' + Format('%2.2d', [zoneId]));
        RegInstance.WriteString('Address', Self.GetScannerHost(zoneId));
    end;

var
    reg : TRegistryNT;
begin
    reg := TRegistryNT.Create;
    try
        try
            reg.OpenFullKey(REG_HKCU_SAMSUNG_ENTRY, True); //Abre hive para current user
            LSRSetReg(reg);
            reg.OpenFullKey(REG_HKDU_SAMSUNG_ENTRY, True); //Abre hive para default user
            LSRSetReg(reg);
        finally
            reg.Free;
        end;
    except
        on E : Exception do begin
            raise Exception.Create('Erro acessando chave de registro'#13 + E.Message);
        end;
    end;
end;

constructor TPthfMainForm.Create(AOwner : TComponent);
var
    x, zone :  Integer;
    itemName : string;
begin
    inherited;
    Self.fileVerMain.FileName := ParamStr(0);
    // identificar e precarregar o valor para a zona 
{$IFDEF DEBUG}
	zone := 38;
	Self.Caption:=BASE_MAINFORM_CAPTION + ' *** Versão depuração*** ' + Self.fileVerMain.FileVersion;
{$ELSE}
    Self.Caption := BASE_MAINFORM_CAPTION + Self.fileVerMain.FileVersion;
    try
        zone := TREUtils.TTREUtils.GetComputerZone(WinNetHnd.GetComputerName());
    except
        on E : Exception do begin
            raise Exception.Create(
                'Impossível calcular identificar zona baseado no nome do computador'#13
                + WinNetHnd.GetComputerName());
        end;
    end;
{$ENDIF}
    Self.edtZoneId.Text := IntToStr(zone);
    try
        Self.hostFile := THostFile.Create;
    except
        on E : Exception do begin
            raise Exception.Create('Erro acesso arquivo de Hosts'#13 + E.Message);
        end;
    end;

    //Verifica se roda no modo auto
    for x := 0 to ParamCount do begin
        itemName := ParamStr(x);
        if SameText(itemName, '/auto') then begin //rodar no modo automatico
            Self.Visible := False;
            Application.ShowMainForm := False;
            Self.hostFile.SetPrinters(zone);
            Self.hostFile.SetSCX4828ScannerPort(zone);
            Self.Close;
            Application.Terminate;
        end;
    end;
end;

destructor TPthfMainForm.Destroy;
begin
    Self.hostFile.Free;
    inherited;
end;

end.
