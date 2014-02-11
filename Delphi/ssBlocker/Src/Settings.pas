{$IFDEF Settings}
	  {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I ssBlocker.inc}

unit Settings;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtDlgs, ExtCtrls;

type
    TFormSettings = class(TForm)
        Label1 :    TLabel;
    	 btnCancel: TBitBtn;
		 procedure btnCancelClick(Sender : TObject);
	 private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    FormSettings : TFormSettings;

implementation

{$R *.dfm}

procedure TFormSettings.btnCancelClick(Sender : TObject);
begin
    Close;
end;

end.
