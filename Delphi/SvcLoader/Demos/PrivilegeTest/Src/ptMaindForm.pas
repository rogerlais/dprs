unit ptMaindForm;

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls;

type
	TForm2 = class(TForm)
		lstPrivelege: TListBox;
		btnReadPrivileges: TButton;
		procedure btnReadPrivilegesClick(Sender: TObject);
	private
		{ Private declarations }
	public
		{ Public declarations }
	end;

var
	Form2: TForm2;

implementation

uses
	JwaWindows, JwsclToken;

{$R *.dfm}

procedure TForm2.btnReadPrivilegesClick(Sender: TObject);
var
	PrivList: TJwPrivilegeSet;
	priv    : TJwPrivilege;
	I       : Integer;
begin
	PrivList := TJwPrivilegeSet.Create();
	try
		PrivList.Create_PPRIVILEGE_SET;
		priv := PrivList.PrivByName[SE_IMPERSONATE_NAME];
		Self.lstPrivelege.AddItem(PrivList.GetText, nil);
		for I := 0 to PrivList.Count - 1 do begin
			Self.lstPrivelege.AddItem(PrivList.PrivByIdx[I].GetText, nil);
		end;
	finally
		PrivList.Free;
	end;
end;

end.
