#!/bin/bash

# Colors (Hex)
BLUE="#89b4fa"
YELLOW="#f9e2af"
RED="#f38ba8"
TEXT="#cdd6f4"
SUBTEXT="#a6adc8"
OVERLAY="#6c7086"

CITY="Bangalore"

# Fetch weather data
TEMP=$(curl -sf --max-time 5 "https://wttr.in" 2>/dev/null | tr -d '+')
HUMIDITY=$(curl -sf --max-time 5 "https://wttr.in" 2>/dev/null)
CONDITION=$(curl -sf --max-time 5 "https://wttr.in" 2>/dev/null)

if [ -z "$TEMP" ]; then
    echo "<span foreground='$RED'>offline</span>"
    exit 0
fi

# Strip unit for comparison
TEMP_NUM=$(echo "$TEMP" | tr -d '°C F')

# Unicode Symbols (Monochrome Text Style)
CONDITION_LOWER=$(echo "$CONDITION" | tr '[:upper:]' '[:lower:]')

case "$CONDITION_LOWER" in
    *sunny*|*clear*)       ICON="☀"  ICON_COLOR="$YELLOW" ;; # U+2600
    *cloud*|*overcast*)    ICON="☁"  ICON_COLOR="$OVERLAY" ;; # U+2601
    *fog*|*mist*|*haze*)   ICON="≋"  ICON_COLOR="$OVERLAY" ;; # U+224B
    *rain*|*drizzle*)      ICON="⛆"  ICON_COLOR="$BLUE"    ;; # U+2614
    *snow*|*sleet*)        ICON="☃"  ICON_COLOR="$TEXT"    ;; # U+2603
    *thunder*)             ICON="🗲"  ICON_COLOR="$YELLOW" ;; # U+26A1
    *)                     ICON=""  ICON_COLOR="$OVERLAY" ;;
esac

# Temperature color logic
if [ "$TEMP_NUM" -ge 30 ] 2>/dev/null; then
    TEMP_COLOR="$RED"
elif [ "$TEMP_NUM" -ge 20 ] 2>/dev/null; then
    TEMP_COLOR="$YELLOW"
elif [ "$TEMP_NUM" -ge 10 ] 2>/dev/null; then
    TEMP_COLOR="$BLUE"
else
    TEMP_COLOR="$SUBTEXT"
fi

# Final Output with Unicode Degree Symbol
echo "<span foreground='$SUBTEXT'>$CITY</span> <span foreground='$ICON_COLOR'>$ICON</span> <span foreground='$TEMP_COLOR'>$TEMP</span> <span foreground='$SUBTEXT'>$HUMIDITY</span>"
