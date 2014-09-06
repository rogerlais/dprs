{$IFDEF vvsConsts}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVERSvc.inc}

unit vvsConsts;

interface

uses
    Classes, Windows, SysUtils, TypInfo, SvcMgr;

type
    //enumeração deve ser literalmente usada nos verbos(cliente/servidor)
	 TVVSVerbs = (vvvReadContent, vvvFileDownload, vvvFileClose, vvvFullFingerprint, vvvReadSegment, vvvRegisterStatus, vvvEndSession );

const
	 DBG_CLIENT_NAME = 'ZPB999WKS01';

	 SUBJECT_TEMPLATE        = 'VVerService - Versão: %s - %s - %s';
	 SWITCH_AUTOCONFIG       = 'autoconfig'; //informa que durante as operações de download a janela de interação não será mostrada

	 PUBLICATION_INSTSEG = 'INSTSEG';

	 MD5_BLOCK_ALIGNMENT = 2048;

	 TOKEN_DELIMITER      = #13#10;
	 STR_CMD_VERB         = 'verb=';
	 STR_END_SESSION_SIGNATURE = 'end_session=';
	 STR_BEGIN_SESSION_SIGNATURE = 'start_session=';
	 STR_OK_PACK          = 'OK';
	 STR_FAIL_PREFIX      = 'FAIL';
	 STR_FAIL_HASH        = STR_FAIL_PREFIX + ' HASH';
	 STR_FAIL_SIZE        = STR_FAIL_PREFIX + ' SIZE';
	 STR_FAIL_VERB        = STR_FAIL_PREFIX + ' VERB';
	 STR_FAIL_RETURN      = STR_FAIL_PREFIX + ' EXECUTION';
	 STR_FAIL_NET         = STR_FAIL_PREFIX + ' NETWORK';
    STR_FAIL_PROTOCOL    = STR_FAIL_PREFIX + ' PROTOCOL';

    II_SERVER_IDLE  = 0;
    II_SERVER_ERROR = 1;
    II_SERVER_BUZY  = 2;
    II_SERVER_OK    = 3;
    II_CLIENT_IDLE  = 0;
    II_CLIENT_ERROR = 1;
    II_CLIENT_BUZY  = 2;
    II_CLIENT_OK    = 3;


function Verb2String(const AVerb : TVVSVerbs) : string;
function String2Verb(const AVerb : string) : TVVSVerbs;
function ServiceStatus2String(const AStatus : TCurrentStatus) : string;
function HTTPEncode(const AStr : ansistring) : ansistring;
function HTTPDecode(const AStr : ansistring) : ansistring;


implementation

function HTTPDecode(const AStr : ansistring) : ansistring;
var
    Sp, Rp, Cp : PAnsiChar;
    S : ansistring;
begin
    SetLength(Result, Length(AStr));
    Sp := PAnsiChar(AStr);
    Rp := PAnsiChar(Result);
    Cp := Sp;
    try
        while Sp^ <> #0 do begin
            case Sp^ of
                '+' : begin
                    Rp^ := ' ';
                end;
                '%' : begin
                    // Look for an escaped % (%%) or %<hex> encoded character
                    Inc(Sp);
                    if Sp^ = '%' then begin
                        Rp^ := '%';
                    end else begin
                        Cp := Sp;
                        Inc(Sp);
                        if (Cp^ <> #0) and (Sp^ <> #0) then begin
                            S   := AnsiChar('$') + Cp^ + Sp^;
                            Rp^ := AnsiChar(StrToInt(string(S)));
                        end else begin
                            raise Exception.CreateFmt('Erro decodificando %s em %s', [Cp - PAnsiChar(AStr)]);
                        end;
                    end;
                end;
                else begin
                    Rp^ := Sp^;
                end;
            end;
            Inc(Rp);
            Inc(Sp);
        end;
    except
        on E : EConvertError do raise EConvertError.CreateFmt('Caracter "%s" inválido encontrado',
                [AnsiChar('%') + Cp^ + Sp^, Cp - PAnsiChar(AStr)])
    end;
    SetLength(Result, Rp - PAnsiChar(Result));
end;


function HTTPEncode(const AStr : ansistring) : ansistring;
    // The NoConversion set contains characters as specificed in RFC 1738 and
    // should not be modified unless the standard changes.
const
    NoConversion = ['A'..'Z', 'a'..'z', '*', '@', '.', '_', '-',
        '0'..'9', '$', '!', '''', '(', ')'];
var
    Sp, Rp : PAnsiChar;
begin
    SetLength(Result, Length(AStr) * 3);
    Sp := PAnsiChar(AStr);
    Rp := PAnsiChar(Result);
    while Sp^ <> #0 do begin
        if Sp^ in NoConversion then begin
            Rp^ := Sp^;
        end else
        if Sp^ = ' ' then begin
            Rp^ := '+';
        end else begin
            FormatBuf(Rp^, 3, ansistring('%%%.2x'), 6, [Ord(Sp^)]);
            Inc(Rp, 2);
        end;
        Inc(Rp);
        Inc(Sp);
    end;
    SetLength(Result, Rp - PAnsiChar(Result));
end;


function ServiceStatus2String(const AStatus : TCurrentStatus) : string;
begin
    try
        Result := GetEnumName(TypeInfo(TCurrentStatus), Integer(AStatus));
    except
        on E : Exception do Result := 'Estado desconhecido';
    end;
end;

function Verb2String(const AVerb : TVVSVerbs) : string;
begin
    Result := GetEnumName(TypeInfo(TVVSVerbs), Integer(AVerb));
end;

function String2Verb(const AVerb : string) : TVVSVerbs;
begin
    Result := TVVSVerbs(GetEnumValue(TypeInfo(TVVSVerbs), AVerb));
end;


end.
