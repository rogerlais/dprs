{$IFDEF fuFileOperation}
		  {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

unit fuFileOperation;

interface

uses
    SysUtils, Classes, Generics.Collections;

type
    TFUOperations = (
        fuoNone = 0,           //usada para desabilitar temporariamente
        fuoCopy = 1,           //tenta copia, sobrescrevendo sem se preocupar com o sucesso da operação
        fuoOverwrite = 2,      //copia apenas se havia versão anterior
        fuoDelete = 4,         //Apaga caso existe, requesito de sucesso = arquivo não mais existe
        fuoDateUpdate = 8,     //Sobrescreve apenas se data atual inferior a fonte
        fuoVersionUpdate = 16, //Sobrescreve apenas se versão inferior(não havendo versão usa a data)
		 fuoForceUpdate = 32,    //Copia e requer sucesso na sobrescrita
		 fuoLink = 64 		    //Cria atalho de source em dest
        );

    TFUSearchPoint = class
    private
        FLocalPath : string;
        FRecursive : boolean;
    public
        property LocalPath : string read FLocalPath write FLocalPath;
        property Recursive : boolean read FRecursive write FRecursive;
        constructor Create(const ALocalPath : string; ARecursive : boolean);
    end;

    TFUSearchPoints = class(TList<TFUSearchPoint>);


    TFUFileOperation = class
    private
        FSearchPoints : TFUSearchPoints;
        FSourcePath :   string;
        FOperation :    TFUOperations;
    public
        property SourcePath : string read FSourcePath write FSourcePath;
        property Operation : TFUOperations read FOperation write FOperation;
        procedure AddSearchPoint(const APath : string; ARecursive : boolean);
		 constructor Create(const ASourcePath : string);
		 destructor Destroy; override;
    end;

    TFUFileOperations = class( TObjectList<TFUFileOperation> );

implementation

{ TFUSearchPoint }

constructor TFUSearchPoint.Create(const ALocalPath : string; ARecursive : boolean);
begin
    inherited Create();
    Self.FLocalPath := ALocalPath;
    Self.FRecursive := ARecursive;
end;

{ TFUFileOperation }

procedure TFUFileOperation.AddSearchPoint(const APath : string; ARecursive : boolean);
var
	sp : TFUSearchPoint;
begin
	sp := TFUSearchPoint.Create( APath, ARecursive );
	Self.FSearchPoints.Add( sp );
end;

constructor TFUFileOperation.Create(const ASourcePath : string);
begin
    Self.FSourcePath   := ASourcePath;
    Self.FSearchPoints := TFUSearchPoints.Create;
end;

destructor TFUFileOperation.Destroy;
begin
	Self.FSearchPoints.Clear; {TODO -oroger -cdsg : Checar se objetos filhos destruidos para esta classe }
	Self.FSearchPoints.Free;
	inherited;
end;

end.
