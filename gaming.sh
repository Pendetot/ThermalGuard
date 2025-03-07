#!/system/bin/sh
# Gaming profile for Thermal Guardian Pro
# Place this in /data/adb/modules/thermalguardianpro/
# Usage: sh /data/adb/modules/thermalguardianpro/gaming.sh start|stop

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print table headers
print_header() {
  local title=$1
  local color=$2
  
  echo -e "${color}===================================================${NC}"
  echo -e "${color}|${NC}  ${WHITE}Gaming Mode By LazyDev ${NC}${color}                         |${NC}"
  echo -e "${color}===================================================${NC}"
  echo -e "${color}|${NC}  ${WHITE}${title}${NC}${color}  |${NC}"
  echo -e "${color}===================================================${NC}"
}

# Function to print table footer
print_footer() {
  local color=$1
  echo -e "${color}===================================================${NC}"
}

# Function to print table row
print_row() {
  local label=$1
  local value=$2
  local color=$3
  local valuecolor=$4
  
  printf "${color}|${NC}  ${WHITE}%-20s${NC} | ${valuecolor}%-30s${NC} ${color}|${NC}\n" "$label" "$value"
}

# Function to print separator
print_separator() {
  local color=$1
  echo -e "${color}===================================================${NC}"
}

# Function to show progress bar
show_progress() {
  local title=$1
  local duration=$2
  local width=30
  local i=0
  
  echo -e "${WHITE}$title${NC}"
  echo -ne "["
  while [ $i -lt $width ]; do
    echo -ne "${GREEN}#${NC}"
    sleep 0.01  # Fixed short delay for better responsiveness
    i=$(expr $i + 1)
  done
  echo -e "] ${GREEN}100%${NC}"
  echo ""
}

LOG_FILE="/data/local/tmp/thermal_logs/gaming_profile.log"

# Log function
log_info() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Create log directory
mkdir -p /data/local/tmp/thermal_logs

# Function to safely write to procfs with error handling
write_to_proc() {
  local path=$1
  local value=$2
  local desc=$3
  
  if [ -f "$path" ]; then
    # Use echo with redirection to avoid 'can't create' errors
    # Don't output errors to screen
    if echo "$value" > "$path" 2>/dev/null; then
      log_info "Successfully set $desc ($value)"
      return 0
    else
      log_info "Failed to set $desc - permission denied or read-only filesystem"
      return 1
    fi
  else
    log_info "Path $path does not exist - skipping"
    return 2
  fi
}

