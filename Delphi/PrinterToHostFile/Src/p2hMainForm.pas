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
        /// <summary>
        /// Constroi e carrega arquivo de host
        /// </summary>
        constructor Create;
        function GetZoneSubNet(ZoneId : Integer) : Integer;
        function GetScannerHost(zone : Integer) : string;
        /// <summary> Ajusta arquivo para conter todas as impressoras da zona corretamente relacionadas </summary>
        /// <param name="zone">Indentificador da zona </param>
        function SetPrinters(zone, RangeOffSet, oct3 : Integer) : Integer;
        function AdjustHosts(ZoneId : Integer) : Integer;
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
    StrHnd, Super, TREConsts, TREUtils, TREZones, WinNetHnd, WinReg32, p2hUtils;

const
    HOSTS_FILE = 'C:\Windows\System32\Drivers\etc\hosts';
    BASE_MAINFORM_CAPTION = 'Ajuste de Endere�os fixos Zona eleitoral - ';
    REG_HKDU_SAMSUNG_ENTRY = 'HKEY_USERS\.DEFAULT\Software\SSScan\Samsung SCX-4x28 Series';
    REG_HKCU_SAMSUNG_ENTRY = 'HKEY_CURRENT_USER\Software\SSScan\Samsung SCX-4x28 Series';


