import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart'; // Per VoidCallback



class BLECommandSender {
  static const int ACK_BYTE = 0x55;
  static const int NACK_BYTE = 0xAA;
  static const int STOP_COMMAND_BYTE = 0xFF; // Usa il valore che preferisci

  final FlutterReactiveBle ble;
  final QualifiedCharacteristic commandCharacteristic;
  final Map<int, void Function(Uint8List)> _responseCallbacks = {};

  Completer<bool>? _ackCompleter;
  bool inModalitaSweep = false;


  BLECommandSender({
    required this.ble,
    required this.commandCharacteristic,
  });

  Future<void> updateBattery({
    required void Function(int) onBatteryLevelUpdated,
    required VoidCallback notifyListeners,
  }) async {
    await sendCommandWithAck(
      commandId: 0x00,
      payload: Uint8List(0),
      onResponse: (Uint8List data) {
        if (data.isNotEmpty) {
          int batteryLevel = data[0];
          print("🔋 Batteria aggiornata: $batteryLevel%");
          onBatteryLevelUpdated(batteryLevel);
          notifyListeners();
        } else {
          print("⚠️ Nessun dato batteria ricevuto");
        }
      },
    );
  }

  /// Invio comando con ACK obbligatorio, ritrasmette su NACK o timeout
  Future<bool> sendCommandWithAck({
    required int commandId,
    required Uint8List payload,
    Duration timeoutDuration = const Duration(seconds: 2),
    void Function(Uint8List)? onResponse,
  }) async {
    print("\u{1F4E4} Invio comando $commandId con ritrasmissione su NACK/timeout");

    List<int> fullPayload = [commandId, ...payload];
    int crc = calculateCrc16(fullPayload);
    List<int> packet = [...fullPayload, (crc >> 8) & 0xFF, crc & 0xFF];

    if (onResponse != null) {
      _responseCallbacks[commandId] = onResponse;
    }

    while (true) {
      if (ble != null && commandCharacteristic != null) {
        await ble!.writeCharacteristicWithResponse(
          commandCharacteristic!,
          value: Uint8List.fromList(packet),
        );
      }

      print("\u{1F4E8} Comando inviato, in attesa di ACK...");

      bool ackReceived = await _waitForAck(timeoutDuration);

      if (ackReceived) {
        print("\u{2705} ACK ricevuto per comando $commandId");
        return true;
      } else {
        print("\u{26A0}\uFE0F NACK o timeout – ritrasmetto comando $commandId");
      }
    }
  }


  Future<bool> _waitForAck(Duration timeout) async {
    _ackCompleter = Completer<bool>();

    Future.delayed(timeout, () {
      if (!_ackCompleter!.isCompleted) {
        _ackCompleter!.complete(false);  // Timeout
      }
    });

    return _ackCompleter!.future;
  }

  void completeAck({bool success = true}) {
    print("🔁 completeAck() chiamato con success=$success");
    if (_ackCompleter != null && !_ackCompleter!.isCompleted) {
      _ackCompleter!.complete(success);
    } else {
      print("⚠️ completeAck() chiamato ma completer già risolto!");
    }
  }

  Future<void> sendAckWithCRC() async {
    List<int> ackPayload = [ACK_BYTE];
    int crc = calculateCrc16(Uint8List.fromList(ackPayload));
    ackPayload.add((crc >> 8) & 0xFF);
    ackPayload.add(crc & 0xFF);

    await ble.writeCharacteristicWithResponse(
      commandCharacteristic,
      value: Uint8List.fromList(ackPayload),
    );
    print("✅ ACK cumulativo inviato con CRC: $crc");
  }

  // Nuova funzione: invio NACK con CRC e lista errori
  Future<void> sendNackWithCRC(List<int> errors) async {
    List<int> nackPayload = [NACK_BYTE, ...errors];
    int crc = calculateCrc16(Uint8List.fromList(nackPayload));
    nackPayload.add((crc >> 8) & 0xFF);
    nackPayload.add(crc & 0xFF);

    await ble.writeCharacteristicWithResponse(
      commandCharacteristic,
      value: Uint8List.fromList(nackPayload),
    );
    print("❌ NACK inviato per pacchetti: $errors con CRC: $crc");
  }

  Future<bool> sendSweepCommand({
    required int numSpettri,
    required int numFrequenze,
    void Function(Uint8List)? onResponse,
  }) async {
    const int comandoSweep = 0x03;
    Uint8List payload = Uint8List.fromList([numSpettri, numFrequenze]);

    print("📡 Invio comando sweep con $numSpettri spettri e $numFrequenze frequenze...");

    bool success = await sendCommandWithAck(
      commandId: comandoSweep,
      payload: payload,
      onResponse: (Uint8List data) {
        print("✅ ACK ricevuto per sweep con payload: $data");
        if (onResponse != null) onResponse(data);
      },
    );

    if (!success) {
      print("❌ Errore invio comando sweep.");
    }

    return success;
  }

  Future<void> sendStopCommand() async {
    int crc = calculateCrc16([STOP_COMMAND_BYTE]);
    await ble.writeCharacteristicWithResponse(
      commandCharacteristic,
      value: [STOP_COMMAND_BYTE, (crc >> 8) & 0xFF, crc & 0xFF],
    );
    print("🛑 Comando di stop inviato.");

  }

  void handleResponse(int commandId, Uint8List data) {
    if (_responseCallbacks.containsKey(commandId)) {
      _responseCallbacks[commandId]!(data);
      _responseCallbacks.remove(commandId);
    } else {
      print("⚠️ Nessun callback registrato per comando $commandId");
    }
  }


  int calculateCrc16(List<int> data) {
    int crc = 0xFFFF;
    for (int b in data) {
      crc ^= (b << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc;
  }

}