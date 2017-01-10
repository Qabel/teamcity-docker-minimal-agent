xvfb-run -a -s "-screen 0 1920x1080x8" bash -c ' /opt/android-sdk/tools/emulator64-x86 -prop persist.sys.language=de -prop persist.sys.country=DE -avd test -no-boot-anim -no-window -qemu' &
echo $! > /var/run/emu.pid

