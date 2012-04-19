{$IFDEF mtUtils}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I MigraTools.inc}

unit mtUtils;

interface

uses
    SysUtils, Windows, Classes, WinReg32, JclWin32, LmAccess, Generics.Collections, TREUsers;

type
    TZEUser = class
    private
        FUserName : string;
        FPassword : string;
        FChecked :  boolean;
        FScope :    TUserScope;
    public
        constructor Create(const AName, APassword : string); virtual;
        /// <summary>
        ///  traduz a senha para a forma calculada
        /// </summary>
        /// <param name="Zone">Identificador da zona</param>
        /// <returns>senha calculada deste usuário</returns>
        function TranslatedPwd(Zone : Integer) : string;
        property UserName : string read FUserName;
        property Password : string read FPassword write FPassword;
        property Checked : boolean read FChecked write FChecked;
        property Scope : TUserScope read FScope write FScope;
        /// <summary>
        /// Troca a senha da conta deste usuário de zona no computador local
        /// </summary>
        /// <returns>Código de erro da operação</returns>
        function SetPassword(Zone : Integer) : NET_API_STATUS;
    end;

    TZEUserList = class
    private
        _FDomain : string;
        FUsers :   TObjectList<TZEUser>;
        function GetCount : Integer;
        function GetItems(index : Integer) : TZEUser;
        function GetIsDomain : boolean;
        function LookupStationDomain(const CurUser : string) : string;
        function GetDomain : string;
        function GetZoneId : Integer;
    public
        constructor Create;
        destructor Destroy; override;
        property Domain : string read GetDomain;
        property Count : Integer read GetCount;
        property Items[index : Integer] : TZEUser read GetItems;
        property isDomain : boolean read GetIsDomain;
        property ZoneId : Integer read GetZoneId;
        function Add(NewUser : TZEUser) : Integer;
        function SetPasswords() : string;
        function Find(const Username : string) : TZEUser;
    end;

var
    GlobalSaveLog : TStringList;

implementation

uses
    APIHnd, WinNetHnd, StrHnd, Str_Pas, TREUtils, AppLog;

const
{$IFDEF DEBUG}
    HOOK_USER_ACCOUNT = 'roger'; //Conta usada para recuperar o dominio da máquina
{$ELSE}
    HOOK_USER_ACCOUNT = '000000010191'; //Conta usada para recuperar o dominio da máquina
{$ENDIF}

procedure StrResetLength(var S : string);
var
    I : Integer;
begin
    for I := 0 to Length(S) - 1 do begin
        if S[I + 1] = #0 then begin
            SetLength(S, I);
            Exit;
        end;
    end;
end;

constructor TZEUser.Create(const AName, APassword : string);
begin
    Self.FUserName := AName;
    Self.FPassword := APassword;
    Self.FScope    := usInvalid;
end;

function TZEUser.SetPassword(Zone : Integer) : NET_API_STATUS;
var
    userInfo :   TUserInfo1003;
    PError :     DWORD;
    PDomain, PUsername : PWideChar;
    tokenIndex : Integer;
    ErrorlogString : string;
