@echo off
mode con cols=140 lines=40 &title parserTrace
set Author=author: No.18649335
set toolversion=version: 2023/6/23 V_0.1
set rerf_desc=说明文档: https://transsioner.feishu.cn/docx/ELf0dPo4Ho06BHxLSE5c3vI1nvc
rem set env
set SRCPATH=D:\bbbbbbbbb\trace_parser_v3_230625\src
set PYTHONHOME=D:\bbbbbbbbb\trace_parser_v3_230625\python310
set ADBPATH=D:\bbbbbbbbb\trace_parser_v3_230625\platform-tools
set PATH="%ADBPATH%";"%PYTHONHOME%";"%PYTHONHOME%\Scripts";%PATH%
set trace_dir=%1

:: 延迟变量扩展 enabledelayedexpansion => !user_input!
setlocal enabledelayedexpansion
pushd %trace_dir% 2>nul
for /F "delims=" %%A in ('dir /B /A "%trace_dir%" 2^>nul') do (
    set "attributes=%%~aA"
)
popd 2>nul
if not defined attributes (
    echo 路径不存在
    exit
) else if "%attributes:~0,1%"=="d" (
    echo 解析 %trace_dir% 目录
    echo.
    set out_dir=%trace_dir%\out
) else (
    for %%i in (%1) do set out_dir=%%~dpi\out
    echo 解析 %trace_dir% 文件
)
echo 输出目录: %out_dir%
if not exist out_dir (
    md %out_dir%
)
echo !Author! > !out_dir!\info.txt
echo !toolversion! >> !out_dir!\info.txt
echo !rerf_desc! >> !out_dir!\info.txt

:menu
::cls
::set /p trace_dir=Enter directory path(输入要解析的目录路径):
echo		         Please Select
echo	=============================================
echo		         1.硬启动/冷启动/锁屏启动/息屏启动/画C启动
echo.             
echo		         2.热启动
echo.             
echo		         3.不同 Camera ID 切换（如前后摄切换 , 后摄 AI 切到人像模式）
echo.             
echo		         4.同 Camera ID 切换（如拍照切视频）
echo.             
echo		         5.shot2see
echo.             
echo		         6.shot2shot
echo.             
echo		         7.连拍
echo.             
echo		         8.开始录像
echo.             
echo		         9.结束录像
echo.             
echo		         10.Back/Home退出
echo.             
echo		         Q.Quit
echo.
set choice=
set /p choice=		Please Select：

:caller
if /i "%choice%" == "1" ( 
    call :1_hardOpen
) else if /i "%choice%" == "2" ( 
    call :2_warmOpen 
) else if /i "%choice%" == "3" ( 
    call :3_diffCamswitch 
) else if /i "%choice%" == "4" ( 
    call :4_sameCamswitch 
) else if /i "%choice%" == "5" (
    call :5_shot2see
) else if /i "%choice%" == "6" (
    call :6_shot2shot
) else if /i "%choice%" == "7" (
    call :7_burstCapture
) else if /i "%choice%" == "8" (
    call :8_startRecord
) else if /i "%choice%" == "9" (
    call :9_stopRecord
) else if /i "%choice%" == "10" (
    call :10_homeClose
) else if /i "%choice%" == "Q" ( 
    goto :eof 
) else ( 
    goto menu
    echo Invalid，Please Input: 1~10, Q
    echo.
) 
set /p cont= 任意键结束操作...
exit /b
::goto menu

:1_hardOpen
:: 冷启动
python.exe %SRCPATH%\camPerfParser.py %trace_dir% 1
goto :eof
:2_warmOpen
:: 热启动
python.exe %SRCPATH%\camPerfParser.py %trace_dir% 2
goto :eof
:3_diffCamswitch
python.exe %SRCPATH%\camPerfParser.py %trace_dir% 3
goto :eof
:4_sameCamswitch
python.exe %SRCPATH%\camPerfParser.py %trace_dir% 4
goto :eof
:5_shot2see
python.exe %SRCPATH%\camPerfParser.py %trace_dir% 5
goto :eof
:6_shot2shot
python.exe %SRCPATH%\camPerfParser.py %trace_dir% 6
goto :eof
:7_burstCapture
goto :eof
:8_startRecord
goto :eof
:9_stopRecord
goto :eof
:10_homeClose
goto :eof
