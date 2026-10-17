# BLE Communication Protocol

[← README](../README.md) · [Architecture](ARCHITECTURE.md) · [Known issues](KNOWN_ISSUES.md)

The protocol is implemented by `ble_connection.dart`, `ble_handler.dart`, and `ble_commandSender.dart`. A separate Python BLE simulator is available for development and testing.

## 1. BLE/GATT

| Property | Value |
| --- | --- |
| Smartphone role | BLE Central / GATT client |
| Device role | BLE Peripheral / GATT server |
| Service UUID | `26ddc6b7-8d50-41d5-a1e2-8b2e1d0636fb` |
| Characteristic UUID | `11235a37-444a-4389-bc22-edf0b0a3997f` |
| Client write API | `writeCharacteristicWithResponse` |
| Client receive API | `subscribeToCharacteristic` |
| Requested MTU | `100` (requested, not guaranteed on every device) |
| Peripheral discovery | Scan without native service filters, then filter in Dart by a name containing `insulin` or `esp`, or a matching service UUID |

The Python simulator creates the same characteristic with `read`, `write`, and `notify` properties. The target peripheral must expose compatible GATT services, characteristics, and permissions.

## 2. CRC and encoding

`BLECommandSender.calculateCrc16()` computes a **16-bit CRC** using:

- Initial value: `0xFFFF`;
- Polynomial: `0x1021`;
- MSB-first processing with no explicit reflection;
- No final XOR;
- CRC bytes transmitted **high byte first, then low byte**.

For measurement samples, the CRC covers the sample bytes **excluding** the two trailing CRC bytes. For battery responses of the form `ACK + payload`, the parser checks the CRC of the `payload`, excluding the outer `ACK` byte. These parameters match the convention commonly called **CRC-16/CCITT-FALSE**, but implementations must use the explicit settings above rather than relying only on that name.

### Packet layouts

```text
Base command (client → peripheral):
+------------+-------------------------+--------+--------+
| command_id | payload (0..N bytes)    | CRC_hi | CRC_lo |
+------------+-------------------------+--------+--------+

Simple ACK (peripheral → client):
+------+
| 0x55 |
+------+

ACK with data, e.g. battery status (peripheral → client):
+------+------------+---------+--------+--------+
| 0x55 | command_id | battery | CRC_hi | CRC_lo |
+------+------------+---------+--------+--------+
       \__________CRC scope__________/

Single-frequency impedance sample (5 bytes):
+-----+--------+--------+--------+--------+
| seq | real_u8| imag_u8| CRC_hi | CRC_lo |
+-----+--------+--------+--------+--------+
 \____________CRC scope____________/

Sweep sample (7 bytes):
+-----+---------+---------+---------+---------+--------+--------+
| seq | real_lo | real_hi | imag_lo | imag_hi | CRC_hi | CRC_lo |
+-----+---------+---------+---------+---------+--------+--------+
 \___________________CRC scope______________________/
```

> A BLE notification can carry several consecutive samples. The current parser checks whether the received buffer length is divisible by 5 or 7. The protocol has **no frame header containing type/length/version** to unambiguously distinguish these sample types. The `inModSweep` flag affects processing, but the first branch still checks `% 5 == 0` during sweep acquisition.

### Sample decoding

- **Single frequency:** `seq` plus 8-bit `real` and `imag` values. The source computes their averages within the received notification chunk.
- **Sweep:** `seq` plus 16-bit little-endian `real` and `imag` values. The decoder converts unsigned values to signed by subtracting `65536` for values `>= 0x8000`. Parsed values are collected in `sweepDataReal` and `sweepDataImag`.
- The UI requests three spectra across 100 frequencies. The simulator uses representative data and hardcoded values in parts of its implementation.

## 3. Command IDs

| Hex | Descriptive name | Payload in Dart | Expected response/parsing |
| --- | --- | --- | --- |
| `0x00` | `SEND_BATTERY` | Empty | Simulator: `0x55, 0x00, level_u8, CRC16(0x00, level)` |
| `0x01` | `ANAGRAFIC_SEND` | `first_name + 0x00 + last_name + 0x00 + date` | ACK; encoded with Dart `codeUnits`, not explicitly UTF-8 |
| `0x02` | `START_SINGLE_FREQUENCY` | Empty | ACK, then 5-byte samples; however, the simulator reads `value[1]` as the frequency |
| `0x03` | `START_SWEEP` | `[spectrum_count_u8, frequency_count_u8]` | ACK, then 7-byte samples |
| `0xFF` | `STOP` | Empty | ACK; `sendStopCommand()` also provides a variant that does not await application-level ACK |
| `0xFE` | `MEASUREMENT_COMPLETE` | Incoming event (1 byte + CRC) | `BLEController` checks CRC and opens the confirmation screen |
| `0x55` | `ACK` | Simple or CRC-bearing form, depending on context | Completes `_ackCompleter` or advances sample handling |
| `0xAA` | `NACK` | Optional list of `seq` values + CRC | Requests selective retransmission |

The academic specification also describes initial-frequency and logarithmic-spacing parameters for a sweep. These fields are not included in the Dart `sendSweepCommand()` payload; firmware interoperability depends on agreement about the command format.

## 4. Command/ACK exchange

