#!/bin/bash
SERVICE="node"

if pgrep -f "$SERVICE" >/dev/null
then
  echo "$SERVICE is running"
else
  echo "starting $SERVICE"

  export DISPLAY=":0"
  /home/pi/sc_player/tasks/./init.sh
fi
