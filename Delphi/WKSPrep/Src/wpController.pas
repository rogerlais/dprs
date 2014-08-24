unit wpController;

interface

uses
    Windows, SysUtils, Classes, TREUsers, TREConfig, TREConsts, TREUtils;

type
    TExecSteps = (esIdCapture, esNetAdjuste, esConfigApps);

type
	 TWKSPrepController = class
	 protected
	 	function ConfigApps( ZonId, WksId : Integer ) : Boolean;
    public
        function ReadNetAdapters(List : TStrings) : Integer;
        function ReadActiveNetAdapters(List : TStrings) : Integer;
        procedure ExecStep(CurrentStep : TExecSteps);
    end;


implementation

{ TWKSPrepController }

function TWKSPrepController.ConfigApps(ZonId, WksId: Integer): Boolean;
begin
	{TODO -oroger -cdsg : Ajusta da primeira a ultima aplicação de acordo com o identificador da zona e da máquina}
end;

procedure TWKSPrepController.ExecStep(CurrentStep : TExecSteps);
 ///
 /// PreCond: Registro de passo anterior inexistente ou inválido
 /// PostCond: Sucesso em todos os passos intermediários e registro do passo atual executado
 ///
begin
    case CurrentStep of
        esIdCapture : begin

        end;
        esNetAdjuste : begin

        end;
        esConfigApps : begin

        end;
        else begin

        end;
    end;
end;

function TWKSPrepController.ReadActiveNetAdapters(List : TStrings) : Integer;
begin

end;

function TWKSPrepController.ReadNetAdapters(List : TStrings) : Integer;
begin

end;

end.
