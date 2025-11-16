#!/bin/bash
cd ~/Documents/Notes
echo "📥 Pulling from Nextcloud..."
./sync_notes.sh --pull nextcloud
echo "✅ Nextcloud pull completed! Press Enter to close..."
read