```mermaid
sequenceDiagram
  participant UI as Flutter UI
  participant S as BLECommandSender
  participant P as Peripheral
  participant H as BLEController
  UI->>S: sendCommandWithAck(id,payload)
  S->>S: CRC16(id + payload)
  S->>P: GATT Write With Response
  Note over S: Await application-level ACK (default 2 s)
  alt Application-level ACK
    P-->>H: notify 0x55 [payload] [CRC]
    H->>S: completeAck(true)
    S-->>UI: true
  else Application-level NACK or timeout
    P-->>H: notify 0xAA (if received)
    H->>S: completeAck(false)
    S->>P: Retry the same command
  end
```

`sendCommandWithAck()` contains an **unbounded `while (true)` retry loop**. If the device is unavailable or acknowledgments never arrive, an operation may remain pending indefinitely. `_waitForAck()` uses a `Completer` shared by that sender instance, so concurrent commands require particular care. Command handling should account for cancellation and a bounded retry policy.

## 5. Sample transfer and retransmission

### Model described in the theses

Lorenzo Bartoli's BLE thesis distinguishes per-packet ACK/NACK from group-based streaming: a **cumulative ACK** follows an error-free group, while a **selective NACK** carries the sequence numbers requiring retransmission. Michele Contino's frontend thesis refers to groups of ten samples and selective retransmission of corrupted samples. The two accounts are **not completely consistent about ACK timing**.

### Current application behavior

- `BLEController.handleIncomingData()` sends `sendAckWithCRC()` if all samples in the received notification buffer pass CRC validation; otherwise it calls `sendNackWithCRC(errors)`.
- It does not explicitly wait for ten samples before acknowledging. Actual grouping depends on notification boundaries.
- `verifyCRC()` returns CRC-failing sequence numbers, **not** a complete list of absent sequence numbers; missing sequence values are not detected separately.
- The Python simulator generates groups of ten single-frequency samples and pairs of sweep samples per notification, but it does not reproduce all thesis-specified timing and grouping behavior exactly.

Validate ACK/NACK timing against firmware using packet-loss tests and MTU-boundary cases.

## 6. Patch installation checks

The UI workflow requests battery status, starts single-frequency acquisition, checks impedance, sends STOP, and performs a sweep.

| Check | Application behavior | Value |
| --- | --- | --- |
| Battery | Level **> 50** is considered sufficient by `BLEScanScreen` | Hardcoded `50` in source (prototype threshold) |
| Impedance | Averages of real and imaginary values in the received chunk must both be `< 500` | `impedanceThreshold = 500` in `BLEController` |
| Impedance timeout | **5-second** timer in `avviaTimerVerificaImpedanza`, plus a **60-second** maximum wait in the screen | Flutter source |
| Sweep | UI requests `3` spectra × `100` frequencies, with a **50-second** maximum wait | `battery_confermation_page.dart` and controller |
| Monotonicity | Compares averages of consecutive windows of **10 samples** | `checkMonotonicity` |
| Standard deviation | Three spectra; default threshold **10**; the UI supplies **only the real component** | `checkStandardDeviation` and `checkSweepData` |

The implementation evaluates standard deviation for the real component only, while the academic design calls for both real and imaginary components. The implemented monotonicity check also differs from the original design.

## 7. Implementation considerations

1. **Ambiguous `% 5` / `% 7` branching:** a 35-byte buffer is divisible by both 5 and 7; branch order can prevent sweep samples from being appended correctly.
2. **Buffering:** the parser assumes that each notification contains complete samples; it does not retain a partial sample split across notifications.
3. **ACK accepted before payload CRC:** for payload-bearing ACK responses, the parser calls `completeAck()` before validating the CRC, potentially releasing the caller on malformed data.
4. **Single-frequency start:** the simulator expects a frequency byte, but the current UI sends an empty payload.
5. **Simulator retransmission:** `send_samples()` assigns `pacchetti_singola_frequenza` in a local variable, while the NACK path refers to the global variable; retransmission needs testing/fixing.
6. **Protocol versioning:** the current packet format does not include a version field.
7. **End-of-measurement event:** the client handles `0xFE`, but confirm the corresponding event emission in the peripheral firmware.
8. **Patient-details encoding:** Dart `String.codeUnits` and the simulator's UTF-8 decoding do not guarantee compatibility for non-ASCII characters.

See [Known issues](KNOWN_ISSUES.md) before hardware testing or distribution.

## 8. Protocol test matrix

| Scenario | Expected behavior |
| --- | --- |
| Valid battery response | ACK and CRC accepted; battery state updated |
| Invalid ACK CRC | Reject the response without confirming the command |
| NACK for one sweep sample | Retransmit the indicated sample |
| Missing sequence number | Detect and request missing data |
| Sample split across notifications | Reassemble the complete sample before parsing |
| Intentional / unintentional disconnect | Skip auto-reconnect for manual disconnect; otherwise retry within the configured limit |
| Concurrent commands | Match acknowledgments to the correct command |
| Android / iOS hardware | Consistent parsing of the same protocol data |

## 9. Firmware compatibility

When integrating a new peripheral firmware revision, compare its command schema, GATT properties, MTU, framing, encoding, ACK/NACK policy, sweep parameters, and `0xFE` completion event against this client implementation. Maintain byte-level compatibility tests for each supported revision.
