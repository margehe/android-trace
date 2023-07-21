@echo off
mode con cols=140 lines=40 &title perfettoRecord
set Author=author: No.18649335
set toolversion=version: 2023/6/23 V_0.1
set rerf_desc=˵���ĵ�: https://transsioner.feishu.cn/docx/ELf0dPo4Ho06BHxLSE5c3vI1nvc
rem set env
set SRCPATH=D:\bbbbbbbbb\trace_parser_v3_230625\src
set PYTHONHOME=D:\bbbbbbbbb\trace_parser_v3_230625\python310
set ADBPATH=D:\bbbbbbbbb\trace_parser_v3_230625\platform-tools
set PATH="%ADBPATH%";"%PYTHONHOME%";"%PYTHONHOME%\Scripts";%PATH%
set BIN_DIR=D:\bbbbbbbbb\trace_parser_v3_230625\bin
set CONFIG_DIR=D:\bbbbbbbbb\trace_parser_v3_230625\config
setlocal enabledelayedexpansion
set RECORD_BIN=%BIN_DIR%\record_android_trace
echo RECORD_BIN: %RECORD_BIN%

set SET_PERF_CONFIG=%CONFIG_DIR%\perf_config\systrace_setup.bat
set END_PERF_CONFIG=%CONFIG_DIR%\perf_config\end_setup.bat

set OUTDIR=%1
echo dir %OUTDIR%

if not exist "%OUTDIR%" (
    echo %OUTDIR% ������, ��ȷ�Ϻ����.
    exit /b
)
echo !Author! > !OUTDIR!\info.txt
echo !toolversion! >> !OUTDIR!\info.txt
echo !rerf_desc! >> !OUTDIR!\info.txt

:menu
::cls
for /F %%i in ('adb shell getprop ro.product.device') do (set device_name=%%i)
if not defined device_name (
    echo ��ȷ����ȷ�����豸�����
    pause
    echo.
    goto menu
)
echo device_name is: %device_name%
set /p user_input="�Ƿ�� CAM_P1 ����ϸ trace (Y/y)? " 
if /I "%user_input%"=="Y" (
    echo ������ϸ����: %SET_PERF_CONFIG%, root �汾������ camera.
    call %SET_PERF_CONFIG%
    set /p cont= root �汾��ɱ camera, ȷ���ܴ� camera ��, ���������ץ trace
    echo.
)

echo.
echo		         Please Select
echo	****************************************************************
echo		    1.�������ץȡ trace
echo.             
echo		    2.�ϵ�����ץȡ sf
echo.             
echo		    3.�ϵ�����ץȡ trace, ץȡ mem, GPU ����Ϣ
echo.             
echo		    4. ץȡ�ڴ� log ����ϸ��Ϣ (��Ҫ root/debug �汾)
echo		    root �汾��Ҫ����: "adb shell 'echo 0 > /d/tracing/tracing_on; echo 0 > /sys/kernel/tracing/tracing_on'"
echo.             
echo		    5. ץȡ camera ��ؽ��� heap, native ����ϸ��Ϣ
echo.             
echo		    6. ץȡ camera ��ؽ����ڴ�й© (debug �汾, Ĭ��ץ 3 Сʱ)
echo.             
echo		    7. ץȡ����ͼ (debug �汾, Ĭ�� 5s)
echo.             
echo		    Q.Quit
echo	****************************************************************
echo.
echo -----------------------------------------------------------------------------------
echo    ���� "enabled ftrace" ��ʾ��ʼ�����ֻ�, ��ʼ¼�� trace ��, ���� 10s �в������.
echo    "disabled ftrace" ��ʾ trace ����.
echo -----------------------------------------------------------------------------------
::cho
set choice=
set /p choice=		Please Select��
if not "%choice%" == "" set choice=%choice:~0,1%

:caller
if /i "%choice%" == "1" ( 
    call :simplest
) else if /i "%choice%" == "2" ( 
    call :simplestSF 
) else if /i "%choice%" == "3" ( 
    call :simple 
) else if /i "%choice%" == "4" ( 
    call :logMem 
) else if /i "%choice%" == "5" ( 
    call :cameraMem
) else if /i "%choice%" == "6" ( 
    call :cameraMemLeak
) else if /i "%choice%" == "7" ( 
    call :cameraPerf
) else if /i "%choice%" == "Q" ( 
    goto :eof 
) else ( 
    goto menu
    echo Invalid��Please Input:
    echo.
)
set /p cont= ���������ץ trace
goto caller

:simplest
::pause
python.exe %RECORD_BIN% -n -c %CONFIG_DIR%/perfetto_trace_simple.config -o %OUTDIR%
goto :eof
:simplestSF
::pause
python.exe %RECORD_BIN% -n -c %CONFIG_DIR%/perfetto_trace_sf.config -o %OUTDIR%
goto :eof
:simple
python.exe %RECORD_BIN% -n -c %CONFIG_DIR%/perfetto_trace_simple.config -o %OUTDIR%
goto :eof
:logMem
python.exe %RECORD_BIN% -n -c %CONFIG_DIR%/perfetto_trace_log_mem.config -o %OUTDIR%
goto :eof
:cameraMem
python.exe %RECORD_BIN% -n -c %CONFIG_DIR%/perfetto_trace_log_native_heap.config -o %OUTDIR%
goto :eof
:cameraMemLeak
python.exe %RECORD_BIN% -n -c %CONFIG_DIR%/perfetto_memLeak.config -o %OUTDIR%
goto :eof
:cameraPerf
python.exe %RECORD_BIN% -n -c %CONFIG_DIR%/perfetto_perf.config -o %OUTDIR%
goto :eof
