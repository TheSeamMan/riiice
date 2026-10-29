#!/usr/bin/env bash

case "$1" in
  status)
    # 1. CPU (delta over 80ms so it's real-time, not boot average!) & RAM
    read -r _ u1 n1 s1 i1 w1 x1 y1 z1 _ < /proc/stat
    sleep 0.08
    read -r _ u2 n2 s2 i2 w2 x2 y2 z2 _ < /proc/stat
    t1=$((u1+n1+s1+i1+w1+x1+y1+z1))
    t2=$((u2+n2+s2+i2+w2+x2+y2+z2))
    dt=$((t2 - t1))
    di=$(( (i2+w2) - (i1+w1) ))
    if [ "$dt" -gt 0 ]; then
      cpu=$(( (dt - di) * 100 / dt ))
    else
      cpu=0
    fi
    ram=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%.0f", (t-a)*100/t}' /proc/meminfo 2>/dev/null || echo 0)

    # CPU Temps & Fan / Power Info
    cpu_temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -n1 | awk '{printf "%.0f", $1/1000}')
    cpu_temp="${cpu_temp:-45}"
    disk=$(df -h / | awk 'NR==2 {gsub("%","",$5); print $5}' 2>/dev/null || echo 0)

    # 2. Zero-Wake NVIDIA GPU Check (Never wakes D3cold!)
    nv_cache="/tmp/shellby-nv.cache"
    nv_awake=0
    for d in /sys/bus/pci/devices/*; do
      if [ "$(cat "$d/vendor" 2>/dev/null)" = "0x10de" ] && [ "$(cat "$d/class" 2>/dev/null | cut -c1-4)" = "0x03" ]; then
        st=$(cat "$d/power/runtime_status" 2>/dev/null)
        [ "$st" = "active" ] && nv_awake=1
      fi
    done

    if [ "$nv_awake" = "0" ]; then
      gpu_util=0; gpu_temp=36; gpu_mem=0
    elif [ -f "$nv_cache" ] && [ $(( $(date +%s) - $(stat -c %Y "$nv_cache" 2>/dev/null || echo 0) )) -lt 30 ]; then
      read -r gpu_util gpu_temp gpu_mem < "$nv_cache"
    elif command -v nvidia-smi >/dev/null 2>&1; then
      read -r gpu_util gpu_temp gpu_mem <<< "$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,utilization.memory --format=csv,noheader,nounits 2>/dev/null | tr ',' ' ')"
      echo "${gpu_util:-0} ${gpu_temp:-0} ${gpu_mem:-0}" > "$nv_cache"
    fi
    gpu_util="${gpu_util:-0}"
    gpu_temp="${gpu_temp:-36}"
    gpu_mem="${gpu_mem:-0}"

    # 3. Audio (PipeWire / PulseAudio)
    vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk '{print $5}' | tr -d '%' | head -n1)
    vol="${vol:-50}"
    sink_mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
    [ "$sink_mute" = "yes" ] && mute="true" || mute="false"

    mic_vol=$(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $5}' | tr -d '%' | head -n1)
    mic_vol="${mic_vol:-80}"
    mic_mute_raw=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $2}')
    if [ "$mic_mute_raw" = "yes" ]; then
      mic_on="false"
      micmute="true"
    else
      mic_on="true"
      micmute="false"
    fi

    # 4. Screen Brightness
    dev=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1)
    if [ -n "$dev" ]; then
      cur_b=$(cat "$dev/brightness" 2>/dev/null || echo 50)
      max_b=$(cat "$dev/max_brightness" 2>/dev/null || echo 100)
      bri=$(( cur_b * 100 / (max_b > 0 ? max_b : 100) ))
    else
      bri=80
    fi

    # 5. Battery & Power Mode
    bat_dir=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)
    if [ -n "$bat_dir" ]; then
      bat=$(cat "$bat_dir/capacity" 2>/dev/null || echo 100)
      bat_stat=$(cat "$bat_dir/status" 2>/dev/null || echo "Full")
      if [ -f "$bat_dir/power_now" ]; then
        bat_watt=$(awk '{printf "%.1f", $1 / 1000000}' "$bat_dir/power_now" 2>/dev/null || echo "0.0")
      else
        bat_watt="0.0"
      fi
    else
      bat=100
      bat_stat="AC"
      bat_watt="0.0"
    fi
    pwr_mode=$(cat /tmp/shellby-power.mode 2>/dev/null || echo "balanced")

    # 6. Network & Bluetooth
    ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '/^yes/ {print $2; exit}')
    [ -z "$ssid" ] && ssid="Wired/Offline"
    bt_power=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}')
    [ "$bt_power" = "yes" ] && bt_on="true" || bt_on="false"

    # 7. Clean Media Metadata & Safe JSON Serialization via Python
    p_stat=$(playerctl status 2>/dev/null || echo "Stopped")
    title=$(playerctl metadata xesam:title 2>/dev/null || echo "Idle")
    artist=$(playerctl metadata xesam:artist 2>/dev/null || echo "No Media")
    album=$(playerctl metadata xesam:album 2>/dev/null || echo "")
    art=$(playerctl metadata mpris:artUrl 2>/dev/null || echo "")

    python3 - "$cpu" "$ram" "$cpu_temp" "$disk" "$gpu_util" "$gpu_temp" "$gpu_mem" \
              "$vol" "$mute" "$mic_vol" "$mic_on" "$micmute" "$bri" \
              "$bat" "$bat_stat" "$bat_watt" "$pwr_mode" \
              "$ssid" "$bt_on" "$p_stat" "$title" "$artist" "$album" "$art" << 'PYEOF'
import sys, json

a = sys.argv[1:]
def to_int(v, d=0):
    try: return int(float(v))
    except Exception: return d

out = {
    "cpu": to_int(a[0]),
    "ram": to_int(a[1]),
    "temp": to_int(a[2], 45),
    "cputemp": to_int(a[2], 45),
    "disk": to_int(a[3]),
    "gpu": to_int(a[4]),
    "gputemp": to_int(a[5], 36),
    "gpumem": to_int(a[6]),
    "vol": to_int(a[7], 50),
    "mute": a[8],
    "mic": to_int(a[9], 80),
    "micon": a[10] == "true",
    "micmute": a[11],
    "bri": to_int(a[12], 80),
    "bat": to_int(a[13], 100),
    "bat_stat": a[14],
    "bat_watt": a[15],
    "pwr_mode": a[16],
    "ssid": a[17],
    "bton": a[18] == "true",
    "pstat": a[19],
    "title": a[20] or "Idle",
    "artist": a[21] or "",
    "album": a[22] or "",
    "art": a[23] or ""
}
print(json.dumps(out))
PYEOF
    ;;

  weather)
    # Cached Hillcrest / San Diego (92103) Weather
    w_cache="/tmp/shellby-weather.json"
    if [ -f "$w_cache" ] && [ $(( $(date +%s) - $(stat -c %Y "$w_cache" 2>/dev/null || echo 0) )) -lt 900 ]; then
      cat "$w_cache"
      exit 0
    fi
    python3 - "$w_cache" << 'PYEOF'
import sys, json, urllib.request
from pathlib import Path

cache_p = Path(sys.argv[1])
url = "https://api.open-meteo.com/v1/forecast?latitude=32.748&longitude=-117.161&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=America%2FLos_Angeles&forecast_days=5"

wmo_map = {
    0: ("Clear Sky", "󰖙"), 1: ("Mostly Clear", "󰖙"), 2: ("Partly Cloudy", "󰖕"), 3: ("Overcast", "󰖐"),
    45: ("Foggy", "󰖑"), 48: ("Rime Fog", "󰖑"), 51: ("Light Drizzle", "󰖗"), 53: ("Drizzle", "󰖗"),
    55: ("Heavy Drizzle", "󰖗"), 61: ("Light Rain", "󰖗"), 63: ("Rain", "󰖖"), 65: ("Heavy Rain", "󰙾"),
    80: ("Rain Showers", "󰖗"), 95: ("Thunderstorm", "󰖓")
}

try:
    req = urllib.request.Request(url, headers={"User-Agent": "Shellby/2.0"})
    with urllib.request.urlopen(req, timeout=5) as r:
        data = json.loads(r.read().decode())
    cur = data.get("current", {})
    code = int(cur.get("weather_code", 0))
    desc, icon = wmo_map.get(code, ("Sunny", "󰖙"))
    out = {
        "temp": f"{round(cur.get('temperature_2m', 72))}°F",
        "feels": f"{round(cur.get('apparent_temperature', 72))}°F",
        "hum": f"{round(cur.get('relative_humidity_2m', 55))}%",
        "wind": f"{round(cur.get('wind_speed_10m', 6))} mph",
        "desc": desc,
        "icon": icon,
        "city": "San Diego"
    }
    cache_p.write_text(json.dumps(out))
    print(json.dumps(out))
except Exception:
    if cache_p.exists():
        print(cache_p.read_text())
    else:
        print(json.dumps({"temp": "72°F", "feels": "72°F", "hum": "50%", "wind": "5 mph", "desc": "Clear", "icon": "󰖙", "city": "San Diego"}))
PYEOF
    ;;

  cal|calendar)
    # Google Calendar ICS + Local Events Parser
    python3 - << 'PYEOF'
import json, urllib.request, datetime, re
from pathlib import Path

home = Path.home()
cal_cache = Path("/tmp/shellby-gcal.ics")
url_file = home / ".config/shellby/gcal_url"
local_json = home / ".config/shellby/events.json"

events = []
if local_json.exists():
    try:
        events.extend(json.loads(local_json.read_text()))
    except Exception:
        pass

ics_text = ""
if url_file.exists():
    u = url_file.read_text().strip()
    if u.startswith("http"):
        try:
            if not cal_cache.exists() or (datetime.datetime.now().timestamp() - cal_cache.stat().st_mtime > 600):
                req = urllib.request.Request(u, headers={"User-Agent": "Shellby/2.0"})
                with urllib.request.urlopen(req, timeout=6) as r:
                    ics_text = r.read().decode("utf-8", errors="ignore")
                cal_cache.write_text(ics_text)
            else:
                ics_text = cal_cache.read_text(errors="ignore")
        except Exception:
            if cal_cache.exists():
                ics_text = cal_cache.read_text(errors="ignore")

if ics_text:
    unfolded = re.sub(r"\r?\n[ \t]", "", ics_text)
    for block in unfolded.split("BEGIN:VEVENT")[1:]:
        body = block.split("END:VEVENT")[0]
        summary = ""
        dtstart = ""
        for line in body.splitlines():
            if line.startswith("SUMMARY"):
                summary = line.split(":", 1)[-1].strip()
            elif line.startswith("DTSTART"):
                dtstart = line.split(":", 1)[-1].strip()
        if summary and len(dtstart) >= 8:
            d_str = f"{dtstart[0:4]}-{dtstart[4:6]}-{dtstart[6:8]}"
            t_str = f"{dtstart[9:11]}:{dtstart[11:13]}" if len(dtstart) >= 13 and "T" in dtstart else "All Day"
            events.append({"date": d_str, "time": t_str, "title": summary})

print(json.dumps({"events": events}))
PYEOF
    ;;
esac
