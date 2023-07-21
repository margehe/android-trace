@echo off
mode con cols=140 lines=40 &title perfettoRecord
set Author=author: No.18649335
set toolversion=version: 2023/6/23 V_0.1
set rerf_desc=说明文档: https://transsioner.feishu.cn/docx/ELf0dPo4Ho06BHxLSE5c3vI1nvc
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
    echo %OUTDIR% 不存在, 请确认后继续.
    exit /b
)
echo !Author! > !OUTDIR!\info.txt
echo !toolversion! >> !OUTDIR!\info.txt
echo !rerf_desc! >> !OUTDIR!\info.txt

:menu
::cls
for /F %%i in ('adb shell getprop ro.product.device') do (set device_name=%%i)
if not defined device_name (
    echo 请确认正确连接设备后继续
    pause
    echo.
    goto menu
)
echo device_name is: %device_name%
set /p user_input="是否打开 CAM_P1 等详细 trace (Y/y)? " 
if /I "%user_input%"=="Y" (
    echo 调用详细配置: %SET_PERF_CONFIG%, root 版本会重启 camera.
    call %SET_PERF_CONFIG%
    set /p cont= root 版本会杀 camera, 确认能打开 camera 后, 任意键继续抓 trace
    echo.
)

echo.
echo		         Please Select
echo	****************************************************************
echo		    1.最低配置抓取 trace
echo.             
echo		    2.较低配置抓取 sf
echo.             
echo		    3.较低配置抓取 trace, 抓取 mem, GPU 等信息
echo.             
echo		    4. 抓取内存 log 等详细信息 (需要 root/debug 版本)
echo		    root 版本需要运行: "adb shell 'echo 0 > /d/tracing/tracing_on; echo 0 > /sys/kernel/tracing/tracing_on'"
echo.             
echo		    5. 抓取 camera 相关进程 heap, native 等详细信息
echo.             
echo		    6. 抓取 camera 相关进程内存泄漏 (debug 版本, 默认抓 3 小时)
echo.             
echo		    7. 抓取火焰图 (debug 版本, 默认 5s)
echo.             
echo		    Q.Quit
echo	****************************************************************
echo.
echo -----------------------------------------------------------------------------------
echo    看到 "enabled ftrace" 提示后开始操作手机, 开始录制 trace 后, 请在 10s 中操作完成.
echo    "disabled ftrace" 提示 trace 结束.
echo -----------------------------------------------------------------------------------
::cho
set choice=
set /p choice=		Please Select：
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
    echo Invalid，Please Input:
    echo.
)
set /p cont= 任意键继续抓 trace
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
