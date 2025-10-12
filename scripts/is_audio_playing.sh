#!/bin/bash

# Check if any audio is playing via PipeWire/PulseAudio
# Look for sink inputs that are not corked (corked = paused)
if pactl list sink-inputs | grep -q "Corked: no"; then
    echo "true"
else
    echo "false"
fi
