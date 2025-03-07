#!/system/bin/sh
# Uninstall script for Thermal Guardian Pro

# Define colors for pretty output
G="\033[1;32m"  # Green
R="\033[1;31m"  # Red
Y="\033[1;33m"  # Yellow
N="\033[0m"     # No color

echo " "
echo -e "${Y}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${N}"
echo -e "${Y}┃ ${R}🔥 THERMAL GUARDIAN PRO UNINSTALLER 🔥   ${Y}┃${N}"
echo -e "${Y}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${N}"
echo " "

# Restore original thermal configurations if backups exist
if [ -d "/data/local/thermal_backup" ]; then
    echo -e "${G}• Restoring original thermal configurations...${N}"
    
    # Restore thermal configs
    if [ -d "/data/vendor/thermal/" ]; then
        for backup in /data/local/thermal_backup/*.conf; do
            if [ -f "$backup" ]; then
                filename=$(basename "$backup")
                cp -f "$backup" "/data/vendor/thermal/$filename" 2>/dev/null
                echo -e "${G}  - Restored: $filename${N}"
            fi
        done
    fi
    
    echo -e "${G}• Original thermal configurations restored${N}"
fi

# Kill any running processes
echo -e "${G}• Stopping Thermal Guardian Pro services...${N}"
for pid in $(pgrep -f "post-fs-data.sh"); do
    kill -9 $pid 2>/dev/null
done

# Remove any gaming mode settings
if [ -f "/data/local/tmp/thermal_logs/gaming_mode_active" ]; then
    echo -e "${Y}• Deactivating gaming mode...${N}"
    sh "$MODPATH/gaming.sh" stop 2>/dev/null
fi

# Reset thermal properties
echo -e "${G}• Resetting thermal properties...${N}"
resetprop --delete persist.vendor.thermal.cpu_temp_limit
resetprop --delete persist.vendor.thermal.gpu_temp_limit
resetprop --delete ro.thermal.manager.enable
resetprop --delete persist.sys.thermal.throttling
resetprop --delete persist.sys.cpu.max_freq
resetprop --delete persist.sys.gpu.max_freq
resetprop --delete persist.vendor.thermal.cpu_temp_threshold
resetprop --delete persist.vendor.thermal.gpu_temp_threshold
resetprop --delete persist.sys.hyperos.thermal.mode
resetprop --delete persist.vendor.disable.thermal.control

# Restore CPU governor settings
echo -e "${G}• Restoring CPU governor settings...${N}"
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "schedutil" > "$cpu" 2>/dev/null
done

# Ask if user wants to keep logs
echo " "
echo -e "${Y}• Would you like to keep Thermal Guardian logs for troubleshooting?${N}"
echo -e "${Y}  1. Yes, keep logs${N}"
echo -e "${Y}  2. No, remove all logs${N}"
echo " "
echo -n -e "${Y}Enter your choice (1-2): ${N}"
read choice

if [ "$choice" = "2" ]; then
    echo -e "${G}• Removing all logs and temporary files...${N}"
    rm -rf /data/local/tmp/thermal_logs
    rm -rf /data/local/thermal_backup
    echo -e "${G}• All logs removed${N}"
else
    echo -e "${G}• Keeping logs at /data/local/tmp/thermal_logs for reference${N}"
fi

echo " "
echo -e "${G}• Thermal Guardian Pro has been successfully uninstalled${N}"
echo -e "${G}• Please reboot your device for changes to take effect${N}"
echo " "