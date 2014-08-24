{$IFDEF boInstUtils}
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I boInstall.inc}


unit boInstUtils;

interface

uses
    Windows, SysUtils, WinReg32, Classes, Variants, ComObj, Activex, FileHnd, StrHnd, Math, boInstConfig;


function GetUninstallBrOfficeString(): string;

function GetInstalledApps(list : TStrings) : Integer;

function CompareVersionStrings(const Ver1, Ver2 : string) : Integer;

function NextFamilyFilename2(const BaseFilename : string) : string;

type
    EBROInstallException = class(Exception);

    TStringDisjunctor = class
    private
        FItems : TStringList;
        function GetCount : Integer;
        function GetItems : TStrings;
    public
        constructor Create(const AText : string; ADelimiter : char);
        destructor Destroy; override;
        property Items : TStrings read GetItems;
        property Count : Integer read GetCount;
    end;

implementation


function CompareVersionStrings(const Ver1, Ver2 : string) : Integer;
{{
Compara duas versões no formato de string, retornando
0 - iguais
1 - Ver1 maior
2 - Ver2 maior
}
var
    X :      Integer;
    comp1, comp2 : TStringDisjunctor;
    v1, v2 : longint;
begin
    comp1 := TStringDisjunctor.Create(Ver1, '.');
    comp2 := TStringDisjunctor.Create(Ver2, '.');
    try
        Result := 0;
        X      := 0;
        while (X <= (Max(comp1.Count, comp2.Count) - 1)) do begin
            if (x > (comp1.Count - 1)) then begin
                Result := 2;
                Exit;
            end else begin
                if (x > (comp2.Count - 1)) then begin
                    Result := 1;
                    Exit;
                end;
            end;
            //Tenta comparar por valor numerico inicialmente
            if (TryStrToInt(comp1.Items.Strings[X], v1) and TryStrToInt(comp2.Items.Strings[X], v2)) then begin
                if (v1 > v2) then begin
                    Result := 1;
                    Exit;
                end else begin
                    if (v2 > v1) then begin
                        Result := 2;
                        Exit;
                    end;
                end;
            end else begin //comparacao por valor de cadeia neste ponto
                if (comp1.Items.Strings[X] > comp2.Items.Strings[X]) then begin
                    Result := 1;
                end else begin
                    if (comp2.Items.Strings[X] > comp1.Items.Strings[X]) then begin
                        Result := 2;
                    end;
                end;
            end;
            Inc(X);
        end;
    finally
        comp1.Free;
        comp2.Free;
    end;
end;

function NextFamilyFilename2(const BaseFilename : string) : string;
{{
Calcula o nome do arquivo seguinte para a sequência na pasta destino dada por BaseFilename.
Caso seja passsado BaseFilename já contendo um identificador de sequencia (n) este será desconsiderado, assim o nome
gerado não será sequência(n+1).

Revision - 11/3/2010 - roger

Passou a funcionar para diretorios da mesma forma que para arquivos

Revision: 5/12/2005 - Roger
}
var
    TargetExt, Prefix : string;
    TargetCount : Integer;
begin
   { TODO -oroger -clib : Repor esta versão pela encontrada em class function TFileHnd.NextFamilyFilename(const BaseFilename :
     string) : string; }
    TargetCount := 0;
    TargetExt   := ExtractFileExt(BaseFilename);
    Prefix      := ChangeFileExt(BaseFilename, EmptyStr);
    repeat
        Inc(TargetCount);
        Result := Prefix + '(' + IntToStr(TargetCount) + ')' + TargetExt;
    until ( (not FileExists(Result)) and ( not DirectoryExists(Result)) );
end;

function GetInstalledApps(list : TStrings) : Integer;
{
Rotina retorna lista com aplicativos instalados no computador para todos os usuários, para montar a lista completa deve-se
usar o mesmo caminho para HKEY_CURRENT_USER e para todos os usários isoladamente
DICA: Varrer método mais genérico de realizar esta carga


Revision - 20100819 - roger
Rotina deslocada para a biblioteca em WinSysLib.WinProcess

}
const
	 UNINST_ROOT = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';
var
	 I :     Integer;
	 reg :   TRegistryNT;
	 keyList : TStringList;
	 entry : string;
begin
	 try
        reg := TRegistryNT.Create;
        try
            reg.OpenFullKey(UNINST_ROOT, False);
            keyList := TStringList.Create;
            try
                reg.GetKeyNames(keyList);
                for I := 0 to keyList.Count - 1 do begin
                    if (reg.ReadFullString(TFileHnd.ConcatPath([UNINST_ROOT, keyList.Strings[I], 'DisplayName']), entry))
                    then begin
                        list.Add(entry);
                    end;
                end;
                Result := ERROR_SUCCESS;
            finally
                keyList.Free;
            end;
        finally
            reg.Free;
        end;
    except
        Result := ERROR_ACCESS_DENIED;
    end;
end;


function GetUninstallBrOfficeString(): string;
{
Varre a lista de aplicações instaladas para todos os usuários do computador em busca de assintaura do BrOffice, encontrando 
recupera o valor de UninstallString

DICA: Varrer método mais genérico de realizar esta carga
}
const
    UNINST_ROOT = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';
var
    I :     Integer;
    reg :   TRegistryNT;
    keyList : TStringList;
    entry : string;
begin
    { TODO -oroger -clib : levar para biblioteca }
    Result := EmptyStr;
    try
        reg := TRegistryNT.Create;
        try
            reg.OpenFullKey(UNINST_ROOT, False);
            keyList := TStringList.Create;
            try
                reg.GetKeyNames(keyList);
                for I := 0 to keyList.Count - 1 do begin
                    if (reg.ReadFullString(TFileHnd.ConcatPath([UNINST_ROOT, keyList.Strings[I], 'DisplayName']), entry)) then begin
                        if ( TStrHnd.startsWith( Uppercase(entry), Uppercase('BrOffice.org') ) ) then begin
                           reg.ReadFullString( TFileHnd.ConcatPath([UNINST_ROOT, keyList.Strings[I], 'UninstallString']), Result );
                           Exit;
                        end;
                    end;
                end;
            finally
                keyList.Free;
            end;
        finally
			 reg.Free;
		 end;
	 except
		 raise Exception.Create('Erro lendo cadeia de desinstalação da versão anterior' );
	 end;
end;


{ TStringDisjunctor }

constructor TStringDisjunctor.Create(const AText : string; ADelimiter : char);
begin
	 inherited Create;
	 Self.FItems := TStringList.Create;
	 Self.FItems.Delimiter := ADelimiter;
	 Self.FItems.DelimitedText := AText;
end;

destructor TStringDisjunctor.Destroy;
begin
	 Self.FItems.Free;
	 inherited;
end;

function TStringDisjunctor.GetCount : Integer;
begin
	 Result := Self.FItems.Count;
end;

function TStringDisjunctor.GetItems : TStrings;
begin
	 Result := Self.FItems;
end;

end.
