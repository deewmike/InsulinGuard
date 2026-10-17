# Development, Local Setup, and Testing

[← README](../README.md) · [BLE protocol](BLE_PROTOCOL.md) · [Known issues](KNOWN_ISSUES.md)

## Requirements and first run

| Area | Requirement |
| --- | --- |
| Flutter/Dart | Dart `^3.6.2` (see `pubspec.yaml`); use a Flutter version compatible with `pubspec.lock`. |
| Android | Android SDK, Android Studio, and **JDK 17**. |
| iOS | macOS, Xcode, and CocoaPods. Add the necessary Bluetooth and notification permissions before running on iOS. |
| Dependencies | Keep `pubspec.lock`: it resolves `flutter_reactive_ble 5.4.0`, `provider 6.1.2`, `sqflite 2.4.1`, `flutter_local_notifications 17.2.4`, and `permission_handler 11.3.1`. Other versions are listed in the [README technology stack](../README.md#technology-stack). |
| BLE | A compatible peripheral or a host supporting BLE peripheral advertising for simulator-based tests. |

```bash
cd appInsulin
flutter --version
flutter doctor -v
flutter pub get
flutter devices
flutter run -d <device-id>

# Static analysis, tests, and debug build
flutter analyze
flutter test
flutter build apk --debug
```

The included `test/widget_test.dart` is a Flutter template. Add tests for application screens and protocol behavior. Keep `pubspec.lock` under version control to preserve dependency versions.

## Android: permissions and configuration

Source: `android/app/src/main/AndroidManifest.xml`.

| Area | Manifest declarations | Platform considerations |
| --- | --- | --- |
| BLE | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`; `BLUETOOTH`, `BLUETOOTH_ADMIN` through SDK 30; optional `android.hardware.bluetooth_le` feature | Android 12+ runtime requests, denied permissions, missing/disabled Bluetooth adapter |
| Location | `ACCESS_FINE_LOCATION` through SDK 30, `ACCESS_COARSE_LOCATION` through SDK 28, `ACCESS_BACKGROUND_LOCATION` | Justify/restrict background access; check policies and legacy behavior |
| Notifications | `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE` | Runtime/special access, schedule accuracy, and restore-after-reboot tests |
| Native components | `.core.NotificationBootReceiver`, `.core.NotificationForegroundService` with `mediaProjection` service type | Ensure the receiver and service classes exist, use the appropriate service type, and work correctly after device restart |

The manifest contains Firebase notification-channel metadata, although the Dart dependencies do not include a Firebase messaging client. The Android Gradle `release` block currently uses `signingConfigs.debug`; configure separate release signing before distribution. Test at least an older Android version, Android 12+, and Android 13+ notifications, including manifest merging and Bluetooth behavior.

## iOS configuration

Add a Bluetooth usage description to `ios/Runner/Info.plist`: 

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is used to connect to the associated monitoring device.</string>
```

`NotificationService.initialize()` currently configures `AndroidInitializationSettings`. Add iOS notification initialization and permissions, then test BLE and notifications on a physical iPhone.

## BLE simulator

A separate Python `ble_simulator.py` script uses `bless` to advertise `insulin_sim` with the project's service and characteristic UUIDs. Place the simulator script in the test directory before running:

```bash
python -m venv .venv
# Linux/macOS: source .venv/bin/activate
# Windows PowerShell: .venv\Scripts\Activate.ps1
python -m pip install bless
python ble_simulator.py
```

Before integration testing, align command `0x02`, sample framing, ACK/NACK, and retransmission handling with the [BLE protocol](BLE_PROTOCOL.md).

## Test checklist

Record the device/OS version, Flutter/Dart version, negotiated MTU, command bytes, CRC results, and any timeouts, without recording real patient information. Test device discovery, battery queries, measurement start/stop, sweeps, NACK handling, disconnection, notification scheduling, and staff access. See the [protocol test matrix](BLE_PROTOCOL.md#8-protocol-test-matrix) and [Known issues](KNOWN_ISSUES.md).

Before distributing an application build, review release signing, data protection, device compatibility, and functional tests. Clinical or therapeutic use requires separate safety and regulatory evaluation.
