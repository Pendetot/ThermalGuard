#!/system/bin/sh
# Additional service script for Thermal Guardian Pro
# This runs on boot to apply additional optimizations

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/thermal_logs/boot_service.log"

# Log function
log_info() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Create log directory
mkdir -p /data/local/tmp/thermal_logs
log_info "Thermal Guardian Pro service started"

# Wait for system boot to complete
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 2
done

log_info "System boot completed, applying additional optimizations"

# Detect ROM type
if grep -q "HyperOS" /system/build.prop; then
    ROM="HyperOS"
    log_info "HyperOS detected, applying specific optimizations"
    
    # Apply HyperOS-specific tweaks
    resetprop persist.vendor.disable.thermal.control 1
    resetprop persist.sys.thermal.config 0
    resetprop persist.sys.hyperos.thermal.mode balanced
    
    # Disable MIUI/HyperOS thermal services
    for svc in thermal-engine thermal-hal thermal-manager; do
        if pgrep -f "$svc" > /dev/null; then
            log_info "Found running thermal service: $svc"
            # Just set properties instead of stopping services
            resetprop persist.vendor.$svc.mode balanced
            resetprop persist.vendor.$svc.config custom
        fi
    done
    
    log_info "HyperOS thermal services reconfigured"
else
    log_info "Non-HyperOS ROM detected, using generic thermal optimizations"
fi

# Apply scheduler tweaks
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "schedutil" > $cpu 2>/dev/null
done

log_info "Applied schedutil governor to all CPUs"

# GPU governor optimization
gpu_paths=(
    "/sys/class/kgsl/kgsl-3d0/devfreq/governor"
    "/sys/class/devfreq/gpu/governor"
    "/sys/devices/platform/kgsl-3d0/devfreq/kgsl-3d0/governor"
)

for path in "${gpu_paths[@]}"; do
    if [ -f "$path" ]; then
        echo "msm-adreno-tz" > "$path" 2>/dev/null || echo "simple_ondemand" > "$path" 2>/dev/null
        log_info "Applied GPU governor: $path"
        break
    fi
done

# IO scheduler optimization
for block in /sys/block/*/queue/scheduler; do
    echo "cfq" > "$block" 2>/dev/null
done

log_info "Applied CFQ IO scheduler"

# Memory management optimization
echo "100" > /proc/sys/vm/swappiness 2>/dev/null
echo "0" > /proc/sys/vm/page-cluster 2>/dev/null
echo "90" > /proc/sys/vm/vfs_cache_pressure 2>/dev/null
echo "3" > /proc/sys/vm/drop_caches 2>/dev/null

log_info "Applied memory management optimizations"

# Network optimization
sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null
sysctl -w net.ipv4.tcp_ecn=1 2>/dev/null

log_info "Applied network optimizations"

# Apply thermal optimizations
if [ -d "/data/vendor/thermal" ]; then
    log_info "Updating vendor thermal configurations"
    
    # Create backup if not already done
    mkdir -p /data/local/thermal_backup
    for conf in /data/vendor/thermal/*.conf; do
        if [ -f "$conf" ] && [ ! -f "/data/local/thermal_backup/$(basename $conf)" ]; then
            cp "$conf" "/data/local/thermal_backup/" 2>/dev/null
            log_info "Backed up thermal config: $(basename $conf)"
        fi
    done
    
    # Copy our optimized thermal config
    if [ -f "$MODDIR/thermal-engine.conf" ]; then
        cp "$MODDIR/thermal-engine.conf" /data/vendor/thermal/ 2>/dev/null
        log_info "Copied optimized thermal config to vendor"
    fi
fi

# Mark service as successfully completed
touch /data/local/tmp/thermal_logs/service_success
log_info "Thermal Guardian Pro service completed successfully"

# Start thermal monitoring in background
nohup sh -c "sh $MODDIR/post-fs-data.sh" > /dev/null 2>&1 &
log_info "Started thermal monitoring background service"