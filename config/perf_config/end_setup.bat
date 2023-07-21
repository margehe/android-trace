@echo off
::----------------------------------------------------------------------------

:: 默认 0
::adb shell "setprop debug.egl.traceGpuCompletion 0"
::::adb shell "setprop debug.egl.trace systrace"
:::: MDP 默认 0
::adb shell "setprop vendor.dp.systrace.enable 0"
:::: 默认 0 
::adb shell "setprop vendor.debug.camera.ulog.filter 0"
:::: 默认 0 
::adb shell "setprop vendor.debug.camera.ulog.func 0"
:::: 默认 0x01
::adb shell "setprop vendor.debug.camera.ulog.mode 0x01"
:: adb shell "pkill camera*"
::----------------------------------------------------------------------------
adb shell "echo 0 > /sys/devices/system/cpu/perf/enable"
adb shell "echo 0 > /sys/module/ged/parameters/ged_log_perf_trace_enable"
echo end setup done
pause