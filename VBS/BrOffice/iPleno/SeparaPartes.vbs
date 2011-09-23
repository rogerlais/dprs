REM  *****  BASIC  *****

REM ***************************************************************************
REM Módulo: SeparaPartes
REM Autor: Rogerlais Andrade e Silva
REM Versão 0.9.2011.2 - 20110921
REM ***************************************************************************
REM Comentarios:
REM Separa as partes de arquivo monolitico nas seguintes partes:
REM 1 - Relatorio: Inicia-se no começo do documento até o aparacimento do 1o token separador
REM 2 - Preliminar(n): Inicia-se após qualquer token denominado "preliminar" e se encerrar ao encontrar qualquer outro, sendo que este pode ser encontrado mais de uma vez
REM 3 - Voto: Inicia-se após o token denominado "voto" e vai até o final do documento
REM ***************************************************************************



private S_DOC_NONE as String
private  S_TOKEN_PRELIMINAR, S_TOKEN_VOTE, S_CURRENT_DOC_PATH, APP_NAME, oUrlSrc as String

Sub SeparaPartes

	'Definição das "constantes"
	B_DEBUG_MODE = true	'Flag global de depuração !!!!Mudar na versão final
	S_TOKEN_PRELIMINAR = "##Preliminar"
	S_TOKEN_VOTE = "##Voto"
	APP_NAME = "iPleno Splitter"
	S_CURRENT_DOC_PATH = "pqp"
	S_DOC_NONE = ""
	

	'Carga das libs requeridas globalmente
	GlobalScope.BasicLibraries.LoadLibrary( "Tools" ) 

 	iPreliminarCount = 0

	oUrlSrc  = fSelectFile()
	If oUrlSrc = S_DOC_NONE Then 
		msgBox "Operação cancelada pelo usuário", 0, APP_NAME
		Exit Sub
	Else	'Houve seleção de processamento
		If oUrlSrc <> S_CURRENT_DOC_PATH Then 'Abre o documento de origem
			oOldPos = null
			Dim aProps(0) As New com.sun.star.beans.PropertyValue
			aProps(0).Name  = "Hidden"
			aProps(0).Value = not B_DEBUG_MODE	'*** Pode ser ajustado para true de modo a naum poluir a tela
			oDocSrc  = StarDesktop.loadComponentFromURL(oUrlSrc, "_blank", 0, aProps())			     		
		Else 'Usa o documento aberto
			oDocSrc = ThisComponent	
			If oDocSrc.URL = "" Then 
				msgBox "O documento ativo deve ser salvo ao menos uma vez", 0, APP_NAME
				Exit Sub
			End If
			oOldPos = oDocSrc.Text.createTextCursor				
		End If
	End If
	
	'Salva ponto de retorno par após processamento
	oVCursSrc   = oDocSrc.CurrentController.getViewCursor()
	
	oVCursSrc.gotoStart(False)	'Garante inicio do documento 
	
	'Variaveis de manipulacao
	sFileName = GetFileNameWithoutExtension( FileNameoutofPath( oDocSrc.URL, "/" ) )
	sOutURL = DirectoryNameoutofPath( oDocSrc.URL, "/" )
	
	'Navega pelos paragrafos do documento fonte
	oParEnum = oDocSrc.Text.createEnumeration()
	segFirstParag = oParEnum.nextElement()
	segLastParag = null
	lastPieceName = "relatorio"
	Do While oParEnum.hasMoreElements()
		curParag = oParEnum.nextElement() 	
		If fnTokenFound( curParag, S_TOKEN_PRELIMINAR ) or fnTokenFound( curParag, S_TOKEN_VOTE ) Then
		
			'Salva relatorio se for o caso
			If lastPieceName = "relatorio" Then
				SavePiece( sFilename, "_relatorio",  sOutURL, segFirstParag, segLastParag, oDocSrc, oVCursSrc )
				If fnTokenFound( curParag, S_TOKEN_VOTE ) Then	'Diferencia parte final
					lastPieceName = "voto"
				Else 
					lastPieceName = "preliminar"
				End If								
				curParag = oParEnum.nextElement() 'Pula token
				segFirstParag = curParag	'primeiro paragrafo serah o seguinte
				oVCursSrc.gotoRange(segFirstParag, false )									
				segLastParag = curParag
			End If
		
			If fnTokenFound( curParag, S_TOKEN_PRELIMINAR ) Then
				If lastPieceName = "preliminar" Then
					iPreliminarCount = iPreliminarCount + 1
					SavePiece( sFilename, "_preliminar_" & iPreliminarCount,  sOutURL, segFirstParag, segLastParag, oDocSrc, oVCursSrc )
					
					oVCursSrc.getEnd()
					curParag = oParEnum.nextElement() 'Pula token
					segFirstParag = curParag	'primeiro paragrafo serah o seguinte
					oVCursSrc.gotoRange(segFirstParag, false )									
					segLastParag = curParag
				End If			
			End If				
			
			If fnTokenFound( curParag, S_TOKEN_VOTE ) Then
				If lastPieceName = "preliminar" Then
					iPreliminarCount = iPreliminarCount + 1
					SavePiece( sFilename, "_preliminar_" & iPreliminarCount,  sOutURL, segFirstParag, segLastParag, oDocSrc, oVCursSrc )

					curParag = oParEnum.nextElement() 'Pula token
					segFirstParag = curParag	'primeiro paragrafo serah o seguinte
					oVCursSrc.gotoRange(segFirstParag, false )									
					segLastParag = curParag
				Else						
					lastPieceName = "voto"
					curParag = oParEnum.nextElement() 'Pula token
					segFirstParag = curParag	'primeiro paragrafo serah o seguinte, busca apenas o final do documento para computar o voto
				End If
			End If
		Else
			segLastParag = curParag			
		End If	
	Loop
	
	'Parte final do documento - assume = VOTO
	If isNull(segLastParag) or ( lastPieceName <> "voto" ) Then
		msgBox "O documento não possui os marcadores esperados", 0, APP_NAME 
	Else
		SavePiece( sFilename, "_voto",  sOutURL , segFirstParag, segLastParag, oDocSrc, oVCursSrc )
	End If
		 
	If oOldPos <> null Then
		oDocSrc.close(true)
	Else 
		oVCursSrc.gotoRange( oOldPos, False )
	End If

