#!/bin/bash

DIR="/home/parteek/ascii"
FILES=($(find "$DIR" -type f -name "*.txt"))
RANDOM_FILE="${FILES[$((RANDOM % ${#FILES[@]}))]}"

# Sanitize ALL Eww-breaking characters
cat "$RANDOM_FILE" | sed \
    -e 's/\\/\\\\/g' \
    -e 's/\$/\\$/g' \
    -e 's/`/\\`/g' \
    -e 's/"/\\"/g' \
    -e "s/'/\\'/g"