#!/bin/bash
WIN=$(xdotool search --sync --onlyvisible --name "init.sh")
xdotool windowminimize $WIN
