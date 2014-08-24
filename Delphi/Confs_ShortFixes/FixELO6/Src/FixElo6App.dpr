program FixElo6App;

{$APPTYPE CONSOLE}

uses
    SysUtils,
    WinReg32,
    FileHnd,
	 Windows, APIHnd;

    procedure WriteReg;
    var
        reg : TRegistryNT;
    begin
        reg := TRegistryNT.Create;
        try
            reg.WriteFullString('HKEY_LOCAL_MACHINE\SOFTWARE\Sistemas Eleitorais\elo6treinamento\Modulo0\Executavel',
                '"C:\Arquivos de programas\Internet Explorer\iexplore.exe" http://elo6treinamento.tse.gov.br/elo/index.seam?cid=4626',
                True);
            reg.WriteFullString('HKEY_LOCAL_MACHINE\SOFTWARE\Sistemas Eleitorais\elo6\Modulo0\Executavel',
                '"C:\Arquivos de programas\Internet Explorer\iexplore.exe" http://elo6.tse.gov.br/elo/index.seam?cid=4626',
                True);
        finally
            reg.Free;
        end;
    end;

	 procedure ClearOldLink();
	 begin
		 if not( DeleteMaskedFiles('C:\Documents and Settings\All Users\Desktop\E*.lnk') ) then begin
			TAPIHnd.CheckApi( GetLastError() );
        end;
    end;

begin
    try
        { TODO -oUser -cConsole Main : Insert code here }
        try
            WriteReg;
            ClearOldLink;
        except
            on E : Exception do begin
                MessageBoxW(0, 'teste', PWideChar('Operação Falhou' + E.Message), MB_OK + MB_ICONSTOP + MB_TOPMOST);
                System.Halt(8066);
            end;
        end;
    except
        on E : Exception do Writeln(E.ClassName, ': ', E.Message);
    end;
end.
