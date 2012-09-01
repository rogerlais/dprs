unit mrfConfiguration;

interface

uses
	Windows, Classes, AppSettings;

type
	TMRFSettings = class( AppSettings.TBaseStartSettings )

	public
   	function CheckSignatureList( const DeviceId : string ) : Boolean;
   end;

implementation

{ TMRFSettings }

function TMRFSettings.CheckSignatureList(const DeviceId: string): Boolean;
begin
	{TODO -oroger -cdsg : Varre a lista de assinaturas de dispositivos para validar o questionado}
	result:=False;
end;

end.
