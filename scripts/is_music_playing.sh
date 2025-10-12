#!/bin/bash

# Check if music is playing from Spotify or ncmpcpp (mpd)
# Returns "true" if either is playing, "false" otherwise

# Check if ncmpcpp/mpd is playing
mpc_status=$(mpc status 2>/dev/null | grep -o 'playing' || echo "")

# Check if Spotify is playing via playerctl
spotify_status=$(playerctl -p spotify status 2>/dev/null || echo "")

# Check if any audio from Spotify or mpd is actively playing
if [ "$mpc_status" = "playing" ] || [ "$spotify_status" = "Playing" ]; then
    echo "true"
else
    echo "false"
fi
