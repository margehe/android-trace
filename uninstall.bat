@echo off
setlocal EnableDelayedExpansion

set "parserTrace=%~dp0parserTrace.bat"
set "perfettoRecord=%~dp0perfettoRecord.bat"
set "systraceRecord=%~dp0systraceRecord.bat"
set "endConfigsTrace=%~dp0endConfigTrace.bat"
set "delFile=%~dp0delReg.reg"

REM ��������ע���
echo %delFile%
echo Windows Registry Editor Version 5.00>%delFile%
echo.>>%delFile%
echo [-HKEY_CLASSES_ROOT\*\shell\parserTrace]>>%delFile%
echo [-HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools]>>%delFile%
echo [-HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools]>>%delFile%

c:\windows\regedit -s %delFile%

REM ɾ���ļ�
del %delFile%  %parserTrace% %perfettoRecord% %systraceRecord% %endConfigsTrace%
echo uninstall end
pause
