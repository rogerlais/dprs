{$IFDEF GPO2VPN}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I GPO2VPN.inc}

program GPO2VPN;

{$APPTYPE CONSOLE}

{$R 'gvBinaryResource.res' 'gvBinaryResource.rc'}

uses
  SysUtils,
  FileHnd,
  gvUtils in 'gvUtils.pas';

var
	controller : TGPOVPNController;
	dst : string;

begin
  try
	 { TODO -oUser -cConsole Main : Insert code here }
	 dst:=TFileHnd.ConcatPath( [ EvalPathName( '%temp%' ), 'GPO2VPN' ] );
	 controller := TGPOVPNController.Create( dst );
	 try
		controller.ExpandResource( dst );
	 finally
	 	controller.Free;
    end;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
