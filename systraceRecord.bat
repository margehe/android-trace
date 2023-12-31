@echo off
mode con cols=140 lines=40 &title systraceRecord
set Author=author: No.18649335
set toolversion=version: 2023/6/23 V_0.1
set rerf_desc=说明文档: https://transsioner.feishu.cn/docx/ELf0dPo4Ho06BHxLSE5c3vI1nvc
rem global set
rem tool version
::env var set
set SRCPATH=D:\bbbbbbbbb\trace_parser_v3_230625\src
set PYTHONHOME=D:\bbbbbbbbb\trace_parser_v3_230625\Python27
set PYTHONPATH=D:\bbbbbbbbb\trace_parser_v3_230625\Python27
set ANDROID_HOME=D:\bbbbbbbbb\trace_parser_v3_230625\platform-tools
set BIN_DIR=D:\bbbbbbbbb\trace_parser_v3_230625\bin
set CONFIG_DIR=D:\bbbbbbbbb\trace_parser_v3_230625\config
setlocal enabledelayedexpansion
set PATH="%ANDROID_HOME%";"%PYTHONHOME%";%PATH%
set Dos2UnixBIN=%BIN_DIR%\dos2unix.exe

set SET_PERF_CONFIG=%CONFIG_DIR%\perf_config\systrace_setup.bat
set END_PERF_CONFIG=%CONFIG_DIR%\perf_config\end_setup.bat

rem echo new PATH:%path%
echo This is systrace record tool

set OUTDIR=%1
::set OUTDIR=D:\Download\office_soft_data\tmppp\tmtm
echo OUTDIR: %OUTDIR%
if not exist "%OUTDIR%" (
    echo %OUTDIR% 不存在, 请确认后继续.
    exit /b
)
set STOP_TRACE_NAME=stoptrace.sh
set STOP_TRACE_SCRIPT=%OUTDIR%\%STOP_TRACE_NAME%

:menu
for /F %%i in ('adb shell getprop ro.product.device') do (set device_name=%%i)
if not defined device_name (
    echo 请确认正确连接设备后继续
    pause
    echo.
    goto menu
)
echo.
echo		         Please Select
echo	****************************************************************
echo		    1.最低配置抓取 trace
echo.             
echo		    2.抓取详细的 trace 
echo              包括 PPM 限频, CAM_P1, 会重启 camera. 需要root版本
echo.
echo		    Q.Quit
echo	****************************************************************
echo.
echo -----------------------------------------------------------------------------------
echo    看到 "capturing trace" 提示后开始操作手机, 开始录制 trace 后, 操作完成后按任意键结束操作.
echo -----------------------------------------------------------------------------------
::cho
set choice=
set /p choice=		Please Select：
if not "%choice%" == "" set choice=%choice:~0,1%

if /i "%choice%" == "2" ( 
    echo 调用详细配置: %SET_PERF_CONFIG%
    call %SET_PERF_CONFIG%
)

:caller
if /i "%choice%" == "1" ( 
    call :simple
) else if /i "%choice%" == "2" ( 
    call :detail
) else if /i "%choice%" == "Q" ( 
    goto :eof 
) else ( 
    goto menu
    echo Invalid，Please Input:
    echo.
)
goto caller

:simple
set setDetailConfig=no
call :configAtrace no
set /p cont= 任意键继续抓 trace
call :genFileName
call :main
goto :eof

:detail
set setDetailConfig=yes
call :configAtrace yes
set /p cont= root 版本会杀 camera, 确认能打开 camera 后, 任意键继续抓 trace
call :genFileName
call :main
::echo 恢复配置: %END_PERF_CONFIG%
::call %END_PERF_CONFIG%
goto :eof

:configAtrace
REM trace setting
if /I "%1"=="no" (
    set "ATRACE_TAGS=input gfx wm am view camera aidl irq binder_driver freq android_fs sched power"
    echo 自定义打开足够简单的 tags: !ATRACE_TAGS!
) else (
    :: exclude tags
    REM pdx 打开后就不能抓 atrace, 确认 atrace -b 20240 --async_start pdx => unable to start tracing
    set "exclude=webview mmc rs adb vibrator nnapi regulators audio database pdx"
    set "ATRACE_TAGS="
    for /f %%a in ('adb shell "atrace --list_categories | awk '{print $1}' "') do (
        set "tag=%%a"
        set "skipTag=false"
        for %%c in (!exclude!) do (
            if /i "!tag!" == "%%c" (
                set "skipTag=true"
            )
        )
        if "!skipTag!" == "false" (
            set "ATRACE_TAGS=!ATRACE_TAGS! !tag!"
        )
    )
    echo 从 `atrace --list_categories` 中排除 !exclude! 
    echo 生成 tag: !ATRACE_TAGS!
    echo.
)
REM atrace apps
set ATRACE_APPS=com.transsion.camera,com.transsion.camera.debug
rem buffer unit is KB
REM 避免频繁写入, 8G 的设置 40M 没有问题
set buffersize=40960
echo buffersize: %buffersize%
echo ATRACE_TAGS: %ATRACE_TAGS%
echo ATRACE_APPS: %ATRACE_APPS%
echo.
goto :eof

:genFileName
:: 生成文件名
:: 获取进程数量
for /f "delims=" %%a in ('adb shell "ps -ef | wc -l"') do set process_count=%%a
echo 后台进程数量: !process_count!

