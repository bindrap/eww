#!/bin/bash

# Run CAVA and format output for EWW
cava -p ~/.config/cava/config | while IFS= read -r line; do
    # Split the line by semicolon delimiter
    IFS=';' read -ra bars <<< "$line"
    
    # Create visual bars using Unicode block characters
    output=""
    for bar in "${bars[@]}"; do
        # Map 0-10 to different bar heights
        case $bar in
            0) output+=" " ;;
            1) output+="▁" ;;
            2) output+="▂" ;;
            3) output+="▃" ;;
            4) output+="▄" ;;
            5) output+="▅" ;;
            6) output+="▆" ;;
            7) output+="▇" ;;
            8|9|10) output+="█" ;;
        esac
    done
    
    echo "$output"
done
