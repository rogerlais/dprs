unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, JvComponentBase, JvMRUList, ComCtrls, JvExStdCtrls, JvButton, JvRecentMenuButton;

type
  TForm1 = class(TForm)
    grpHost: TGroupBox;
    cbbHosts: TComboBox;
    lblCombooHosts: TLabel;
    cbbIPHost: TComboBox;
    lblIPHost: TLabel;
    lblUsers: TLabel;
    cbbUsers: TComboBox;
    btnLaunch: TBitBtn;
    btnRecentListHost: TJvRecentMenuButton;
    cbbTest: TComboBoxEx;
    mrlstHost: TJvMruList;
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
