# 🔥❄️ Thermal Guardian Pro v2.0 ❄️🔥

## Advanced thermal management system for Android devices with HyperOS support

Thermal Guardian Pro is a Magisk module designed to intelligently manage your device's temperature without sacrificing performance. Unlike other thermal solutions that simply throttle your CPU, Thermal Guardian Pro uses an adaptive algorithm to find the perfect balance between cooling and performance.

## 🌟 Features

- **HyperOS Compatibility**: Full support for Xiaomi's HyperOS ROM
- **Advanced Thermal Algorithm**: Dynamically adjusts CPU/GPU frequencies based on real-time temperature
- **Auto-Detection**: Automatically detects your device's CPU architecture and SoC type
- **Battery Protection**: Special thermal protection while charging to extend battery lifespan
- **Performance Profiles**: Different performance modes based on temperature ranges
- **Gaming Mode**: Optional gaming profile for maximum performance during gaming sessions
- **Logging System**: Detailed logs for troubleshooting and performance monitoring
- **Universal Compatibility**: Works on Snapdragon, MediaTek, and other processors
- **No Performance Loss**: Maintains device performance while keeping temperatures in check

## 📋 Requirements

- Android 10 or higher
- Magisk 20.4 or newer
- Root access
- Compatible with most kernels

## 📑 Temperature Profiles

| Mode | Temperature Range | Description |
|------|-------------------|-------------|
| **Performance** | Below 55°C | Maximum performance with all cores at high frequency |
| **Balanced** | 55°C - 65°C | Moderate throttling to maintain stable temperatures |
| **Power Saving** | 65°C - 75°C | Stronger throttling to prevent overheating |
| **Emergency** | Above 75°C | Maximum throttling to protect hardware |

## 🎮 Gaming Mode

Thermal Guardian Pro includes a special gaming mode that can be activated when needed:

```bash
# Start gaming mode
su -c "sh /data/adb/modules/thermalguardianpro/gaming.sh start"

# Stop gaming mode when done
su -c "sh /data/adb/modules/thermalguardianpro/gaming.sh stop"

# Check status
su -c "sh /data/adb/modules/thermalguardianpro/gaming.sh status"
```

## 📊 Monitoring

You can check the thermal logs at any time:

```bash
su -c "cat /data/local/tmp/thermal_logs/thermal_guardian.log"
```

## 📝 Troubleshooting

If you encounter any issues:

1. Check logs at `/data/local/tmp/thermal_logs/`
2. Make sure your ROM is properly detected
3. Try rebooting your device
4. Report issues with full logs through the support channel

## 🔄 Updates

The module will check for updates automatically. You can also check manually through the Magisk Manager.

## 📱 Support

For support, bug reports, or feature requests, please join our Telegram group:
https://t.me/thermalguardian

## 📜 License

This module is provided as-is with no warranty. Use at your own risk.

## 🔧 Credits

- Original concept by LazyDev
- Enhanced by the community
- Special thanks to the Magisk team