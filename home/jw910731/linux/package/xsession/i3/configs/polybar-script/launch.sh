#!/bin/sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar1 and bar2
#MONITORS=$(xrandr --query | grep " connected" | cut -d" " -f1)

polybar --config=$HOME/.config/polybar/polybar.ini default > /tmp/polybar.log 2>&1 &
echo "Bars launched..."