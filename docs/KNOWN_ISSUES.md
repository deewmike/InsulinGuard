# Known Issues and Development Priorities

[← README](../README.md) · [BLE protocol](BLE_PROTOCOL.md) · [Development](DEVELOPMENT.md)

This page tracks technical work needed to improve reliability, portability, and security. InsulinGuard is a research prototype, not a clinically validated medical product.

## BLE and protocol

| Priority | Issue | Recommended action |
| --- | --- | --- |
| High | `sendCommandWithAck()` can retry indefinitely when an application-level ACK never arrives | Add bounded retries, cancellation, and explicit error states |
| High | A response can complete the ACK wait before its payload CRC is validated | Validate the response and correlate it with the command before accepting the ACK |
| High | Sample lengths are checked using `% 5` before `% 7`, creating ambiguous parsing for buffers such as 35 bytes | Use the active measurement mode and explicit framing information |
| High | Command `0x02` has an empty payload in the UI, while the Python simulator expects a frequency byte | Align the client command format with the peripheral firmware |
| Medium | Sample parsing assumes complete samples in a notification | Add buffering for partial sample delivery |
| Medium | Missing sequence numbers are not independently detected | Track sequence numbers and request missing samples |
| Medium | Notification and scan subscriptions are not consistently cancelled | Manage subscriptions throughout connect/disconnect and widget lifecycle |
| Medium | The simulator's single-frequency retransmission path uses a variable with inconsistent scope | Correct the packet cache and test selective NACK handling |

See [BLE protocol](BLE_PROTOCOL.md) for packet layouts, CRC parameters, and a suggested test matrix.

## Patch measurements

The research specification and Dart implementation differ in several areas:

- **Monitoring schedule:** the planned 48-hour cycle includes a faster sampling window from **−20 to +40 minutes** around each administration. Full device-side scheduling and synchronization remain to be integrated.
- **Sweep configuration:** the thesis describes an initial frequency and logarithmically spaced intervals; `sendSweepCommand()` sends spectrum and frequency counts only.
- **ACK/NACK grouping:** the academic model describes grouped transfers and selective retransmission, whereas the application acknowledges received notification buffers.
- **Statistics:** the design includes standard-deviation checks for real and imaginary impedance; the current UI evaluates standard deviation for the real component only.

Measurement thresholds and patch-validation rules must be reviewed against the intended hardware and research methodology before relying on them.

## App, data, and platform

| Priority | Issue | Recommended action |
| --- | --- | --- |
| High | Staff access uses a default `0000` PIN stored in `shared_preferences` | Use suitable authentication and protect personal data |
| High | `ios/Runner/Info.plist` lacks `NSBluetoothAlwaysUsageDescription`; local notifications initialize for Android only | Configure and test Bluetooth and notification permissions on iOS |
| High | Android manifest declares `NotificationBootReceiver` and `NotificationForegroundService` | Ensure their native implementations exist and test background/reboot behavior |
| High | Android release configuration uses debug signing | Configure release signing before distribution |
| Medium | `DatabaseHelper` has no `meal` column, although some application code references that field | Align the schema and callers; define migrations |
| Medium | Diary date/time formats differ between input and parsing paths | Normalize stored date/time values and add locale tests |
| Medium | Protocol handlers can navigate with `BuildContext`, and `HomePage` creates a separate `AppState` instance in one widget | Decouple navigation from BLE handling and use shared state consistently |
| Medium | `pubspec.yaml` still uses generic project identifiers (`app`, `com.example.app`) | Set the intended application and package names when preparing a release |
| Low | `flutter_reactive_ble` and `permission_handler` lack explicit dependency constraints | Pin supported versions and retain `pubspec.lock` |
| Low | `test/widget_test.dart` is Flutter's default template; no CI configuration is included | Add feature/protocol tests and a CI workflow |

## Recommended test coverage

1. **BLE:** scan permissions, connect/reconnect, characteristic discovery, ACK/NACK, malformed CRCs, dropped samples, and MTU variations.
2. **Measurements:** battery checks, measurement start/stop, sweep completion, patch failure states, and timeouts.
3. **UI and storage:** administration CRUD, date/time parsing, reminders, staff access, state updates, and navigation.
4. **Platforms:** Android permissions and notification behavior; iOS Bluetooth/notification setup on physical hardware.
5. **Release:** signing, privacy and permission review, automated tests, and a consistent application identity.
