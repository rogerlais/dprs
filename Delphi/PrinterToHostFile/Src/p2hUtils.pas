unit p2hUtils;

interface

uses
	TREConsts, TREUtils, TREZones;

var
	GlobalZoneMapping : TTRECentralMapping;

implementation


initialization
begin
 GlobalZoneMapping:=TTRECentralMapping.Create;
 GlobalZoneMapping.LoadHardCoded;
end;


end.
