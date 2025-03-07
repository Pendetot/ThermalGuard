# Installation Guide for Thermal Guardian Pro v2.0

## Pre-Installation Steps

1. **Backup your data**: Always backup important data before installing any system modification
2. **Ensure Magisk is installed**: This module requires Magisk v20.4 or newer
3. **Check battery level**: Make sure your battery is at least 50% charged
4. **Close all background apps**: To ensure a smooth installation

## Installation Methods

### Method 1: Via Magisk Manager (Recommended)

1. Open Magisk Manager
2. Tap on the Menu icon (≡) → Modules
3. Tap on "Install from storage" button at the bottom
4. Navigate to the downloaded zip file and select it
5. Tap "INSTALL"
6. Once installation is complete, tap "REBOOT"

### Method 2: Via Recovery

1. Download the module zip file
2. Reboot to recovery mode
3. Select "Install" or "Install zip"
4. Navigate to the downloaded zip file and select it
5. Swipe to confirm flash
6. Reboot system

## Post-Installation

After rebooting, the module will automatically configure itself based on your device. No additional setup is required for basic functionality.

### Verifying Installation

To verify that the module is working correctly:

1. Open Terminal Emulator app or Termux
2. Run the following command:
   ```
   su -c "cat /data/local/tmp/thermal_logs/thermal_guardian.log"
   ```
3. You should see log entries showing the module is monitoring your device's temperature

### Optional: Gaming Mode Setup

To set up easy access to Gaming Mode:

1. Create a Shortcut with Termux:
   ```
   termux-shortcut -n "Gaming Mode ON" -c "su -c 'sh /data/adb/modules/thermalguardianpro/gaming.sh start'"
   termux-shortcut -n "Gaming Mode OFF" -c "su -c 'sh /data/adb/modules/thermalguardianpro/gaming.sh stop'"
   ```

2. Or use automation apps like Tasker to create shortcuts

## Troubleshooting

If you encounter any issues after installation:

1. **Device overheating**: Check logs to verify the module is running
   ```
   su -c "cat /data/local/tmp/thermal_logs/thermal_guardian.log | tail -n 50"
   ```

2. **Performance issues**: Try toggling gaming mode on and off
   ```
   su -c "sh /data/adb/modules/thermalguardianpro/gaming.sh start"
   ```
   
   Wait a few minutes, then turn it off:
   ```
   su -c "sh /data/adb/modules/thermalguardianpro/gaming.sh stop"
   ```

3. **Module not working**: Try disabling and re-enabling the module in Magisk Manager

4. **HyperOS specific issues**: Check if the ROM is properly detected
   ```
   su -c "grep 'ROM detected' /data/local/tmp/thermal_logs/thermal_guardian.log"
   ```

## Uninstallation

If you need to uninstall the module:

1. Open Magisk Manager
2. Go to Modules
3. Find Thermal Guardian Pro and tap the Uninstall button
4. Reboot your device

Alternatively, you can use the included uninstall script:
```
su -c "sh /data/adb/modules/thermalguardianpro/uninstall.sh"
```

## Support

If you need assistance, please visit:
- Telegram: https://t.me/thermalguardian
- GitHub Issues: https://github.com/lazydev/thermalguardian/issues