{TODO -oroger -cdsg : Alterar l�gica do aplicativo para registrar em todos os servidores de DNS os hosts das impressoras }

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
        if not InRange(zoneId, TREConsts.CMPNAME_LOCAL_MIN_VALUE, TREConsts.CMPNAME_LOCAL_MAX_VALUE) then begin
            raise Exception.Create('Valor fora da faixa');
        end;
    except
        raise Exception.CreateFmt('Valor inteiro entre %d e %d requerido', [CMPNAME_LOCAL_MIN_VALUE, CMPNAME_LOCAL_MAX_VALUE]);
    end;
    try
        changeCount := Self.hostFile.AdjustHosts(zoneId);
        MessageDlg('Opera��o conclu�da com sucesso'#13 +
            'Foram alteradas ' + Format('%d', [changeCount]) + ' linha(s)',
            mtInformation, [mbOK], 0);
        if Self.chkSetScannerPort.Checked then begin
            Self.hostFile.SetSCX4828ScannerPort(zoneId);
        end;
    except
        on E : Exception do begin
            raise Exception.Create('Opera��o falhou!'#13 + E.Message);
        end;
    end;
end;

procedure TPthfMainForm.btnOpenHostClick(Sender : TObject);
begin
    Self.JvCreateProcess.ApplicationName := 'C:\Windows\notepad.exe';
    Self.JvCreateProcess.CommandLine     := ' ' + HOSTS_FILE;
    Self.JvCreateProcess.Run;
end;

function THostFile.AdjustHosts(ZoneId : Integer) : Integer;
var
    central :   TTRECentral;
    Zone :      TTREZone;
    subNet, x : Integer;
begin
    zone := GlobalZoneMapping.GetZoneById(ZoneId);
    if not Assigned(zone) then begin
        Result := Self.SetPrinters(ZoneId, 0, ZoneId);
    end else begin
        central := zone.Central;
        if not Assigned(central) then begin
            subNet := ZoneId;
            Result := Self.SetPrinters(ZoneId, 0, subNet);
        end else begin
            subNet := central.PrimaryZone.id; //Subrede igual ao octeto da zona primaria
            Result := 0;
            for x := 0 to central.Count - 1 do begin
                zone   := central.Zones[x];
                Result := Result + Self.SetPrinters(zone.Id, Zone.CentralIndex, subNet);
            end;
        end;
    end;
end;

constructor THostFile.Create;
begin
    inherited;
    Self.LoadFromFile(HOSTS_FILE);
end;

function THostFile.GetScannerHost(zone : Integer) : string;
begin
    Result := 'Z' + Format('%2.2d', [zone]) + '-S4828';
end;

function THostFile.GetZoneSubNet(ZoneId : Integer) : Integer;
///  <summary>
///    Retorna a sub-rede da zona em seu endere�amento IP
///  </summary>
///  <remarks>
///	Para esta recupera��o existe um mapeamento carregado de diversas maneiras, certificar-se de usar o correto, bem como seus dados
///  </remarks>
var
	 z : TTREZone;
	 central : TTRECentral;
begin
	 Result := ZoneId; //Assume inicialmente o id da zona para 3 octeto
    z      := GlobalZoneMapping.GetZoneById(ZoneId);
    if Assigned(z) then begin
        central := z.Central;
        if Assigned(central) then begin
            Result := central.PrimaryZone.Id;
        end;
    end;
end;

function THostFile.SetIPLink(const Name, ip : string) : Integer;
var
    x : Integer;
    newLine, curLine : string;
begin
    Result  := 0;
    newLine := ip + '       ' + Name; // salva a linha com 5 espacos de separa��o 
    for x := 0 to Self.Count - 1 do begin
        curLine := Self.Strings[x];
        if TStrHnd.startsWith(curLine, ip) then begin //Verifica altera��o do valor
            if newLine <> curLine then begin
                Self.Strings[x] := newLine;
                Inc(Result);
            end;
            Exit;
        end;
    end;
    Self.Add(newLine); // adiciona a nova linha com 5 espacos de separa��o 
    Inc(Result);
end;

function THostFile.SetPrinters(zone, RangeOffset, oct3 : Integer) : Integer;
///  <summary>
///    <param>Zone</param> - Id da zona
///    <param>RangeOffSet</param>  - Salto para ip do modelo da impressora
///    <param>oct3</param> - terceiro octeto do ipv4 a ser usado como endere�o da impressora
///  </summary>
///  <remarks>
///
///  </remarks>
var
	 prtName, ipBase, prtIp : string;
begin
	if RangeOffSet < 0 then begin
		RangeOffSet:= 0;
	end;

	 {TODO -oroger -cdsg : Colocar cada uma das impressoras em vetor e com saltos de 2 calcular o 4o octeto do endereco. tentar alterar o incio da faixa de 70 para 80 de modo a fugir do roteador }
	 Result  := 0;
	 ipBase  := '10.183.' + IntToStr(oct3);
	 // Xerox
	 prtName := 'Z' + Format('%2.2d', [zone]) + '-X3428';
	 prtIp   := ipBase + '.' + IntToStr( 90 + RangeOffSet );
	 Result  := Result + Self.SetIPLink(prtName, prtIp);

	 // Samsung  ML-3050
	 prtName := 'Z' + Format('%2.2d', [zone]) + '-S3050';
	 prtIp   := ipBase + '.' + IntToStr( 94 + RangeOffSet );
	 Result  := Result + Self.SetIPLink(prtName, prtIp);

	 // Samsung  SCX-4828
	 prtName := 'Z' + Format('%2.2d', [zone]) + '-S4828';
	 prtIp   := ipBase + '.' + IntToStr( 92 + RangeOffSet );
	 Result  := Result + Self.SetIPLink(prtName, prtIp);

	 // Samsung  ML-3710
	 prtName := 'Z' + Format('%2.2d', [zone]) + '-S3710';
	 prtIp   := ipBase + '.' + IntToStr( 96 + RangeOffSet );
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
    zone := 35;
    Self.Caption := BASE_MAINFORM_CAPTION + ' *** Vers�o depura��o*** ' + Self.fileVerMain.FileVersion;
    {$ELSE}
    Self.Caption := BASE_MAINFORM_CAPTION + Self.fileVerMain.FileVersion;
    try
        zone := TREUtils.TTREUtils.GetComputerZone(WinNetHnd.GetComputerName());
    except
        on E : Exception do begin
            raise Exception.Create(
                'Imposs�vel calcular identificar zona baseado no nome do computador'#13
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
            Self.hostFile.AdjustHosts(zone);
            Self.hostFile.SetSCX4828ScannerPort(zone);
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