End Sub


REM *************************************************************
REM Identifica o documento de origem para o processamento das partes
REM Caso seja o documento atual o retorno será "."
REM Caso seja selecionado outro, retorno será o caminho/url do documento
REM Havendo cancelamento, string vazia
REM *************************************************************
function fSelectFile() as String
	'Exibe dialogo com SIM-NÃO-CANCELAR solcitando origem
	fSelectFile = S_DOC_NONE	'Nenhum documento selecionado ate o momento(retorno para CANCELAR)
	docSelect = msgbox ( "Separar as peças do documento corrente?", 3 + 32 + 256, "Origem das partes")
	select case docSelect	
		case 6	'Sim - confirmar salvamento anterior	
			'msgbox "Informado o documento atual", 0, APP_NAME
			fSelectFile = S_CURRENT_DOC_PATH	
		case 7	' Não - Selecionar documento origem
			fSelectFile =  fOpenFile()
	end select
End Function 


REM *************************************************************
REM Invoca dialogo de abertura de arquivo
REM Ajusta máscara para tipos suportados
REM Caminho inicial U:\ para o caso de não haver documento para referência
REM *************************************************************
Function fOpenFile() as String

   Dim oFileDialog as Object
   Dim iAccept as Integer
   Dim sPath as String
   Dim InitPath as String
   Dim oUcb as object
   Dim filterNames(4) as String

   filterNames(0) = "*.odt;*.rtf;*.doc;*.docx"
   filterNames(1) = "*.odt"
   filterNames(2) = "*.doc"
   filterNames(3) = "*.rtf"

   'GlobalScope.BasicLibraries.LoadLibrary("Tools") ***Carregada globalmente no inicio da macro
   oFileDialog = CreateUnoService("com.sun.star.ui.dialogs.FilePicker")
   oUcb = createUnoService("com.sun.star.ucb.SimpleFileAccess")

   AddFiltersToDialog(FilterNames(), oFileDialog)
   'Ajusta caminho inicial do dialogo
   If ThisComponent.URL <> "" Then 'O local mais recentemente usado sera selecionado
   		InitPath = DirectoryNameoutofPath( ThisComponent.URL, "/" )	
   Else   'Usa o caminho da unidade de rede padrão
   	    InitPath = ConvertToUrl( "U:\" )	
   End If

   If oUcb.Exists(InitPath) Then
      oFileDialog.SetDisplayDirectory(InitPath)
   End If

   iAccept = oFileDialog.Execute()
   If iAccept = 1 Then
      sPath = oFileDialog.Files(0)
      fOpenFile = sPath
   Else 
   	  fOpenFile = ""
   End If
   oFileDialog.Dispose()

End Function



REM *************************************************************
REM Salva documento com o nome de arquivo dos paragrafos de inicio e fim
REM *************************************************************
Function SavePiece( filename, sufix, dirName as String, startParag, endParag, srcDoc, srcVC  as Object ) As boolean
	'Cria novo documento
	Dim aProps(0) As New com.sun.star.beans.PropertyValue
	aProps(0).Name  = "Hidden"
	aProps(0).Value = not B_DEBUG_MODE	'*** Pode ser ajustado para true de modo a naum poluir a tela
	oUrl     = "private:factory/swriter"
	oDocDest     = StarDesktop.loadComponentFromURL(oUrl, "_blank", 0, aProps )
	oVCursDest   = oDocDest.CurrentController.getViewCursor()     
	
  	If startParag.supportsService("com.sun.star.text.Paragraph") and endParag.supportsService("com.sun.star.text.Paragraph") Then
		srcVC.gotoRange(startParag, false )
	  	srcVC.gotoRange(endParag, true )
	  	oDocDest.CurrentController.insertTransferable(srcDoc.CurrentController.getTransferable())
	  	oVCursDest.gotoEnd(false)
	  	oDocDest.Text.insertControlCharacter(oVCursDest, com.sun.star.text.ControlCharacter.PARAGRAPH_BREAK, false )	
	End If  
    oDocDest.Text.insertControlCharacter(oVCursDest, com.sun.star.text.ControlCharacter.PARAGRAPH_BREAK, false)
	
	destURL = dirName & "/" & filename & sufix & ".rtf"
	propVal = MakePropertyValue( "FilterName", "Rich Text Format" )
	oDocDest.storeToURL( destURL, Array( propVal ) )
	oDocDest.close(true)

End Function


REM *************************************************************
REM localiza no paragrafo o token passado
REM *************************************************************
Function fnTokenFound( ByRef oPar As Enumeration, ByRef token As String ) As Boolean
	result = false
	If oPar.supportsService("com.sun.star.text.Paragraph") Then	
		compEnum = oPar.createEnumeration()
		Do While compEnum.hasMoreElements()
			t = compEnum.nextElement
			result = ( t.String = token )
			If result Then
				Exit Do
			End If
		Loop
	End If
	fnTokenFound = result
End Function

REM *************************************************************
REM Monta estrutura de par/propriedade
REM *************************************************************
Function MakePropertyValue( Optional cName As String, Optional uValue ) As com.sun.star.beans.PropertyValue
   oPropertyValue = createUnoStruct( "com.sun.star.beans.PropertyValue" )
   If Not IsMissing( cName ) Then
      oPropertyValue.Name = cName
   EndIf
   If Not IsMissing( uValue ) Then
      oPropertyValue.Value = uValue
   EndIf
   MakePropertyValue() = oPropertyValue
End Function 