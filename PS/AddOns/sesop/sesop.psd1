#
# Manifesto de módulo para o módulo 'sesop'
#
# Gerado por: Rogerlais Andrade e Silva
#
# Gerado em: 22/01/2016
#

@{

	# Script module or binary module file associated with this manifest
	#ModuleToProcess = @('ISEUtils.psm1', 'RemoteSupport.psm1' )

	# Arquivo de módulo de script ou módulo binário associado a este manifesto.
	# RootModule = ''

	# Número da versão deste módulo.
	ModuleVersion = '0.1.1.0'

	# ID usada para identificar este módulo de forma exclusiva
	GUID = '24d8b381-8cc4-4dea-803e-85c2e6c1067b'

	# Autor deste módulo
	Author = 'Rogerlais Andrade e Silva'

	# Empresa ou fornecedor deste módulo
	CompanyName = 'TRE-PB/STI/COSUP/SESOP'

	# Instrução de direitos autorais para este módulo
	Copyright = '(c) 2016 Rogerlais Andrade e Silva. Todos os direitos reservados.'

	# Descrição da funcionalidade fornecida por este módulo
	Description = 'Utils for PS-ISE(SESOP)'

	# A versão mínima do mecanismo do Windows PowerShell exigida por este módulo
	PowerShellVersion = '4.0'

	# Nome do host do Windows PowerShell exigido por este módulo
	PowerShellHostName = ''

	# A versão mínima do host do Windows PowerShell exigida por este módulo
	PowerShellHostVersion = ''

	# Versão mínima do Microsoft .NET Framework exigida por este módulo
	DotNetFrameworkVersion = '3.5'

	# A versão mínima do CLR (Common Language Runtime) exigida por este módulo
	CLRVersion = ''

	# Arquitetura de processador (None, X86, Amd64, IA64) exigida por este módulo
	# ProcessorArchitecture = ''

	# Módulos que devem ser importados para o ambiente global antes da importação deste módulo
	RequiredModules = @()

	# Assemblies que devem ser carregados antes da importação deste módulo
	RequiredAssemblies = @()

	# Arquivos de script (.ps1) executados no ambiente do chamador antes da importação deste módulo.
	ScriptsToProcess = @()
	
	# Arquivos de tipo (.ps1xml) a serem carregados durante a importação deste módulo
	TypesToProcess = @()

	# Arquivos de formato (.ps1xml) a serem carregados na importação deste módulo
	FormatsToProcess = @()

	# Módulos para importação como módulos aninhados do módulo especificado em RootModule/ModuleToProcess
	# NestedModules = @()
    NestedModules =@('RemoteSupport.psm1', 'ISEUtils.psm1', 'Prompts.psm1')

	# Funções a serem exportadas deste módulo
    #FunctionsToExport = '*'
    <# Deixando esta estrada vazia implica em todo o módulo exportar explicitamente seus membros(método preferido)
	FunctionsToExport = @(        
        'Save-IseSession',
        'Restore-IseSession',
        'Set-VNCState'        
        )
    #>
	# Cmdlets a serem exportados deste módulo
	CmdletsToExport = 'Get-ChoiceYesNo'

	# Variáveis a serem exportadas deste módulo
	VariablesToExport = ''

	# Aliases a serem exportados deste módulo
	AliasesToExport = '*'

	# Lista de todos os módulos empacotados com este módulo
	ModuleList = @()

	# Lista de todos os arquivos incluídos neste módulo
	FileList = @()

	# Dados particulares a serem transmitidos ao módulo especificado em RootModule/ModuleToProcess
	PrivateData = ''

	# URI de HelpInfo deste módulo
	# HelpInfoURI = ''

	# Prefixo padrão dos comandos exportados deste módulo. Substitua o prefixo padrão usando Import-Module -Prefix.
	# DefaultCommandPrefix = ''

}

