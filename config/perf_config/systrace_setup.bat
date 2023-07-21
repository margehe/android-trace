@echo off
adb root
adb shell "echo 0 > /d/tracing/tracing_on"
adb shell "echo 0 > /sys/kernel/tracing/tracing_on"

adb shell "cd /sys/kernel/tracing/events/sched;echo 1 > sched_waking/enable;echo 1 > sched_wakeup/enable;echo 1 > sched_switch/enable;"
adb shell "cd /sys/kernel/tracing/events/power;echo 1 > cpu_idle/enable;echo 1 > cpu_frequency/enable;echo 1 > cpu_frequency_limits/enable;"
adb shell "echo 'mtk_ppm perf_tracker irq' >> /sys/kernel/tracing/set_event"


:: vendor.debug.mtkcam.systrace.level  默认是 1, open camera3 device (device@3.6/internal/0) systraceLevel(1) instanceId(0) vid(0)
:: mtkcam/mtkcam.mk 有个默认值  MTKCAM_SYSTRACE_LEVEL_DEFAULT
::----------------------------------------------------------------------------

:: 默认 0
adb shell "setprop debug.egl.traceGpuCompletion 1"
adb shell "setprop debug.egl.trace systrace"
:: MDP 默认 0
adb shell "setprop vendor.dp.systrace.enable 1"
:: 默认 0x01
adb shell "setprop vendor.debug.camera.ulog.mode 0x11"
::adb shell "setprop vendor.debug.camera.ulog.mode 0xff"
:: 默认 0 
adb shell "setprop vendor.debug.camera.ulog.filter 0xfffff"
:: 默认 0 
adb shell "setprop vendor.debug.camera.ulog.func 1"

adb shell "pkill camera*"
::----------------------------------------------------------------------------
adb shell "echo 1 > /sys/devices/system/cpu/perf/enable"
adb shell "echo 1 > /sys/module/ged/parameters/ged_log_perf_trace_enable"
adb shell "echo 512 > /sys/kernel/tracing/saved_cmdlines_size"

echo confirm ppm_user_setting info:
adb shell "cat /sys/kernel/tracing/events/mtk_ppm/ppm_user_setting/enable;"
echo set_event:
adb shell "cat /sys/kernel/tracing/set_event"
::----------------------------------------------------------------------------
echo systrace setup done
::set /p cont= root 版本会杀 camera, 确认能打开 camera 后, 任意键继续抓 trace