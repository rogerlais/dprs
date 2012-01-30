unit ptMaindForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls;

type
    TForm2 = class(TForm)
        lstPrivelege :      TListBox;
        btnReadPrivileges : TButton;
        procedure btnReadPrivilegesClick(Sender : TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    Form2 : TForm2;

implementation

uses
    JwsclToken;

{$R *.dfm}

procedure TForm2.btnReadPrivilegesClick(Sender : TObject);
var
    PrivList : TJwPrivilegeSet;
    I : Integer;
begin
    PrivList := TJwPrivilegeSet.Create();
    Self.lstPrivelege.AddItem(PrivList.GetText, nil);
    for I := 0 to PrivList.Count - 1 do begin
        Self.lstPrivelege.AddItem(PrivList.PrivByIdx[i].GetText, nil);
    end;
end;

end.
