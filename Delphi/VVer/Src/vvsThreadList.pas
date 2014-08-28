{$IFDEF vvsThreadList}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVerSvc.inc}

unit vvsThreadList;

interface

uses
    Classes, SysUtils, Windows, SyncObjs;

type
    TSyncTThreadList<T> = class(TObject)
    private
        FLock : TCriticalSection;
        FList : TStringList;
        function GetOwnsObjects : boolean;
        procedure SetOwnsObjects(const Value : boolean);
    public
        constructor Create; virtual;
        destructor Destroy; override;
        function Add(const AName : string; const AValue : T) : Integer;
        function GetByName(const AName : string) : T;
        procedure Extract(const AValue : T);
        function Get(const AName : string) : T;
        property OwnsObjects : boolean read GetOwnsObjects write SetOwnsObjects;
    end;

implementation

{ TSyncTThreadList<T> }

function TSyncTThreadList<T>.Add(const AName : string; const AValue : T) : Integer;
begin
    Self.FLock.Enter;
    try
		Self.FList.AddObject( AName, TObject( AValue ) );
	 finally
		Self.FLock.Leave;
	 end;
end;

constructor TSyncTThreadList<T>.Create;
begin
    inherited Create;
    Self.FLock := TCriticalSection.Create;
    Self.FList := TStringList.Create;
	 Self.FList.OwnsObjects := True;
	 Self.FList.Sorted:=True;
end;

destructor TSyncTThreadList<T>.Destroy;
begin
    Self.FLock.Enter;
    try
	 	Self.FList.Free;
	 finally
		Self.FLock.Free; //Espero que chame antes Self.FLock.Leave;
	 end;
	 inherited;
end;

procedure TSyncTThreadList<T>.Extract(const AValue : T);
var
	idx : integer;
begin
	Self.FLock.Enter;
	try
		idx:=Self.FList.IndexOfObject( TObject(AValue) );
		if ( idx <> -1 ) then begin
			Self.FList.Delete( idx );
		end;
	finally
   	Self.FLock.Leave;
	end;
end;

function TSyncTThreadList<T>.Get(const AName : string) : T;
var
	idx : integer;
begin
	Self.FLock.Enter;
	try
		if ( Self.FList.Find( AName, idx ) ) then begin
			Result:=T( Self.Flist.Objects[ idx ] );
		end else begin
			Result:=T(TObject(nil));
		end;
	finally
		Self.FLock.Leave;
	end;
end;

function TSyncTThreadList<T>.GetByName(const AName : string) : T;
begin
	Self.FLock.Enter;
	try

	finally
		Self.FLock.Leave;
	end;
end;

function TSyncTThreadList<T>.GetOwnsObjects : boolean;
begin
	 Self.FLock.Enter;
	 try
		 Result := Self.FList.OwnsObjects;
	 finally
		 Self.FLock.Leave
	 end;
end;

procedure TSyncTThreadList<T>.SetOwnsObjects(const Value : boolean);
begin
    Self.FLock.Enter;
    try
        Self.FList.OwnsObjects := Value;
    finally
        Self.FLock.Leave
    end;
end;

end.
