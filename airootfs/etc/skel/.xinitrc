#!/bin/bash


export QT_QPA_PLATFORMTHEME=qt6ct

feh --bg-scale ~/wallpaper.png &
picom --backend xrender --fading \
      --fade-in-step 0.05 \
      --fade-out-step 0.05 &

# launch welcome.sh after dwm is ready
# sleep gives dwm time to initialize
(sleep 0.3 && st -e /usr/local/bin/welcome.sh) &

exec dwm