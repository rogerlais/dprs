unit adumFrameStatusOperation;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs,  StdCtrls, ComCtrls, Buttons;

type
  TFrameStatusOperation = class(TFrame)
    lblStatus: TLabel;
    pbStatus: TProgressBar;
    btnCancel: TBitBtn;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

end.
