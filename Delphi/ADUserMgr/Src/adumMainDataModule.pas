{$IFDEF adumMainDataModule}
    {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I ADUserMgr.inc}

unit adumMainDataModule;

interface

uses
    SysUtils, Classes, WideStrings, DBXMySql, DB, SqlExpr,
    Forms, adumFrameStatusOperation, XPThreads, FMTBcd, DBClient, SimpleDS, adumConfig,
  adumUtils;

type
    TDtMdMainADUserMgr = class(TDataModule)
        conMySQLADUsrMgrConnection : TSQLConnection;
    dsUserFullNames: TSimpleDataSet;
    fldUserNameId: TIntegerField;
    fldFullNameUse: TStringField;
    fldRuledFullName: TStringField;
    dtstfldUserFullNamesFldUserEntries: TDataSetField;
    private
        { Private declarations }

    public
        { Public declarations }
    end;

    TADUserControler = class
    public
        procedure CancelPressed(Sender : TObject);
        procedure LoadAllData(MainForm : TForm);
        procedure OpenDatabase;
        function ShowUserBrowser(MainForm : TForm) : TFrame;
    end;

    TExternalLoader = class(XPThreads.TXPNamedThread)

    end;

var
    DtMdMainADUserMgr : TDtMdMainADUserMgr;
    AppControl :        TADUserControler;

implementation

uses
    adumFrameUserBrowser;

{$R *.dfm}

{ TADUserControler }

procedure TADUserControler.CancelPressed(Sender : TObject);
begin
    {TODO -oroger -cdsg : Cancelar o thread em execucao}
end;

procedure TADUserControler.LoadAllData(MainForm : TForm);
    ///  <summary>
    ///    Carrega todos os bancos de dados externos para o interno.
    /// Exibe o frame de progresso, durante o processo e vincula os controles de progressbar e botão cancelar
    ///  </summary>
    ///  <remarks>
    ///
    ///  </remarks>
var
   f : TframeStatusOperation;
begin
     f := TframeStatusOperation.Create(MainForm);
    try
        TframeStatusOperation(f).btnCancel.OnClick := Self.CancelPressed;
        f.Parent := MainForm;
        f.Show;
        f.BringToFront;
        MainForm.Refresh;
        Application.ProcessMessages;
        Self.OpenDatabase;
        //Sleep(3000);
    finally
        f.Free;
    end;
end;

procedure TADUserControler.OpenDatabase;
begin
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.ConnectionName := 'ADUsrMgrConnection';
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.DriverName     := 'MYSQL';
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.GetDriverFunc  := 'getSQLDriverMYSQL';
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.LibraryName    := 'dbxmys.dll';
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.LoginPrompt    := False;
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.Params.Add('drivername=MYSQL');
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.Params.Add('Database=usr_mgr');
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.Params.Add('HostName=' + GlobalConfig.ServerName);
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.Params.Add('User_Name=' + GlobalConfig.DBUserName);  //login
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.Params.Add('Password=' + GlobalConfig.DBPassword);   //Senha
    try
    DtMdMainADUserMgr.conMySQLADUsrMgrConnection.Connected := True;
    DtMdMainADUserMgr.dsUserFullNames.Active := True;
    except
          on E : Exception do begin
             raise EADUMException.Create('Falha abrindo banco de dados:'#13#10 + E.Message );
          end;
    end;
end;

function TADUserControler.ShowUserBrowser(MainForm : TForm) : TFrame;
begin
    try
        Result := TFrmUserBrowser.Create(MainForm);
        Result.Parent := MainForm;
        Result.Show;
        Result.BringToFront;
        MainForm.Refresh;
        Application.ProcessMessages;
        TFrmUserBrowser(Result).LoadData;
    except
        on E : Exception do begin
            if Assigned(Result) then begin
                FreeAndNil(Result);
            end;
            raise E;
        end;
    end;
end;

initialization
    begin
        AppControl := TADUserControler.Create;
    end;

finalization
    begin
        FreeAndNil(AppControl);
    end;

end.
