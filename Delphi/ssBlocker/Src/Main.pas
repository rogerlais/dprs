{$IFDEF Main}
	  {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I ssBlocker.inc}

unit Main;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, WinHnd,
    Dialogs, ExtCtrls, Credits;

type
    TFormMain = class(TForm)
        scrlngcrdts1 : TScrollingCredits;
        tmrMain :      TTimer;
        procedure FormShow(Sender : TObject);
        procedure tmrMainTimer(Sender : TObject);
    private
        { Private declarations }
        FFirstMouseMove : boolean;
		 FLastCursor : TCursor;
		 FPassCount : Integer;
        crs : TPoint;
        procedure DeactivateScrnSaver(var Msg : TMsg; var Handled : boolean);
        procedure LockWinStation();
    public
        { Public declarations }
        constructor Create(AOwner : TComponent); override;
        destructor Destroy; override;
    end;

var
    FormMain : TFormMain;

implementation

uses
    WinNetHnd, Super;

{$R *.dfm}


constructor TFormMain.Create(AOwner : TComponent);
begin
    inherited;
    FFirstMouseMove := True;
	 FLastCursor     := Screen.Cursor;
    Screen.Cursor   := crNone;
    Self.tmrMainTimer(Self.tmrMain);
end;

procedure TFormMain.DeactivateScrnSaver(var Msg : TMsg; var Handled : boolean);
var
    done : boolean;
begin
    done := false;
	 case Msg.message of
		 WM_MOUSEMOVE : begin
			 done := (Abs(LOWORD(Msg.lParam) - crs.x) > 5) or (Abs(HIWORD(Msg.lParam) - crs.y) > 5);
		 end;
		 WM_KEYDOWN, WM_ACTIVATE, WM_ACTIVATEAPP, WM_NCACTIVATE, WM_LBUTTONUP, WM_LBUTTONDOWN, WM_MOUSEWHEEL : begin
            done := True;
        end;
        WM_QUIT : begin
			 //Self.LockWinStation;
		 end;
		 else begin
		 //nada a fazer
		 end;
	 end;
	  if done then begin
		  PostMessage(Self.Handle, WM_CLOSE, 0, 0);
		  Self.LockWinStation;
	  end;
end;

destructor TFormMain.Destroy;
begin
    Screen.Cursor := FLastCursor;
    inherited;
end;

procedure TFormMain.FormShow(Sender : TObject);
begin
    GetCursorPos(crs); //Registra posição inicial do mouse para travar a sensibilidade
	 Application.OnMessage := DeactivateScrnSaver; //trata eventos para disparo do bloqueio
    //Alavanca a janela para ser a mais visivel
	 Application.BringToFront;
    SetForegroundWindow(Self.Handle);
end;

procedure TFormMain.LockWinStation;
begin
    //Application.ProcessMessages;
    keybd_event(VK_LWIN, $9d, 0, 0);
    keybd_event(VkKeyScan('L'), $9e, 0, 0);
    keybd_event(VkKeyScan('L'), $9e, KEYEVENTF_KEYUP, 0);
    keybd_event(VK_LWIN, $9d, KEYEVENTF_KEYUP, 0);
end;

procedure TFormMain.tmrMainTimer(Sender : TObject);
begin
    Inc(Self.FPassCount);
    Self.scrlngcrdts1.Credits.Text := Format('%s'#13#10'%s', [GetUserName(), FormatDAteTime('dd/mm/yyy - hh:mm:ss', Now())]);
    Self.scrlngcrdts1.Align := alClient;
end;

end.
