@echo off
setlocal EnableDelayedExpansion

REM 生成解析 trace 和抓取 trace 的 bat 脚本
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
set "set_desp=说明文档: https://transsioner.feishu.cn/docx/ELf0dPo4Ho06BHxLSE5c3vI1nvc"


REM 生成 %parserTrace%
REM 将指定内容添加到临时文件
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
REM 将 "%parserTxt% 的内容追加到临时文件
type "%parserTxt%" >> "%tempFile%"
REM 将临时文件的内容移动回 "%parserTrace%"
move /Y "%tempFile%" "%parserTrace%"
echo 指定内容已经成功添加到 %parserTrace% 的开头.

REM 生成 %perfettoRecord%
REM 将指定内容添加到临时文件
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
REM 将 %perfettoRecordTxt% 的内容追加到临时文件
type "%perfettoRecordTxt%" >> "%tempFile%"
REM 将临时文件的内容移动回 "%perfettoRecord%"
move /Y "%tempFile%" "%perfettoRecord%"
echo 指定内容已经成功添加到 %perfettoRecord% 的开头.


REM 生成 %systraceRecord%
REM 将指定内容添加到临时文件
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
REM 将 %systraceRecordTxt% 的内容追加到临时文件
type "%systraceRecordTxt%" >> "%tempFile%"
REM 将临时文件的内容移动回 "%systraceRecord%"
move /Y "%tempFile%" "%systraceRecord%"
echo 指定内容已经成功添加到 %systraceRecord% 的开头.


REM 生成回复配置的文件
echo REM 恢复配置 > %endConfigsTrace%
echo call %END_PERF_CONFIG% >> %endConfigsTrace%

REM 设置右键注册表
set "regFile=%~dp0setReg.reg"
echo %regFile%
::pause

echo Windows Registry Editor Version 5.00>%regFile%
echo.>>%regFile%

REM 单个文件上右键 (拆解trace)
echo [HKEY_CLASSES_ROOT\*\shell\parserTrace]>>%regFile%
echo @="aTrace 拆解">>%regFile%
echo [HKEY_CLASSES_ROOT\*\shell\parserTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\*\shell\parserTrace\command" /ve /t REG_EXPAND_SZ /d "\"%parserTrace%\" \"%%L\"" /f

REM 目录上右键 (Transs_PerfTools)
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools]>>%regFile%
echo "SubCommands"="">>%regFile%
REM 目录上右键 (拆解trace)
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\parserTrace]>>%regFile%
echo @="aTrace 拆解">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\parserTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\parserTrace\command" /ve /t REG_EXPAND_SZ /d "\"%parserTrace%\" \"%%V\"" /f
REM 目录上右键 (抓取 pefetto trace)
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\pefettoRecordTrace]>>%regFile%
echo @="perfettoTrace 抓取">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\pefettoRecordTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\pefettoRecordTrace\command" /ve /t REG_EXPAND_SZ /d "\"%perfettoRecord%\" \"%%V\"" /f
REM 目录上右键 (抓取 systrace trace)
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\systraceRecordTrace]>>%regFile%
echo @="systraceTrace 抓取">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\systraceRecordTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\shell\Transs_PerfTools\shell\systraceRecordTrace\command" /ve /t REG_EXPAND_SZ /d "\"%systraceRecord%\" \"%%V\"" /f

REM 目录空白区域右键 (Transs_PerfTools)
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools]>>%regFile%
::echo @="Transs_PerfTools">>%regFile%
echo "SubCommands"="">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell]>>%regFile%
REM 目录空白区域右键 (拆解trace)
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\parserTrace]>>%regFile%
echo @="aTrace 拆解">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\parserTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\parserTrace\command" /ve /t REG_EXPAND_SZ /d "\"%parserTrace%\" \"%%V\"" /f
REM 目录空白区域右键 (抓取 pefetto trace)
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\pefettoRecordTrace]>>%regFile%
echo @="perfettoTrace 抓取">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\pefettoRecordTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\pefettoRecordTrace\command" /ve /t REG_EXPAND_SZ /d "\"%perfettoRecord%\" \"%%V\"" /f
REM 目录空白区域右键 (抓取 systrace trace)
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\systraceRecordTrace]>>%regFile%
echo @="systraceTrace 抓取">>%regFile%
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\systraceRecordTrace\command]>>%regFile%
echo.>>%regFile%
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Transs_PerfTools\shell\systraceRecordTrace\command" /ve /t REG_EXPAND_SZ /d "\"%systraceRecord%\" \"%%V\"" /f

c:\windows\regedit -s %regFile%
del %regFile%
echo setup end
pause
