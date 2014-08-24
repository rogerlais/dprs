{$IFDEF svclUtils}
     {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclUtils;

interface


uses
	 Classes, SysUtils, AppLog, Windows, StreamHnd;

type
	 ESVCLException = class(ELoggedException);

implementation

end.
