{$IFDEF vvSvcStatus}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
//Criado em 20141021 por roger

unit vvSvcStatus;

interface

uses
	Classes, SysUtils, System.Generics.Collections;

type
	TRuningStatus = (rsUnknow, rsIdle, rsBuzy, rsDownload, rsError);

	///<summary>
	///Instancia classe para a comunicação IPC entre o serviço o processo GUI
	///</summary>
	TIPCStatus = class
	private
		FRuningStatus: TRuningStatus;
		FClientList  : TObjectList<TObject>;
		procedure SetRuningStatus(const Value: TRuningStatus);
	protected
		{ protected declarations }
	public
		{ public declarations }
		property RuningStatus: TRuningStatus read FRuningStatus write SetRuningStatus;
		constructor Create();
		destructor Destroy; override;
		procedure UpdateClients();
	end;

implementation

{ TIPCStatus }

constructor TIPCStatus.Create;
begin
	Self.FRuningStatus := rsError;
	Self.FClientList   := TObjectList<TObject>.Create;
end;

destructor TIPCStatus.Destroy;
begin
	Self.FClientList.Free;
	inherited;
end;

procedure TIPCStatus.SetRuningStatus(const Value: TRuningStatus);
begin
	Self.FRuningStatus := Value;
	Self.UpdateClients;
	{ TODO -oroger -cdsg : atualiza status de exibição }
end;

procedure TIPCStatus.UpdateClients;
var
	obj : TObject;
begin
	for Obj in Self.FClientList do begin
		//Notifica clientes da alteração
	end;
end;

end.
