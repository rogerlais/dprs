{$IFDEF ELOV6Patch}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I ELOV6Patch.inc}

program ELOV6Patch;

{$APPTYPE CONSOLE}

{$R *.dres}
{$R *.res}


uses
  SysUtils,
  Windows,
  WinReg32,
  AppSettings,
  elopSecFolder in 'elopSecFolder.pas';

var
	Reg : AppSettings.TRegistryBasedSettings;

procedure InitApp;
begin
	Reg := TRegistryBasedSettings.Create('HKEY_LOCAL_MACHINE\SOFTWARE\Sistemas Eleitorais\');
end;

procedure PatchELOProduction;
//Corrige ELO V6
begin
	if Reg.KeyExists( 'elo6\Modulo0' ) then begin
		Reg.WriteString( 'elo6\Modulo0\Executavel',
		'"C:\Arquivos de programas\Internet Explorer\iexplore.exe" http://elo6.tse.gov.br/elo/index.seam?cid=4626');
	end else begin
		raise Exception.Create('ELOV6(Produção) não encontrado neste computador');
	end;
end;

procedure PatchELOTreina;
//Corrige elov6 treinamento
begin
	if Reg.KeyExists( 'elo6treinamento\Modulo0' ) then begin
		Reg.WriteString( 'elo6treinamento\Modulo0\Executavel',
		'"C:\Arquivos de programas\Internet Explorer\iexplore.exe" http://elo6treinamento.tse.gov.br/elo/index.seam?cid=4626');
	end else begin
		raise Exception.Create('ELOV6(Treinamento) não encontrado neste computador');
	end;
end;

begin
  try
	 InitApp;
	 PatchELOProduction;
	 PatchELOTreina;
  except
	 on E: Exception do begin
	   Writeln(E.ClassName, ': ', E.Message);
	   MessageBoxW(GetDesktopWindow(), PWideChar(E.Message), PWideChar('Erro'), MB_OK + MB_ICONSTOP + MB_TOPMOST );
	 end;
  end;

end.
