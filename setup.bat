@echo off
setlocal EnableDelayedExpansion

REM ���ɽ��� trace ��ץȡ trace �� bat �ű�
set "parserTxt=%~dp0src\parser.txt"
set "perfettoRecordTxt=%~dp0src\perfettoRecord.txt"
set "systraceRecordTxt=%~dp0src\systraceRecord.txt"
echo %parserTxt%
::pause
set "parserTrace=%~dp0parserTrace.bat"
set "perfettoRecord=%~dp0perfettoRecord.bat"
set "systraceRecord=%~dp0systraceRecord.bat"
set "endConfigsTrace=%~dp0endConfigTrace.bat"
set "tempFile=%~dp0temp.bat"

set CONFIG_DIR=%~dp0config
set END_PERF_CONFIG=%CONFIG_DIR%\perf_config\end_setup.bat

set "set_author=author: No.18649335"
set "set_version=version: 2023/6/23 V_0.1"
set "set_desp=˵���ĵ�: https://transsioner.feishu.cn/docx/ELf0dPo4Ho06BHxLSE5c3vI1nvc"


REM ���� %parserTrace%
REM ��ָ��������ӵ���ʱ�ļ�
(
echo @echo off
echo mode con cols=140 lines=40 ^&title parserTrace
echo set Author=%set_author%
echo set toolversion=%set_version%
echo set rerf_desc=%set_desp%
echo rem set env
echo set SRCPATH=%~dp0src
echo set PYTHONHOME=%~dp0python310
echo set ADBPATH=%~dp0platform-tools
echo set PATH="%%ADBPATH%%";"%%PYTHONHOME%%";"%%PYTHONHOME%%\Scripts";%%PATH%%
) > "%tempFile%"
REM �� "%parserTxt% ������׷�ӵ���ʱ�ļ�
type "%parserTxt%" >> "%tempFile%"
REM ����ʱ�ļ��������ƶ��� "%parserTrace%"
move /Y "%tempFile%" "%parserTrace%"
echo ָ�������Ѿ��ɹ���ӵ� %parserTrace% �Ŀ�ͷ.

REM ���� %perfettoRecord%
REM ��ָ��������ӵ���ʱ�ļ�
(
echo @echo off
echo mode con cols=140 lines=40 ^&title perfettoRecord
echo set Author=%set_author%
echo set toolversion=%set_version%
echo set rerf_desc=%set_desp%
echo rem set env
echo set SRCPATH=%~dp0src
echo set PYTHONHOME=%~dp0python310
echo set ADBPATH=%~dp0platform-tools
echo set PATH="%%ADBPATH%%";"%%PYTHONHOME%%";"%%PYTHONHOME%%\Scripts";%%PATH%%
echo set BIN_DIR=%~dp0bin
echo set CONFIG_DIR=%~dp0config
) > "%tempFile%"
REM �� %perfettoRecordTxt% ������׷�ӵ���ʱ�ļ�
type "%perfettoRecordTxt%" >> "%tempFile%"
REM ����ʱ�ļ��������ƶ��� "%perfettoRecord%"
move /Y "%tempFile%" "%perfettoRecord%"
echo ָ�������Ѿ��ɹ���ӵ� %perfettoRecord% �Ŀ�ͷ.


REM ���� %systraceRecord%
REM ��ָ��������ӵ���ʱ�ļ�
(
echo @echo off
echo mode con cols=140 lines=40 ^&title systraceRecord
echo set Author=%set_author%
echo set toolversion=%set_version%
echo set rerf_desc=%set_desp%
echo rem global set
echo rem tool version
echo ::env var set
echo set SRCPATH=%~dp0src
echo set PYTHONHOME=%~dp0Python27
echo set PYTHONPATH=%~dp0Python27
echo set ANDROID_HOME=%~dp0platform-tools
echo set BIN_DIR=%~dp0bin
echo set CONFIG_DIR=%~dp0config
) > "%tempFile%"
REM �� %systraceRecordTxt% ������׷�ӵ���ʱ�ļ�
type "%systraceRecordTxt%" >> "%tempFile%"
REM ����ʱ�ļ��������ƶ��� "%systraceRecord%"
move /Y "%tempFile%" "%systraceRecord%"
echo ָ�������Ѿ��ɹ���ӵ� %systraceRecord% �Ŀ�ͷ.


REM ���ɻظ����õ��ļ�
echo REM �ָ����� > %endConfigsTrace%
echo call %END_PERF_CONFIG% >> %endConfigsTrace%

REM �����Ҽ�ע���
set "regFile=%~dp0setReg.reg"
echo %regFile%
::pause

echo Windows Registry Editor Version 5.00>%regFile%
echo.>>%regFile%

REM �����ļ����Ҽ� (���trace)
echo [HKEY_CLASSES_ROOT\*\shell\parserTrace]>>%regFile%
echo @="aTrace ���">>%regFile%
echo [HKEY_CLASSES_ROOT\*\shell\parserTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\*\shell\parserTrace\command" /ve /t REG_EXPAND_SZ /d "\"%parserTrace%\" \"%%L\"" /f

REM Ŀ¼���Ҽ� (Transs_PerfTools)
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools]>>%regFile%
echo "SubCommands"="">>%regFile%
REM Ŀ¼���Ҽ� (���trace)
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\parserTrace]>>%regFile%
echo @="aTrace ���">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\parserTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\parserTrace\command" /ve /t REG_EXPAND_SZ /d "\"%parserTrace%\" \"%%V\"" /f
REM Ŀ¼���Ҽ� (ץȡ pefetto trace)
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\pefettoRecordTrace]>>%regFile%
echo @="perfettoTrace ץȡ">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\pefettoRecordTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\pefettoRecordTrace\command" /ve /t REG_EXPAND_SZ /d "\"%perfettoRecord%\" \"%%V\"" /f
REM Ŀ¼���Ҽ� (ץȡ systrace trace)
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\systraceRecordTrace]>>%regFile%
echo @="systraceTrace ץȡ">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\systraceRecordTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\systraceRecordTrace\command" /ve /t REG_EXPAND_SZ /d "\"%systraceRecord%\" \"%%V\"" /f

REM Ŀ¼�հ������Ҽ� (Transs_PerfTools)
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools]>>%regFile%
::echo @="Transs_PerfTools">>%regFile%
echo "SubCommands"="">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell]>>%regFile%
REM Ŀ¼�հ������Ҽ� (���trace)
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\parserTrace]>>%regFile%
echo @="aTrace ���">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\parserTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\parserTrace\command" /ve /t REG_EXPAND_SZ /d "\"%parserTrace%\" \"%%V\"" /f
REM Ŀ¼�հ������Ҽ� (ץȡ pefetto trace)
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\pefettoRecordTrace]>>%regFile%
echo @="perfettoTrace ץȡ">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\pefettoRecordTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\pefettoRecordTrace\command" /ve /t REG_EXPAND_SZ /d "\"%perfettoRecord%\" \"%%V\"" /f
REM Ŀ¼�հ������Ҽ� (ץȡ systrace trace)
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\systraceRecordTrace]>>%regFile%
echo @="systraceTrace ץȡ">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\systraceRecordTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\systraceRecordTrace\command" /ve /t REG_EXPAND_SZ /d "\"%systraceRecord%\" \"%%V\"" /f

c:\windows\regedit -s %regFile%
del %regFile%
echo setup end
pause
