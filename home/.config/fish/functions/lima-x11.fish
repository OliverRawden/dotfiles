function lima-x11 --description 'Re-allow the lima guest after XQuartz restarts (cookie + xhost reset)'
    set -gx PATH /opt/X11/bin $PATH
    set -gx DISPLAY :0
    open -a XQuartz

    for i in (seq 40)
        test -S /tmp/.X11-unix/X0; and break
        sleep 0.15
    end

    xhost +192.168.5.15 >/dev/null 2>&1; or true

    set -l cookie (xauth list 2>/dev/null | awk '/unix:0/{print $NF; exit}')
    if test -n "$cookie"; and command -q limactl
        limactl shell linux-desktop -- xauth add host.lima.internal:0 MIT-MAGIC-COOKIE-1 $cookie >/dev/null 2>&1; or true
    end

    echo "XQuartz is ready for lima linux-desktop (DISPLAY=host.lima.internal:0)"
end
