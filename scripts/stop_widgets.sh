#!/bin/bash

# Stop all EWW widgets
eww close-all
killall eww 2>/dev/null || true
echo "🛑 EWW widgets stopped!"
