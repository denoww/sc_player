#!/bin/bash
# WID=$(xdotool search --onlyvisible --class chromium|head -1)
WID=$(xdotool search --onlyvisible --name page-player)
xdotool windowactivate --sync $WID
xdotool key --clearmodifiers ctrl+F5
