#!/bin/bash
cd ~/Documents/Notes
echo "📥 Pulling from Google Drive..."
./sync_notes.sh --pull google
echo "✅ Google pull completed! Press Enter to close..."
read