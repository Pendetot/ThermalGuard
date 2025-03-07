#!/system/bin/sh

# Detect ROM Type
if [ -f "/system/build.prop" ]; then
  ROM_TYPE=$(grep -o "ro.miui.ui.version.*" /system/build.prop | grep -o "HyperOS" || echo "OTHER")
else
  ROM_TYPE="OTHER"
fi

# Create log directory
mkdir -p /data/local/tmp/thermal_logs
LOG_FILE="/data/local/tmp/thermal_logs/thermal_guardian.log"

# Log function
log_info() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

log_info "Thermal Guardian starting... ROM detected: $ROM_TYPE"

# Check if device has big.LITTLE or DynamIQ CPU architecture
if [ -d "/sys/devices/system/cpu/cpu6/cpufreq/" ]; then
  # 3-cluster CPU (likely Snapdragon 8xx series)
  LITTLE_CORES="0-3"
  MEDIUM_CORES="4-6"
  BIG_CORES="7"
  log_info "Detected 3-cluster CPU architecture"
elif [ -d "/sys/devices/system/cpu/cpu4/cpufreq/" ]; then
  # 2-cluster CPU (big.LITTLE)
  LITTLE_CORES="0-3"
  BIG_CORES="4-7"
  log_info "Detected big.LITTLE CPU architecture"
else
  # Single cluster
  LITTLE_CORES="0-$(( $(grep -c processor /proc/cpuinfo) - 1 ))"
  BIG_CORES=""
  log_info "Detected single-cluster CPU architecture"
fi

# Apply core-specific optimizations
optimize_cores() {
  local temp=$1
  local governor=$2
  local little_max_freq=$3
  local big_max_freq=$4
  
  # Apply CPU governor
  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "$governor" > "$cpu" 2>/dev/null
  done
  
  # Apply frequency limits to little cores
  for cpu in $(seq 0 3); do
    if [ -f "/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_max_freq" ]; then
      echo "$little_max_freq" > "/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_max_freq" 2>/dev/null
    fi
  done
  
  # Apply frequency limits to big cores if they exist
  if [ -n "$BIG_CORES" ]; then
    for cpu in $(seq 4 7); do
      if [ -f "/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_max_freq" ]; then
        echo "$big_max_freq" > "/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_max_freq" 2>/dev/null
      fi
    done
  fi
  
  log_info "Applied optimization for temp $temp°C: $governor governor, little cores: $little_max_freq, big cores: $big_max_freq"
}

# GPU optimization
optimize_gpu() {
  local level=$1
  
  # Try different GPU paths (varies by device)
  GPU_PATHS=(
    "/sys/class/kgsl/kgsl-3d0/devfreq/max_freq"  # Qualcomm
    "/sys/class/devfreq/gpu/max_freq"            # MediaTek
    "/sys/kernel/gpu/gpu_max_clock"              # Samsung Exynos
  )
  
  for path in "${GPU_PATHS[@]}"; do
    if [ -f "$path" ]; then
      case $level in
        "high")
          cat "$path" | head -n1 > "$path" 2>/dev/null  # Maximum frequency
          ;;
        "medium")
          cat "$path" | head -n1 | awk '{print int($1*0.85)}' > "$path" 2>/dev/null  # 85% of max
          ;;
        "low")
          cat "$path" | head -n1 | awk '{print int($1*0.70)}' > "$path" 2>/dev/null  # 70% of max
          ;;
      esac
      log_info "Applied GPU optimization level: $level to $path"
      break
    fi
  done
}

