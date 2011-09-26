{$IFDEF FileUpdate}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

program FileUpdate;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  fuMainDataModule in 'fuMainDataModule.pas' {DMMainController: TDataModule};

begin
  try
	 { TODO -oUser -cConsole Main : Insert code here }

  except
	 on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
