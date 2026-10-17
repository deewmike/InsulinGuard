# Contributing to InsulinGuard

InsulinGuard welcomes improvements to the Flutter interface, BLE communication, testing, and documentation.

## Proposing a change

1. Open an issue describing the problem, its impact, reproduction steps, and affected files.
2. Submit a pull request scoped to the issue. Update the README or `/docs` whenever behavior or interfaces change.
3. Include results from `flutter analyze`, `flutter test`, and relevant device/OS checks. Add or update tests when changing application behavior.

## Pull request checklist

- [ ] **BLE:** provide example bytes/CRC values, simulator/firmware compatibility notes, and appropriate ACK/NACK, timeout, and error tests.
- [ ] **UI:** cover loading states, denied permissions, disconnects, accessibility, and navigation.
- [ ] **Data:** plan SQLite migrations and tests for schema changes; exclude real health records, identifiers, and secrets from source, screenshots, and logs.
- [ ] **Lifecycle:** release subscriptions/controllers correctly and do not suppress errors without handling them.
- [ ] **Platforms:** claim Android/iOS compatibility only for environments actually tested.

See [Known issues](docs/KNOWN_ISSUES.md) for current technical priorities.