# HyperOS-specific optimizations
apply_hyperos_tweaks() {
  if [ "$ROM_TYPE" = "HyperOS" ]; then
    # Disable MIUI/HyperOS agressive thermal throttling
    resetprop persist.vendor.disable.thermal.control 1
    resetprop persist.sys.thermal.config 0
    
    # Modify HyperOS thermal configs
    if [ -d "/data/vendor/thermal/" ]; then
      for config in /data/vendor/thermal/*.conf; do
        if [ -f "$config" ]; then
          # Backup original config if not already backed up
          if [ ! -f "${config}.bak" ]; then
            cp "$config" "${config}.bak"
          fi
          
          # Increase thermal limits in HyperOS thermal configs
          sed -i 's/trip_temp>[0-9]\{2\}</trip_temp>75</g' "$config" 2>/dev/null
          log_info "Modified HyperOS thermal config: $config"
        fi
      done
    fi
  fi
}

# Apply initial HyperOS optimizations
apply_hyperos_tweaks

# Find the correct thermal zone
for i in $(seq 0 20); do
  if [ -f "/sys/class/thermal/thermal_zone$i/type" ]; then
    TYPE=$(cat "/sys/class/thermal/thermal_zone$i/type")
    if [[ "$TYPE" == *"cpu"* ]] || [[ "$TYPE" == *"CPU"* ]] || [[ "$TYPE" == *"cluster"* ]]; then
      CPU_THERMAL_ZONE=$i
      log_info "Found CPU thermal zone: thermal_zone$i ($TYPE)"
      break
    fi
  fi
done

# Fallback to thermal_zone0 if no CPU thermal zone found
if [ -z "$CPU_THERMAL_ZONE" ]; then
  CPU_THERMAL_ZONE=0
  log_info "No specific CPU thermal zone found, using thermal_zone0"
fi

# Advanced thermal management loop
while true; do
  # Read CPU temperature (divide by 1000 if value is in millicelsius)
  if [ -f "/sys/class/thermal/thermal_zone$CPU_THERMAL_ZONE/temp" ]; then
    CPU_TEMP_RAW=$(cat "/sys/class/thermal/thermal_zone$CPU_THERMAL_ZONE/temp")
    
    # Check if temp is in millicelsius (>1000) or celsius
    if [ "$CPU_TEMP_RAW" -gt 1000 ]; then
      CPU_TEMP=$(awk "BEGIN {print $CPU_TEMP_RAW/1000}")
    else
      CPU_TEMP=$CPU_TEMP_RAW
    fi
  else
    # Fallback
    CPU_TEMP=50
    log_info "Could not read CPU temperature, assuming 50°C"
  fi
  
  # Get current battery temperature
  if [ -f "/sys/class/power_supply/battery/temp" ]; then
    BATT_TEMP=$(awk "BEGIN {print $(cat /sys/class/power_supply/battery/temp)/10}")
  else
    BATT_TEMP=30
  fi
  
  # Check if device is charging
  IS_CHARGING=0
  if [ -f "/sys/class/power_supply/battery/status" ]; then
    BATT_STATUS=$(cat /sys/class/power_supply/battery/status)
    if [ "$BATT_STATUS" = "Charging" ]; then
      IS_CHARGING=1
    fi
  fi
  
  # Adaptive thermal management based on temperatures
  if [ "$CPU_TEMP" -ge 75 ]; then
    # Emergency mode: Aggressive throttling for extreme temperatures
    optimize_cores "$CPU_TEMP" "schedutil" 1100000 1400000
    optimize_gpu "low"
    log_info "EMERGENCY COOLING: CPU temp $CPU_TEMP°C, Battery temp $BATT_TEMP°C"
    sleep 3  # Shorter interval for critical temperatures
    
  elif [ "$CPU_TEMP" -ge 65 ]; then
    # High temperature mode: Strong throttling
    optimize_cores "$CPU_TEMP" "schedutil" 1400000 1800000
    optimize_gpu "low"
    log_info "HIGH TEMP MODE: CPU temp $CPU_TEMP°C, Battery temp $BATT_TEMP°C"
    sleep 5
    
  elif [ "$CPU_TEMP" -ge 55 ]; then
    # Moderate temperature mode: Balanced approach
    optimize_cores "$CPU_TEMP" "schedutil" 1600000 2000000
    optimize_gpu "medium"
    log_info "MODERATE TEMP MODE: CPU temp $CPU_TEMP°C, Battery temp $BATT_TEMP°C"
    sleep 8
    
  else
    # Cool temperature mode: Performance optimized
    if [ "$IS_CHARGING" -eq 1 ] && [ "$BATT_TEMP" -ge 38 ]; then
      # Reduce performance if battery is hot while charging
      optimize_cores "$CPU_TEMP" "schedutil" 1600000 2000000
      optimize_gpu "medium"
      log_info "BATTERY PROTECTION MODE: CPU temp $CPU_TEMP°C, Battery temp $BATT_TEMP°C (Charging)"
    else
      # Full performance when cool
      optimize_cores "$CPU_TEMP" "performance" 1800000 2400000
      optimize_gpu "high"
      log_info "PERFORMANCE MODE: CPU temp $CPU_TEMP°C, Battery temp $BATT_TEMP°C"
    fi
    sleep 10
  fi
  
  # Reapply HyperOS tweaks periodically
  if [ $(( RANDOM % 60 )) -eq 0 ]; then
    apply_hyperos_tweaks
  fi
done &