unit mainDemoForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, OleCtrls, SHDocVw, ExtCtrls;

type
    TForm1 = class(TForm)
        wbBrowser : TWebBrowser;
        pnlBottom : TPanel;
        btnLoad :   TBitBtn;
        btnTest :   TBitBtn;
    btnStep2: TBitBtn;
        procedure btnLoadClick(Sender : TObject);
        procedure btnTestClick(Sender : TObject);
    procedure btnStep2Click(Sender: TObject);
    private
        { Private declarations }
        procedure ProcessMatCPFForm( const Matric, StrCPF : string );
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnLoadClick(Sender : TObject);
begin
    Self.wbBrowser.Navigate('http://www.faciltecnologia.com.br:81/pbconsig/');
end;

procedure TForm1.btnStep2Click(Sender: TObject);
begin
     Self.ProcessMatCPFForm('6938213', '45294895404');
end;

procedure TForm1.btnTestClick(Sender : TObject);
var
    FormItem :  variant;
    Field :     variant;
    SendButton : Variant;
    FieldName : string;
    I, J :      Integer;
begin
    if Self.wbBrowser.OleObject.Document.all.tags('FORM').Length = 0 then begin
        Exit;
    end;

    SendButton:=Variants.Null;
    for I := 0 to Self.wbBrowser.OleObject.Document.Forms.Length - 1 do begin
        FormItem := Self.wbBrowser.OleObject.Document.Forms.Item(I);
        try
            for j := 0 to FormItem.Length - 1 do begin
                //Identifica o campo e seu nome no formulário
                Field     := FormItem.Item(j);
                FieldName := Field.Name;

                if FieldName = 'usuario' then begin// nome do input para o campo usuario
                    Field.Value := 'rb.financiamentos';
                end;
                if FieldName = 'senha' then begin// nome do input para o campo senha
                    Field.Value := '131313';
                end;
                if FieldName = 'btnentrar' then begin
                   SendButton:=FormItem.Item(j);
                end;
            end
        except
            ShowMessage('Não foi possível identificar os campos para atribuir os valores de usuário e senha');
        end;
    end;
    if not VarIsNull( SendButton ) then begin
       SendButton.Click();
       //Esperar pelo resultado da consulta????
       while ( Self.wbBrowser.Busy ) or ( Self.wbBrowser.ReadyState <> READYSTATE_COMPLETE ) do begin
             Application.ProcessMessages();
             {TODO -oroger -cdsg : Colocar limite de espera}
       end;
       Self.ProcessMatCPFForm('6938213', '45294895404');
    end;
end;

procedure TForm1.ProcessMatCPFForm(const Matric, StrCPF: string);
var
    FormItem :  variant;
    Field :     variant;
    SendButton : Variant;
    FieldName : string;
    I, J :      Integer;
begin

     //url = http://www.faciltecnologia.com.br:81/pbconsig/consigfacil.php?pagina=busca_servidor_consignatario.php

    if Self.wbBrowser.OleObject.Document.all.tags('FORM').Length = 0 then begin
        Exit;
    end;

    SendButton:=Variants.Null;
    for I := 0 to Self.wbBrowser.OleObject.Document.Forms.Length - 1 do begin
        FormItem := Self.wbBrowser.OleObject.Document.Forms.Item(I);
        try
            for j := 0 to FormItem.Length - 1 do begin
                //Identifica o campo e seu nome no formulário
                Field     := FormItem.Item(j);
                FieldName := Field.Name;

                if FieldName = 'matricula' then begin// nome do input para o campo usuario
                    Field.Value := Matric;
                end;
                if FieldName = 'cpf' then begin// nome do input para o campo senha
                    Field.Value := StrCPF;
                end;
                if ( FieldName = '' ) or ( FieldName = 'Pesquisar' ) then begin
                   SendButton:=FormItem.Item(j);
                end;
            end
        except
            ShowMessage('Não foi possível identificar os campos para atribuir os valores de usuário e senha');
        end;
    end;
    if not VarIsNull( SendButton ) then begin
       SendButton.Click();
    end;
end;

end.
