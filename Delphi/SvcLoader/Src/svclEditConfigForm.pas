unit svclEditConfigForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TEditConfigForm = class(TForm)
    pnlBottom: TPanel;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EditConfigForm: TEditConfigForm;

implementation

{$R *.dfm}

end.
