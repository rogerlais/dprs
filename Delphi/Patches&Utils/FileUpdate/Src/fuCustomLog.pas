{$IFDEF fuCustomLog}
		  {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}


unit fuCustomLog;

interface

uses
	 SysUtils, Windows, Classes, AppLog, fuUserSwitcher;

type
	 TFULog = class(TLogFile)
	 protected
		 procedure StreamDispose; override;
		 procedure StreamNeeded; override;
	 public
		 constructor Create(const AFileName : string; Lock : boolean ); overload;
		 destructor Destroy; override;
	 end;

implementation

{ TFULog }

constructor TFULog.Create(const AFileName : string; Lock : boolean );
begin
	 inherited Create(AFileName, Lock);
end;

destructor TFULog.Destroy;
begin
	//Self.FParentSwitcher não deve ser destruido aqui, refere-se ao controlador da instancia
	inherited;
end;

procedure TFULog.StreamDispose;
begin
	 inherited;
	 GlobalSwitcher.RevertToPrevious();
end;

procedure TFULog.StreamNeeded;
begin
	GlobalSwitcher.SwitchTo( APP_NET_USER );
	inherited;
end;

end.