begin
    tokenIndex := Pos('\', Self.FUserName);
    if tokenIndex <> 0 then begin //conta de dominio
        PDomain   := StrNew(PWideChar(Copy(Self.UserName, 1, tokenIndex - 1)));
        PUsername := StrNew(PWideChar(Copy(Self.FUserName, tokenIndex + 1, Length(Self.UserName))));
    end else begin
        PDomain   := nil;
        PUsername := StrNew(PWideChar(Self.FUserName));
    end;
    userInfo.usri1003_password := StrNew(PWideChar(Self.TranslatedPwd(Zone)));
    try
        Result := NetUserSetInfo(PDomain, PUserName, 1003, @userInfo, @PError);
        if (Result <> NERR_Success) then begin //Registrar a falha de alteração
            ErrorlogString := '       ***IMPORTANTE: ' +
                Format('Operação falhou para %s. %s.'#13#10, [Self.UserName, SysErrorMessage(Result)]);
        end;
        if Self.Scope <> usSupport then begin
            GlobalSaveLog.Values[Self.UserName] := userInfo.usri1003_password + ErrorlogString;
        end else begin
            GlobalSaveLog.Values[Self.UserName] := ErrorlogString;
        end;
    finally
        StrDispose(PUsername);
        StrDispose(PDomain);
        StrDispose(userInfo.usri1003_password);
    end;
end;

function TZEUser.TranslatedPwd(Zone : Integer) : string;
var
    chain : string;
    zv :    array[1..3] of char;
begin
    try
        chain  := Format('%3.3d', [Zone]);
        zv[1]  := Chr(Ord('i') + StrToInt(Copy(chain, 1, 1)));
        zv[2]  := Chr(Ord('a') + StrToInt(Copy(chain, 2, 1)));
        zv[3]  := Chr(Ord('o') + StrToInt(Copy(chain, 3, 1)));
        Result := Self.Password;
        Result := Str_Pas.ReplaceSubString(Result, '<1>', zv[1]);
        Result := Str_Pas.ReplaceSubString(Result, '<2>', zv[2]);
        Result := Str_Pas.ReplaceSubString(Result, '<3>', zv[3]);
    except
        on E : Exception do begin
            raise Exception.CreateFmt('Erro traduzindo senha para a conta "%s" para o identificador %d',
                [Self.UserName, Zone, E.Message]);
        end;
    end;
end;

{ TZEUserList }

function TZEUserList.Add(NewUser : TZEUser) : Integer;
begin
    Result := Self.FUsers.Add(NewUser);
end;

constructor TZEUserList.Create;
var
    x :     Integer;
    dName : string;
    dUser : TZEUser;
begin
    inherited;
    Self.FUsers := TObjectList<TZEUser>.Create();
    Self.FUsers.OwnsObjects := True;
    //Adiciona a lista de usuários conhecida
      {$IFDEF DEBUG}
    //Self.FUsers.Add( TZEUser.Create('ghost', 'esmeralda' ) );
    dUser := TZEUser.Create('000000010191', 'xp2k3oper');
    dUser.Scope := usSupport;
    Self.FUsers.Add(dUser);
      {$ELSE}
    dUser := TZEUser.Create('suporte', '$!$adm!n');
    dUser.Scope := usSupport;
    Self.FUsers.Add(dUser);

    dUser := TZEUser.Create('vncacesso', 'ac3ss0vnc');
    dUser.Scope := usSupport;
    Self.FUsers.Add(dUser);

    dUser := TZEUser.Create('instalador', 's<1>nst<2>l<3>');
    dUser.Scope := usZone;
    Self.FUsers.Add(dUser);

    dUser := TZEUser.Create('desinstalador', 'des<1>nst<2>l<3>');
    dUser.Scope := usZone;
    Self.FUsers.Add(dUser);

    dUser := TZEUser.Create('supervisor', 'autor<1>z<2>d<3>');
    dUser.Scope := usZone;
    Self.FUsers.Add(dUser);

    dUser := TZEUser.Create('oficial', 'ass<1>n<2>d<3>');
    dUser.Scope := usZone;
    Self.FUsers.Add(dUser);

    dUser := TZEUser.Create('000000010191', 'xp2k3oper');
    dUser.Scope := usSupport;
    Self.FUsers.Add(dUser);

     {$ENDIF}

    //duplicar contas de usuários para o caso de haver domínio
    dName := Self.Domain;
    if dName <> EmptyStr then begin
        if not (TStrHnd.endsWith(dName, '.GOV.BR')) then begin
            dName := dName + '.GOV.BR';
        end;
        for x := Self.FUsers.Count - 1 downto 0 do begin
            dUser := TZEUser.Create(dName + '\' + Self.FUsers.Items[x].UserName, Self.FUsers.Items[x].Password);
            dUser.Scope := Self.FUsers.Items[x].Scope;
            dUser.Checked := Self.FUsers.Items[x].Checked;
            Self.FUsers.Add(dUser);
        end;
    end;

    //habilita todos os usuarios
    for x := 0 to Self.FUsers.Count - 1 do begin
        Self.Items[x].Checked := True;
    end;
end;

destructor TZEUserList.Destroy;
begin
    Self.FUsers.Free;
    inherited;
end;

function TZEUserList.Find(const Username : string) : TZEUser;
var
    x : Integer;
begin
    Result := nil;
    for x := 0 to Self.FUsers.Count - 1 do begin
        if SameText(Self.FUsers.Items[x].FUserName, Username) then begin
            Result := Self.FUsers.Items[x];
            Exit;
        end;
    end;
end;

function TZEUserList.GetCount : Integer;
begin
    Result := Self.FUsers.Count;
end;

function TZEUserList.GetDomain : string;
begin
    if (Pos('STD', UpperCase(GetComputerName())) > 0) then begin //Maquina STD = não possui dominio
        Result := EmptyStr;
    end else begin
        if (Self._FDomain = EmptyStr) then begin
            Self._FDomain := Self.LookupStationDomain(HOOK_USER_ACCOUNT);
        end;
        Result := Self._FDomain;
    end;
end;

 /// <summary>
 /// Determina se a estação pertence a um domínio
 /// </summary>
 /// <returns>Condição da estação</returns>
function TZEUserList.GetIsDomain : boolean;
var
    cName : string;
begin
    Result := (Self.Domain <> EmptyStr);
     (*
     cName  := UpperCase(GetComputerName());
     {TODO -oroger -cfuture : Melhorar forma de recuperar dominio sem as gambiarras}
     //Usa-se conta pertinente exclusivamente ao dominio(não podemos ter outra de mesmo nome na máquina) para pegar o dominio vinculado
     Result := TStrHnd.Contains('WKS', cName) or TStrHnd.Contains('PDC', cName);     
     *)
end;

function TZEUserList.GetItems(index : Integer) : TZEUser;
begin
    Result := Self.FUsers.Items[index];
end;

function TZEUserList.GetZoneId : Integer;
var
    domainName : string;
begin
    if Self.isDomain then begin
        //Formato do nome do dominio = cae-pbnnn ou zne-pbnnn
         {$IFDEF DEBUG}
        domainName := Copy('cae-pb123.gov.br', 7, 3);
         {$ELSE}
        domainName := Copy(Self.Domain, 7, 3);
         {$ENDIF}
        Result     := StrToInt(domainName);
    end else begin
         {$IFDEF DEBUG}
        Result := TTREUtils.GetComputerZone('ZPB081WKS145');
         {$ELSE}
        try
            Result := TTREUtils.GetComputerZone(GetComputerName());
        except
            on E : Exception do begin
                raise Exception.CreateFmt('Impossível determinar a zona deste computador(%s).#13''%s', [GetComputerName(), E.Message]);
            end;
        end;
         {$ENDIF}
    end;
end;

function TZEUserList.LookupStationDomain(const CurUser : string) : string;
var
    Count1, Count2 : DWORD;
    Sd :  PSID; // PSecurityDescriptor; // FPC requires PSID
    Snu : SID_Name_Use;
begin
    Count1 := 0;
    Count2 := 0;
    Sd     := nil;
    Snu    := SIDTypeUser;
    Result := '';
    LookUpAccountName(nil, PChar(CurUser), Sd, Count1, PChar(Result), Count2, Snu);
    // set buffer size to Count2 + 2 characters for safety
    SetLength(Result, Count2 + 1);
    Sd := AllocMem(Count1);
    try
        if LookUpAccountName(nil, PChar(CurUser), Sd, Count1, PChar(Result), Count2, Snu) then begin
            StrResetLength(Result);
        end else begin
            Result := EmptyStr;
        end;
    finally
        FreeMem(Sd);
    end;
end;

function TZEUserList.SetPasswords : string;
var
    User : TZEUser;
    ret :  NET_API_STATUS;
    x :    Integer;
begin
    Result := EmptyStr;
    for x := 0 to Self.FUsers.Count - 1 do begin
        User := Self.FUsers.Items[x];
        if User.Checked then begin
            try
                ret := User.SetPassword(Self.ZoneId);
                TAPIHnd.CheckAPI(ret);
            except
                on E : Exception do begin
                    Result := Result + #13 + E.Message + #13'Conta(' + User.FUserName + ')';
                end;
            end;
        end;
    end;
end;

initialization
    begin
        GlobalSaveLog := TStringList.Create;
        GlobalSaveLog.Add('Resultado da operação realizada em: ' + DateToStr(Now()));
        GlobalSaveLog.Add('');
        GlobalSaveLog.Add('***  Senhas  ***');
    end;

finalization
    begin
        GlobalSaveLog.Free;
    end;

end.