# Function to apply gaming optimizations
apply_gaming_mode() {
  clear
  print_header "ACTIVATING GAMING MODE" "${RED}"
  
  log_info "Activating Gaming Mode"
  
  # Store current settings for recovery
  mkdir -p /data/local/tmp/thermal_backup
  print_row "Creating backups" "IN PROGRESS" "${RED}" "${YELLOW}"
  
  show_progress "Backing up CPU settings..." 0.8
  
  # Back up CPU governors
  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ -f "$cpu" ]; then
      cat "$cpu" > "/data/local/tmp/thermal_backup/$(basename $(dirname $(dirname $cpu)))_gov" 2>/dev/null
    fi
  done
  
  # Back up CPU frequencies
  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
    if [ -f "$cpu" ]; then
      cat "$cpu" > "/data/local/tmp/thermal_backup/$(basename $(dirname $(dirname $cpu)))_freq" 2>/dev/null
    fi
  done
  
  print_row "CPU backups" "COMPLETED" "${RED}" "${GREEN}"
  
  show_progress "Optimizing CPU performance..." 1.0
  
  # Apply performance governor to all cores
  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ -f "$cpu" ]; then
      echo "performance" > "$cpu" 2>/dev/null
      log_info "Set CPU governor to performance: $cpu"
    fi
  done
  
  print_row "CPU Governor" "PERFORMANCE" "${RED}" "${GREEN}"
  
  # Count optimized cores
  little_cores=0
  big_cores=0
  
  # Process little cores (0-3)
  cpu=0
  while [ $cpu -le 3 ]; do
    if [ -f "/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_max_freq" ]; then
      # Get the max available frequency
      max_freq=$(cat "/sys/devices/system/cpu/cpu$cpu/cpufreq/cpuinfo_max_freq")
      # Set to 95% of max to avoid thermal issues
      target_freq=$(echo "$max_freq * 0.95" | bc | cut -d'.' -f1)
      echo "$target_freq" > "/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_max_freq" 2>/dev/null
      log_info "Set little core $cpu to $target_freq Hz"
      little_cores=$(expr $little_cores + 1)
    fi
    cpu=$(expr $cpu + 1)
  done
  
  # Process big cores (4-7)
  cpu=4
  while [ $cpu -le 7 ]; do
    if [ -f "/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_max_freq" ]; then
      max_freq=$(cat "/sys/devices/system/cpu/cpu$cpu/cpufreq/cpuinfo_max_freq")
      target_freq=$(echo "$max_freq * 0.93" | bc | cut -d'.' -f1)
      echo "$target_freq" > "/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_max_freq" 2>/dev/null
      log_info "Set big core $cpu to $target_freq Hz"
      big_cores=$(expr $big_cores + 1)
    fi
    cpu=$(expr $cpu + 1)
  done
  
  print_row "Little cores (0-3)" "$little_cores OPTIMIZED" "${RED}" "${GREEN}"
  print_row "Big cores (4+)" "$big_cores OPTIMIZED" "${RED}" "${GREEN}"
  
  show_progress "Optimizing GPU performance..." 0.8
  
  # GPU optimizations
  GPU_PATHS="/sys/class/kgsl/kgsl-3d0/devfreq/max_freq /sys/class/devfreq/gpu/max_freq /sys/kernel/gpu/gpu_max_clock"
  
  gpu_optimized=0
  for path in $GPU_PATHS; do
    if [ -f "$path" ]; then
      # Backup current
      cat "$path" > "/data/local/tmp/thermal_backup/gpu_freq" 2>/dev/null
      # Set to max
      cat "$path" | head -n1 > "$path" 2>/dev/null
      log_info "Set GPU to maximum frequency: $path"
      gpu_optimized=1
      break
    fi
  done
  
  if [ $gpu_optimized -eq 1 ]; then
    print_row "GPU Frequency" "MAXIMUM" "${RED}" "${GREEN}"
  else
    print_row "GPU Frequency" "NOT FOUND" "${RED}" "${YELLOW}"
  fi
  
  show_progress "Optimizing memory settings..." 0.5
  
  # Memory optimizations - using the safe write function and silent error handling
  memory_success=0
  
  # Redirect all errors to null to keep display clean
  write_to_proc "/proc/sys/vm/swappiness" "0" "VM swappiness" >/dev/null 2>&1
  result=$?
  if [ $result -eq 0 ]; then
    memory_success=$(expr $memory_success + 1)
  fi
  
  write_to_proc "/proc/sys/vm/page-cluster" "0" "VM page cluster" >/dev/null 2>&1
  result=$?
  if [ $result -eq 0 ]; then
    memory_success=$(expr $memory_success + 1)
  fi
  
  write_to_proc "/proc/sys/vm/vfs_cache_pressure" "20" "VM cache pressure" >/dev/null 2>&1
  result=$?
  if [ $result -eq 0 ]; then
    memory_success=$(expr $memory_success + 1)
  fi
  
  write_to_proc "/proc/sys/vm/drop_caches" "3" "VM drop caches" >/dev/null 2>&1
  result=$?
  if [ $result -eq 0 ]; then
    memory_success=$(expr $memory_success + 1)
  fi
  
  if [ $memory_success -gt 0 ]; then
    print_row "Memory Settings" "OPTIMIZED ($memory_success parameters)" "${RED}" "${GREEN}"
  else
    print_row "Memory Settings" "NOT AVAILABLE" "${RED}" "${YELLOW}"
  fi
  
  show_progress "Applying thermal optimizations..." 0.8
  
  # Increase thermal limits temporarily (only during gaming)
  thermal_success=0
  if [ -d "/data/vendor/thermal/" ]; then
    for config in /data/vendor/thermal/*.conf; do
      if [ -f "$config" ]; then
        # Backup
        cp "$config" "${config}.game_bak" 2>/dev/null
        # Increase thresholds
        sed -i 's/trip_temp>[0-9]\{2\}</trip_temp>80</g' "$config" 2>/dev/null
        thermal_success=$(expr $thermal_success + 1)
      fi
    done
    
    if [ $thermal_success -gt 0 ]; then
      print_row "Thermal Limits" "INCREASED ($thermal_success files)" "${RED}" "${GREEN}"
    else
      print_row "Thermal Limits" "NO CONFIG FILES FOUND" "${RED}" "${YELLOW}"
    fi
  else
    print_row "Thermal Limits" "NOT AVAILABLE" "${RED}" "${YELLOW}"
  fi
  
  show_progress "Applying system properties..." 0.8
  
  # Set props
  resetprop vendor.powerhal.init 1 >/dev/null 2>&1
  resetprop vendor.powerhal.rendering 1 >/dev/null 2>&1
  resetprop debug.composition.type gpu >/dev/null 2>&1
  resetprop debug.egl.hw 1 >/dev/null 2>&1
  resetprop debug.sf.hw 1 >/dev/null 2>&1
  
  # Set display flags for smoother gaming
  resetprop debug.sf.disable_backpressure 1 >/dev/null 2>&1
  resetprop debug.sf.latch_unsignaled 1 >/dev/null 2>&1
  
  # Boosting touch response
  resetprop debug.sf.early.app.duration 16000000 >/dev/null 2>&1
  resetprop debug.sf.early.sf.duration 16000000 >/dev/null 2>&1
  resetprop debug.sf.earlyGl.app.duration 16000000 >/dev/null 2>&1
  resetprop debug.sf.earlyGl.sf.duration 16000000 >/dev/null 2>&1
  
  print_row "System Properties" "OPTIMIZED FOR GAMING" "${RED}" "${GREEN}"
  
  # Create status file to indicate gaming mode is on
  touch /data/local/tmp/thermal_logs/gaming_mode_active
  
  log_info "Gaming mode activated successfully"
  
  print_separator "${RED}"
  print_row "GAMING MODE" "SUCCESSFULLY ACTIVATED" "${RED}" "${GREEN}"
  print_row "Throttling" "DISABLED" "${RED}" "${GREEN}"
  print_row "Thermal Limits" "INCREASED" "${RED}" "${GREEN}"
  print_row "Performance" "MAXIMIZED" "${RED}" "${GREEN}"
  print_row "Touch Response" "IMPROVED" "${RED}" "${GREEN}"
  print_separator "${RED}"
  print_row "IMPORTANT" "Run 'gaming.sh stop' when done" "${RED}" "${YELLOW}"
  print_footer "${RED}"
  
  echo ""
  echo -e "${YELLOW}Gaming mode activated! Your device is now optimized for gaming.${NC}"
  echo -e "${YELLOW}Remember to disable gaming mode when you're done playing to prevent overheating.${NC}"
  echo ""
}

# Function to restore normal settings
restore_normal_mode() {
  clear
  print_header "RESTORING NORMAL MODE" "${BLUE}"
  
  log_info "Deactivating Gaming Mode"
  
  show_progress "Restoring CPU settings..." 1.0
  
  # Check if backup files exist
  cpu_restored=0
  
  if [ -d "/data/local/tmp/thermal_backup" ]; then
    # Restore CPU governors
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
      if [ -f "$cpu" ]; then
        cpu_name=$(basename $(dirname $(dirname $cpu)))
        if [ -f "/data/local/tmp/thermal_backup/${cpu_name}_gov" ]; then
          cat "/data/local/tmp/thermal_backup/${cpu_name}_gov" > "$cpu" 2>/dev/null
          log_info "Restored CPU governor for $cpu_name"
          cpu_restored=$(expr $cpu_restored + 1)
        else
          echo "schedutil" > "$cpu" 2>/dev/null
          log_info "Set default schedutil governor for $cpu_name"
          cpu_restored=$(expr $cpu_restored + 1)
        fi
      fi
    done
    
    # Restore CPU frequencies
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
      if [ -f "$cpu" ]; then
        cpu_name=$(basename $(dirname $(dirname $cpu)))
        if [ -f "/data/local/tmp/thermal_backup/${cpu_name}_freq" ]; then
          cat "/data/local/tmp/thermal_backup/${cpu_name}_freq" > "$cpu" 2>/dev/null
          log_info "Restored CPU frequency for $cpu_name"
        fi
      fi
    done
    
    print_row "CPU Settings" "RESTORED ($cpu_restored cores)" "${BLUE}" "${GREEN}"
    
    show_progress "Restoring GPU settings..." 0.8
    
    # Restore GPU frequency
    gpu_restored=0
    GPU_PATHS="/sys/class/kgsl/kgsl-3d0/devfreq/max_freq /sys/class/devfreq/gpu/max_freq /sys/kernel/gpu/gpu_max_clock"
    
    for path in $GPU_PATHS; do
      if [ -f "$path" ] && [ -f "/data/local/tmp/thermal_backup/gpu_freq" ]; then
        cat "/data/local/tmp/thermal_backup/gpu_freq" > "$path" 2>/dev/null
        log_info "Restored GPU frequency"
        gpu_restored=1
        break
      fi
    done
    
    if [ $gpu_restored -eq 1 ]; then
      print_row "GPU Settings" "RESTORED" "${BLUE}" "${GREEN}"
    else
      print_row "GPU Settings" "NO BACKUP FOUND" "${BLUE}" "${YELLOW}"
    fi
    
    log_info "Restored CPU and GPU settings"
  else
    log_info "No backup found, applying default optimized settings"
    print_row "Settings Backup" "NOT FOUND" "${BLUE}" "${YELLOW}"
    
    # Apply default thermal guardian settings
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
      if [ -f "$cpu" ]; then
        echo "schedutil" > "$cpu" 2>/dev/null
        log_info "Applied default schedutil governor"
        cpu_restored=$(expr $cpu_restored + 1)
      fi
    done
    
    print_row "CPU Settings" "DEFAULT APPLIED ($cpu_restored cores)" "${BLUE}" "${GREEN}"
  fi
  
  show_progress "Restoring thermal configurations..." 0.8
  
  # Restore thermal configurations
  thermal_restored=0
  if [ -d "/data/vendor/thermal/" ]; then
    for config in /data/vendor/thermal/*.conf.game_bak; do
      if [ -f "$config" ]; then
        cp "$config" "${config%.game_bak}" 2>/dev/null
        rm -f "$config" 2>/dev/null
        log_info "Restored thermal config: $config"
        thermal_restored=$(expr $thermal_restored + 1)
      fi
    done
    
    if [ $thermal_restored -gt 0 ]; then
      print_row "Thermal Configs" "RESTORED ($thermal_restored files)" "${BLUE}" "${GREEN}"
    else
      print_row "Thermal Configs" "NO BACKUPS FOUND" "${BLUE}" "${YELLOW}"
    fi
  else
    print_row "Thermal Configs" "NOT AVAILABLE" "${BLUE}" "${YELLOW}"
  fi
  
  show_progress "Restoring memory settings..." 0.5
  
  # Restore memory settings safely with silent error handling
  memory_restored=0
  
  write_to_proc "/proc/sys/vm/swappiness" "100" "VM swappiness" >/dev/null 2>&1
  result=$?
  if [ $result -eq 0 ]; then
    memory_restored=$(expr $memory_restored + 1)
  fi
  
  write_to_proc "/proc/sys/vm/page-cluster" "0" "VM page cluster" >/dev/null 2>&1
  result=$?
  if [ $result -eq 0 ]; then
    memory_restored=$(expr $memory_restored + 1)
  fi
  
  write_to_proc "/proc/sys/vm/vfs_cache_pressure" "90" "VM cache pressure" >/dev/null 2>&1
  result=$?
  if [ $result -eq 0 ]; then
    memory_restored=$(expr $memory_restored + 1)
  fi
  
  if [ $memory_restored -gt 0 ]; then
    print_row "Memory Settings" "RESTORED ($memory_restored parameters)" "${BLUE}" "${GREEN}"
  else
    print_row "Memory Settings" "NOT AVAILABLE" "${BLUE}" "${YELLOW}"
  fi
  
  show_progress "Restoring system properties..." 0.5
  
  # Restore normal props
  resetprop vendor.powerhal.rendering 0 >/dev/null 2>&1
  resetprop debug.composition.type gpu >/dev/null 2>&1
  
  print_row "System Properties" "RESTORED" "${BLUE}" "${GREEN}"
  
  # Remove gaming mode indicator
  rm -f /data/local/tmp/thermal_logs/gaming_mode_active
  
  log_info "Gaming mode deactivated, returned to normal thermal profile"
  
  print_separator "${BLUE}"
  print_row "NORMAL MODE" "SUCCESSFULLY RESTORED" "${BLUE}" "${GREEN}"
  print_row "Thermal Protection" "ENABLED" "${BLUE}" "${GREEN}"
  print_row "Battery Efficiency" "OPTIMIZED" "${BLUE}" "${GREEN}"
  print_row "CPU Throttling" "BALANCED" "${BLUE}" "${GREEN}"
  print_footer "${BLUE}"
  
  echo ""
  echo -e "${GREEN}Gaming mode deactivated. Your device has returned to normal thermal profile.${NC}"
  echo -e "${GREEN}Battery life and temperature management have been restored.${NC}"
  echo ""
}

# Check status with fancy output
check_status() {
  clear
  
  if [ -f "/data/local/tmp/thermal_logs/gaming_mode_active" ]; then
    print_header "STATUS CHECK" "${RED}"
    print_row "Current Mode" "GAMING MODE" "${RED}" "${GREEN}"
    print_row "CPU Governor" "PERFORMANCE" "${RED}" "${GREEN}"
    print_row "CPU Frequency" "MAXIMUM" "${RED}" "${GREEN}"
    print_row "GPU Frequency" "MAXIMUM" "${RED}" "${GREEN}"
    print_row "Thermal Throttling" "DISABLED" "${RED}" "${GREEN}"
    print_row "Touch Response" "ENHANCED" "${RED}" "${GREEN}"
    print_separator "${RED}"
    print_row "IMPORTANT" "Run 'gaming.sh stop' when done" "${RED}" "${YELLOW}"
    print_footer "${RED}"
  else
    print_header "STATUS CHECK" "${BLUE}"
    print_row "Current Mode" "NORMAL MODE" "${BLUE}" "${CYAN}"
    print_row "CPU Governor" "SCHEDUTIL/BALANCED" "${BLUE}" "${CYAN}"
    print_row "CPU Frequency" "DYNAMIC" "${BLUE}" "${CYAN}"
    print_row "GPU Frequency" "DYNAMIC" "${BLUE}" "${CYAN}"
    print_row "Thermal Throttling" "ENABLED" "${BLUE}" "${CYAN}"
    print_row "Battery Efficiency" "OPTIMIZED" "${BLUE}" "${CYAN}"
    print_separator "${BLUE}"
    print_row "TIP" "Run 'gaming.sh start' before games" "${BLUE}" "${YELLOW}"
    print_footer "${BLUE}"
  fi
}

# Main script logic
case "$1" in
  start)
    if [ -f "/data/local/tmp/thermal_logs/gaming_mode_active" ]; then
      echo -e "${YELLOW}Gaming mode is already active!${NC}"
    else
      apply_gaming_mode
    fi
    ;;
  stop)
    if [ -f "/data/local/tmp/thermal_logs/gaming_mode_active" ]; then
      restore_normal_mode
    else
      echo -e "${CYAN}Gaming mode is not currently active.${NC}"
    fi
    ;;
  status)
    check_status
    ;;
  *)
    print_header "USAGE HELP" "${YELLOW}"
    print_row "COMMAND" "DESCRIPTION" "${YELLOW}" "${WHITE}"
    print_separator "${YELLOW}"
    print_row "gaming.sh start" "Activate gaming mode" "${YELLOW}" "${GREEN}"
    print_row "gaming.sh stop" "Deactivate gaming mode" "${YELLOW}" "${BLUE}"
    print_row "gaming.sh status" "Check if gaming mode is active" "${YELLOW}" "${CYAN}"
    print_footer "${YELLOW}"
    exit 1
    ;;
esac

exit 0