:: 获取内存信息
for /f "tokens=1,2 delims=: " %%a in ('adb shell "cat /proc/meminfo" ^| findstr /i "MemTotal MemAvailable"') do (
  if "%%a"=="MemTotal" (
    set /a mem_total=%%b/1024
  ) else if "%%a"=="MemAvailable" (
    set /a mem_available=%%b/1024
  )
)
:: 计算可用内存百分比
echo 可用内存: !mem_available! M
echo 内存总量: !mem_total! M
set /a mem_percentage=(!mem_available!*1000)/!mem_total!
set mem_percentage_float=!mem_percentage:~0,-1!.!mem_percentage:~-1!
echo 可用内存百分比: !mem_percentage_float!%%
:: 提取 rom 版本
for /f "delims=" %%a in ('adb shell getprop persist.sys.ota_version') do set rom_version=%%a
echo rom 版本: !rom_version!
for /f "tokens=1 delims=-" %%a in ("!rom_version!") do set rom_model=%%a
echo rom_model: !rom_model!
for /f "tokens=5 delims=-" %%a in ("!rom_version!") do set date_ver=%%a
echo date_ver: !date_ver!
:: trace 开始的时间
rem 根据当前日期获取，年月日串
set yyyy=%date:~,4%
set mm=%date:~5,2%
set day=%date:~8,2%
set "mmdd=%mm%%day%"
rem 把年月日串中的空格替换为0
set "mmdd=%mmdd: =0%"
rem 根据当前时间获取，时分秒串
set hh=%time:~0,2%
set mi=%time:~3,2%
set ss=%time:~6,2%
set "hhmiss=%hh%%mi%%ss%"
set "hhmiss=%hhmiss: =0%"
rem 把时间串中的:替换为0
set "hhmiss=%hhmiss::=0%"
rem 把时间串中的空格替换为0
set "hhmiss=%hhmiss: =0%"
rem 根据日期时间生成文件名称，中间以HH区分日期和时间部分
set date-time=%mmdd%%hhmiss%

:: trace 文件名
set outputfile=!rom_model!-!date_ver!-!date-time!-!process_count!-!mem_percentage_float!.html
echo final file name: !outputfile!

rem color xx [常用的颜色有以下值：0 黑色，1蓝色，2 绿色，3 浅绿色，4红色，5紫色，6黄色，7白色，8灰色，9浅蓝，A浅绿，B浅蓝色，C浅红色，D浅紫色，E浅黄色，F亮白色]
echo.
goto :eof

::set /p user_input=" 按任意键, 3秒后后继续..."
::color 02
::ping -n 4 127.0.0.1 >nul

::--------------------------------------------------------
::-- Main section starts below here
::--------------------------------------------------------
:main
echo.
color A
echo %time%, ============ start caputring systrace... ===========
call :startTraceLoop !buffersize!
echo.
set /p end= 按任意键结束抓取...
color C
echo %time%, stop caputring systrace...
call :stopTraceLoop !buffersize!
color 07
goto :eof
::pause
::exit

:startTraceLoop
  setlocal
  echo %time%,%0 start
  echo adb shell atrace -b %1 --async_start %ATRACE_TAGS% -a %ATRACE_APPS%
  ::pause
  adb shell atrace -b %1 --async_start %ATRACE_TAGS% -a %ATRACE_APPS%
  echo %time%,%0 end
  echo "please enter any key to stop the trace catching if need..."
  color 03
  endlocal
goto :eof

:stopTraceLoop
  setlocal
  echo %time%,%0 start...
  echo !Author! > !OUTDIR!\info.txt
  echo !toolversion! >> !OUTDIR!\info.txt
  echo !rerf_desc! >> !OUTDIR!\info.txt  
  rem generate device shell file
  echo #^^!/system/bin/sh> !STOP_TRACE_SCRIPT!
  echo echo start to stop recording trace on phone. 
  echo echo >> !STOP_TRACE_SCRIPT!
  echo echo >> !STOP_TRACE_SCRIPT!
  echo atrace -b %1 -z -o /data/local/tmp/trace_origin --async_stop %ATRACE_TAGS% >> !STOP_TRACE_SCRIPT!
  echo chmod 0666 /data/local/tmp/trace_origin >> !STOP_TRACE_SCRIPT!
  echo !Dos2UnixBIN! !STOP_TRACE_SCRIPT!
  !Dos2UnixBIN! !STOP_TRACE_SCRIPT!
  adb push !STOP_TRACE_SCRIPT! /data/local/tmp/
  adb shell chmod 0777 /data/local/tmp/!STOP_TRACE_NAME!
  echo exec shell on device start,time is %time%
  adb shell sh /data/local/tmp/!STOP_TRACE_NAME!
  echo exec shell on device end,time is %time%
  rem pull origin trace data
  adb pull /data/local/tmp/trace_origin !OUTDIR!
  python --version
  echo !PYTHONHOME!\python.exe !ANDROID_HOME!\systrace\systrace.py --from-file !OUTDIR!\trace_origin -o !OUTDIR!\!outputfile!
  python !ANDROID_HOME!\systrace\systrace.py --from-file !OUTDIR!\trace_origin -o !OUTDIR!\!outputfile!
  echo %time%,%0 end...
  del !STOP_TRACE_SCRIPT! !OUTDIR!\trace_origin
  endlocal
goto :eof