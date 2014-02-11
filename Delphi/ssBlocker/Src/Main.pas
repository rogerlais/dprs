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
        procedure FormMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);
        procedure FormMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
        procedure FormShow(Sender : TObject);
        procedure tmrMainTimer(Sender : TObject);
        procedure FormCloseQuery(Sender : TObject; var CanClose : boolean);
    private
        { Private declarations }
        FFirstMouseMove : boolean;
        FOldMouseX : Integer;
        FOldMouseY : Integer;
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
    WinNetHnd;

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
    if Msg.message = WM_MOUSEMOVE then begin
        done := (Abs(LOWORD(Msg.lParam) - crs.x) > 5) or (Abs(HIWORD(Msg.lParam) - crs.y) > 5);
    end else begin
        done := (Msg.message = WM_KEYDOWN) or (Msg.message = WM_ACTIVATE) or (Msg.message = WM_ACTIVATEAPP) or
            (Msg.message = WM_NCACTIVATE);
    end;
    if done then begin
        Self.LockWinStation;
        Close;
    end;
end;

destructor TFormMain.Destroy;
begin
    Screen.Cursor := FLastCursor;
    inherited;
end;

procedure TFormMain.FormMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);
const
    Sensitivity = 2;
begin
    // ignore the very first mouse move
    // this event seems to happen once even if the mouse doesn't move
    if FFirstMouseMove then begin
        FFirstMouseMove := False;
        FOldMouseX      := X;
        FOldMouseY      := Y;
    end else begin
        if (Abs(FOldMouseX - X) > Sensitivity) or (Abs(FOldMouseY - Y) > Sensitivity) then begin
            Self.Close;
        end;
    end;
end;

procedure TFormMain.FormShow(Sender : TObject);
begin
    GetCursorPos(crs);
    Application.OnMessage := DeactivateScrnSaver;
end;

procedure TFormMain.LockWinStation;
begin
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

procedure TFormMain.FormCloseQuery(Sender : TObject; var CanClose : boolean);
begin
	 Application.ProcessMessages;
	 {TODO -oroger -cdsg : diferenciar do modo preview(ver rotina de entrada) para evitar bloqueio }
    Self.LockWinStation();
end;

procedure TFormMain.FormMouseDown(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
begin
    Close;
end;

end.
