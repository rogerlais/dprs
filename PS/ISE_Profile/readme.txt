Resummo:

//------------------------------
Understanding the Profiles

You can have four different profiles in Windows PowerShell. The profiles are listed in load order. 
The most specific profiles have precedence over less specific profiles where they apply.

    %windir%\system32\WindowsPowerShell\v1.0\profile.ps1 -> This profile applies to all users and all shells.

    %windir%\system32\WindowsPowerShell\v1.0\ Microsoft.PowerShell_profile.ps1 -> This profile applies to all users, but only to the Microsoft.PowerShell shell.

    %UserProfile%\My Documents\WindowsPowerShell\profile.ps1 -> This profile applies only to the current user, but affects all shells.

    %UserProfile%\My Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -> This profile applies only to the current user and the Microsoft.PowerShell shell.
//------------------------------

Carga automática de extensões do ISE
Para atualizar execute updateProfile.ps1


Informações adicionais podem ser obtidas em https://msdn.microsoft.com/en-us/library/bb613488%28v=VS.85%29.aspx