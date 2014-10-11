{$IFDEF vvsThreadList}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVerSvc.inc}

unit vvsThreadList;

interface

uses
    Classes, SysUtils, Windows, SyncObjs, System.Generics.Collections;

type
	TSyncTThreadList<T> = class(TObject)
	private
		FLock : TCriticalSection;
		FList : TStringList;
		function GetOwnsObjects : boolean;
		procedure SetOwnsObjects(const Value : boolean);
		function CastRetT( const Value ) : T; inline;
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
	{$TYPEDADDRESS OFF}
	Self.FLock.Enter;
	try
		Self.FList.AddObject( AName, TObject( (@AValue)^ ) );
	 finally
		Self.FLock.Leave;
	 end;
	 {$TYPEDADDRESS ON}
end;

function TSyncTThreadList<T>.CastRetT(const Value): T;
begin
	Result := T( Value );
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
       Self.FLock.Leave;
		Self.FLock.Free;
	 end;
	 inherited;
end;

procedure TSyncTThreadList<T>.Extract(const AValue : T);
var
	idx : integer;
begin
	{$TYPEDADDRESS OFF}
	Self.FLock.Enter;
	try
		idx:=Self.FList.IndexOfObject( TObject((@AValue)^) );
		if ( idx <> -1 ) then begin
			Self.FList.Delete( idx );
		end;
	finally
	Self.FLock.Leave;
	end;
	{$TYPEDADDRESS ON}
end;

function TSyncTThreadList<T>.Get(const AName : string) : T;
var
	idx : integer;
	p : Pointer;
begin
	{$TYPEDADDRESS OFF}
	Self.FLock.Enter;
	try
		if ( Self.FList.Find( AName, idx ) ) then begin
			p:=TObject( Self.Flist.Objects[ idx ] ); //T necessariamente uma classe
			Result:=T( p^ );
		end else begin
			Result:=T(nil);
		end;
	finally
		Self.FLock.Leave;
	end;
	{$TYPEDADDRESS ON}
end;

function TSyncTThreadList<T>.GetByName(const AName : string) : T;
var
	x : Integer;
	ob : TObject;
begin
	Self.FLock.Enter;
	try
		x := Self.FList.IndexOf( AName );
		if ( x >= 0 ) then begin
			ob := Self.FList.Objects[x];
			Result:= Self.CastRetT( ob );
		end else begin
			Result := T(nil);
		end;
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
