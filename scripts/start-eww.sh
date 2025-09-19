#!/bin/bash

/usr/bin/pkill eww
sleep 1

/usr/bin/eww daemon --config ~/.config/eww &
sleep 2

#/usr/bin/eww open sysinfo-window
#/usr/bin/eww open weather-window
/usr/bin/eww open ascii-window
#/usr/bin/eww open file-button-window
#/usr/bin/eww open youtube-window
