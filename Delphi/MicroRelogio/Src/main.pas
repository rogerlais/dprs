unit main;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
    ExtCtrls, StdCtrls, OleServer, Word2000, JvComponentBase, JvScreenSaveSuppress;

type
    TForm1 = class(TForm)
        lblHora :       TLabel;
        Timer1 :        TTimer;
        lblData :       TLabel;
        scrSuppressor : TJvScreenSaveSuppressor;
        procedure Timer1Timer(Sender : TObject);
        procedure FormKeyPress(Sender : TObject; var Key : char);
        procedure FormShow(Sender : TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

{$R *.DFM}

procedure TForm1.Timer1Timer(Sender : TObject);
begin
    lblData.Caption := FormatDateTime('dd/mm/yy', date);
    lblHora.Caption := FormatDateTime('hh:mm', time);
    keybd_event(VK_NUMLOCK, $45, KEYEVENTF_EXTENDEDKEY, 0);
    Sleep(400);
    keybd_event(VK_NUMLOCK, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);
end;

procedure TForm1.FormKeyPress(Sender : TObject; var Key : char);
begin
    if key = #27 then begin
        Self.Close;
    end;
end;

procedure TForm1.FormShow(Sender : TObject);
begin
    lblData.Caption   := FormatDateTime('dd/mm/yy', date);
    lblHora.Caption   := FormatDateTime('hh:mm', time);
    lblData.Font.Size := 150;
    lblHora.Font.Size := 400;

    lblData.Top := (screen.Height - lblHora.Height - lblData.Height - 10) div 2;
    lblHora.Top := (screen.Height - lblHora.Height - lblData.Height - 10) div 2 + lblData.Height + 10;

    lblData.Left := (screen.Width - lblData.Width) div 2;
    lblHora.Left := (screen.Width - lblHora.Width) div 2;

end;

end.
