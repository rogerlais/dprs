unit wpMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Buttons;

type
  TForm1 = class(TForm)
    pnlBottom: TPanel;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    pgcMain: TPageControl;
    tsInfo: TTabSheet;
    ledtZonNumber: TLabeledEdit;
    ledtWksId: TLabeledEdit;
    memoResult: TMemo;
    lblResult: TLabel;
    cbbNetAdapter: TComboBox;
    lblNetAdapter: TLabel;
    chkUseDHCP: TCheckBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

end.
