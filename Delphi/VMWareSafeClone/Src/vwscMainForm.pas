unit vwscMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TVMCloneMainForm = class(TForm)
    ExecBtn: TButton;
    ComputerNameEdit: TLabeledEdit;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  VMCloneMainForm: TVMCloneMainForm;

implementation

{$R *.dfm}

procedure TVMCloneMainForm.FormCreate(Sender: TObject);
begin
	{TODO -oroger -cdsg : Ajustar caption de acordo com a versão}
	Self.ComputerNameEdit.Text:=GetComputerName();
end;

end.
