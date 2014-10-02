@echo off
:chk
ping -n 1 %1 | find /I "Reply from" 
if not errorlevel 1 goto start
ping -n 1 %1 | find /I "Resposta de" 
if not errorlevel 1 goto start
ping -n 2 127.0.0.1 > nul
goto chk
:start
%2 %3 %4 %5 %6 %7 %8 %9
