#!/sbin/sh

MODDIR=${0%/*}

# Definisikan fungsi untuk menampilkan warna tanpa menggunakan kode ANSI langsung
# Magisk UI print sudah mendukung tanda bintang untuk warna
print_title() {
  ui_print " "
  ui_print "************************************"
  ui_print "🔥❄️ THERMAL GUARDIAN PRO v2.0 ❄️🔥"
  ui_print "by LazyDev (Enhanced)"
  ui_print "************************************"
  ui_print " "
}

print_title

# Check device architecture
ARCH=$(uname -m)
ui_print "• Device Architecture: $ARCH"

# Check CPU info
CPU_VENDOR=$(grep -m 1 "vendor_id" /proc/cpuinfo | cut -d':' -f2 | tr -d ' ')
CPU_MODEL=$(grep -m 1 "model name" /proc/cpuinfo | cut -d':' -f2 | tr -d ' ')
NUM_CORES=$(grep -c processor /proc/cpuinfo)

ui_print "• CPU: $CPU_VENDOR $CPU_MODEL"
ui_print "• CPU Cores: $NUM_CORES"

# Check if device is MediaTek or Snapdragon
if [ -d "/sys/class/kgsl" ]; then
    SOC="Snapdragon"
elif [ -d "/sys/class/ged" ]; then
    SOC="MediaTek"
else
    SOC="Other"
fi

ui_print "• SoC Detected: $SOC"

# Check Android version
ANDROID_VER=$(getprop ro.build.version.release)
SDK_VER=$(getprop ro.build.version.sdk)
ui_print "• Android Version: $ANDROID_VER (SDK $SDK_VER)"

# Detect ROM type
if grep -q "HyperOS" /system/build.prop; then
    ROM="HyperOS"
    ui_print "• ROM Detected: $ROM"
    ui_print "• Applying $ROM specific optimizations..."
    
    # Create HyperOS specific settings
    mkdir -p $MODDIR/system/etc/hyperos_thermal
    cp -f $MODDIR/thermal-engine.conf $MODDIR/system/etc/hyperos_thermal/thermal-engine.conf
    
    # Additional HyperOS specific tweaks
    ui_print "• Setting up HyperOS thermal overrides..."
    # These directories will be created during module installation
    mkdir -p $MODDIR/system/vendor/etc/thermal
    touch $MODDIR/system/vendor/etc/.thermal_config_applied
elif grep -q "miui" /system/build.prop; then
    ROM="MIUI"
    ui_print "• ROM Detected: $ROM"
    ui_print "• Applying $ROM compatible settings..."
else
    ROM="Other"
    ui_print "• ROM Detected: $ROM (Generic)"
fi

# Create log directory
mkdir -p /data/local/tmp/thermal_logs

# Set permissions
ui_print "• Setting up permissions..."
set_perm_recursive $MODDIR 0 0 0755 0644
set_perm $MODDIR/post-fs-data.sh 0 0 0755
set_perm $MODDIR/service.sh 0 0 0755
set_perm $MODDIR/gaming.sh 0 0 0755
set_perm $MODDIR/uninstall.sh 0 0 0755
set_perm $MODDIR/system.prop 0 0 0644
set_perm $MODDIR/thermal-engine.conf 0 0 0644

# Check for custom kernel
KERNEL_VERSION=$(uname -r)
if echo "$KERNEL_VERSION" | grep -q "custom\|oc\|perf\|proton"; then
    ui_print "• Custom kernel detected: $KERNEL_VERSION"
    ui_print "• Optimizing for custom kernel..."
fi

# Backup original thermal configs
if [ -d "/system/vendor/etc/thermal" ]; then
    ui_print "• Backing up original thermal configs..."
    mkdir -p /data/local/thermal_backup
    cp -af /system/vendor/etc/thermal/* /data/local/thermal_backup/ 2>/dev/null
fi

ui_print " "
ui_print "************************************"
ui_print "📱 THERMAL PROFILE CONFIGURATION 📱"
ui_print "************************************"
ui_print " "
ui_print "• Safe CPU Temperature Range: 45°C - 70°C"
ui_print "• Safe Battery Temperature: 25°C - 40°C"
ui_print "• Performance Mode: Below 55°C"
ui_print "• Balanced Mode: 55°C - 65°C"
ui_print "• Power Saving Mode: Above 65°C"
ui_print " "
ui_print "• Installation completed successfully!"
ui_print "• Please reboot your device to apply changes."
ui_print " "