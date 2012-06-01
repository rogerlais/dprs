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
	 private
		 FSwitcher : TFUUserSwitcher;
	 protected
		 procedure StreamDispose; override;
		 procedure StreamNeeded; override;
	 public
		 constructor Create(const AFileName : string; Lock : boolean; AUserSwitcher : TFUUserSwitcher ); overload;
	 end;

implementation

{ TFULog }

constructor TFULog.Create(const AFileName : string; Lock : boolean; AUserSwitcher : TFUUserSwitcher );
begin
    inherited Create(AFileName, Lock);
    Self.FSwitcher := AUserSwitcher;
end;

procedure TFULog.StreamDispose;
begin
	 inherited;
	 Self.FSwitcher.
end;

procedure TFULog.StreamNeeded;
begin
	Self.IncreaseNetAcess();
	 inherited;
end;

end.
