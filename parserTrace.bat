@echo off
mode con cols=140 lines=40 &title parserTrace
set Author=author: No.18649335
set toolversion=version: 2023/6/23 V_0.1
set rerf_desc=˵���ĵ�: https://transsioner.feishu.cn/docx/ELf0dPo4Ho06BHxLSE5c3vI1nvc
rem set env
set SRCPATH=D:\bbbbbbbbb\trace_parser_v3_230625\src
set PYTHONHOME=D:\bbbbbbbbb\trace_parser_v3_230625\python310
set ADBPATH=D:\bbbbbbbbb\trace_parser_v3_230625\platform-tools
set PATH="%ADBPATH%";"%PYTHONHOME%";"%PYTHONHOME%\Scripts";%PATH%
set trace_dir=%1

:: �ӳٱ�����չ enabledelayedexpansion => !user_input!
setlocal enabledelayedexpansion
pushd %trace_dir% 2>nul
for /F "delims=" %%A in ('dir /B /A "%trace_dir%" 2^>nul') do (
    set "attributes=%%~aA"
)
popd 2>nul
if not defined attributes (
    echo ·��������
    exit
) else if "%attributes:~0,1%"=="d" (
    echo ���� %trace_dir% Ŀ¼
    echo.
    set out_dir=%trace_dir%\out
) else (
    for %%i in (%1) do set out_dir=%%~dpi\out
    echo ���� %trace_dir% �ļ�
)
echo ���Ŀ¼: %out_dir%
if not exist out_dir (
    md %out_dir%
)
echo !Author! > !out_dir!\info.txt
echo !toolversion! >> !out_dir!\info.txt
echo !rerf_desc! >> !out_dir!\info.txt

:menu
::cls
::set /p trace_dir=Enter directory path(����Ҫ������Ŀ¼·��):
echo		         Please Select
echo	=============================================
echo		         1.Ӳ����/������/��������/Ϣ������/��C����
echo.             
echo		         2.������
echo.             
echo		         3.��ͬ Camera ID �л�����ǰ�����л� , ���� AI �е�����ģʽ��
echo.             
echo		         4.ͬ Camera ID �л�������������Ƶ��
echo.             
echo		         5.shot2see
echo.             
echo		         6.shot2shot
echo.             
echo		         7.����
echo.             
echo		         8.��ʼ¼��
echo.             
echo		         9.����¼��
echo.             
echo		         10.Back/Home�˳�
echo.             
echo		         Q.Quit
echo.
set choice=
set /p choice=		Please Select��

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
    echo Invalid��Please Input: 1~10, Q
    echo.
) 
set /p cont= �������������...
exit /b
::goto menu

:1_hardOpen
:: ������
python.exe %SRCPATH%\camPerfParser.py %trace_dir% 1
goto :eof
:2_warmOpen
:: ������
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
