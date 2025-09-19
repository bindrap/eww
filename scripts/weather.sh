#!/bin/bash

# Location
CITY="Windsor"

# Fetch weather data from wttr.in
WEATHER=$(curl -sf "wttr.in/$CITY?format=j1") || {
  echo "❌ No weather data"
  exit 1
}

# Parse current conditions
TEMP=$(jq -r '.current_condition[0].temp_C' <<< "$WEATHER")
FEELS=$(jq -r '.current_condition[0].FeelsLikeC' <<< "$WEATHER")
COND=$(jq -r '.current_condition[0].weatherDesc[0].value' <<< "$WEATHER")
HUMIDITY=$(jq -r '.current_condition[0].humidity' <<< "$WEATHER")
UV=$(jq -r '.current_condition[0].uvIndex' <<< "$WEATHER")
WIND_KPH=$(jq -r '.current_condition[0].windspeedKmph' <<< "$WEATHER")
WIND_DIR=$(jq -r '.current_condition[0].winddir16Point' <<< "$WEATHER")
SUNRISE=$(jq -r '.weather[0].astronomy[0].sunrise' <<< "$WEATHER")
SUNSET=$(jq -r '.weather[0].astronomy[0].sunset' <<< "$WEATHER")

# Icon helper
get_icon() {
  case "$1" in
    *Clear*|*Sunny*) echo "☀️" ;;
    *Partly*) echo "⛅" ;;
    *Cloud*|*Overcast*) echo "☁️" ;;
    *Mist*|*Fog*) echo "🌫️" ;;
    *Rain*|*Drizzle*) echo "🌧️" ;;
    *Snow*|*Blizzard*) echo "❄️" ;;
    *Thunder*) echo "⛈️" ;;
    *Sleet*) echo "🌨️" ;;
    *) echo "🌤️" ;;
  esac
}

# UV warning
uv_level() {
  [[ $1 -le 2 ]] && echo "Low" ||
  [[ $1 -le 5 ]] && echo "Moderate" ||
  [[ $1 -le 7 ]] && echo "High" ||
  [[ $1 -le 10 ]] && echo "Very High" || echo "Extreme"
}

# Hourly forecast (next 3 periods)
HOURLY=$(jq -c '.weather[0].hourly[:3][]' <<< "$WEATHER")
FORECAST=""
for H in $HOURLY; do
  TIME=$(jq -r '.time' <<< "$H" | sed 's/^$/0/' | xargs printf "%04d")
  HR="${TIME:0:2}:${TIME:2:2}"
  TIME_FMT=$(date -d "$HR" +"%I:%M %p" 2>/dev/null || echo "$HR")
  T=$(jq -r '.tempC' <<< "$H")
  D=$(jq -r '.weatherDesc[0].value' <<< "$H")
  ICON=$(get_icon "$D")
  FORECAST+="$TIME_FMT: $T°C $ICON\n"
done

# Output block
ICON_NOW=$(get_icon "$COND")
UV_WARN=$(uv_level "$UV")

cat <<EOF
$ICON_NOW $TEMP°C • $COND
Feels like: $FEELS°C
💧 $HUMIDITY% • ☀️ UV: $UV ($UV_WARN)
💨 $WIND_KPH km/h $WIND_DIR
🌅 $SUNRISE • 🌇 $SUNSET

Next 3 hours:
$(echo -e "$FORECAST")
EOF
