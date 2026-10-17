import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'ble_handler.dart';

class BLEConnectionController extends ChangeNotifier {

  final FlutterReactiveBle _ble = FlutterReactiveBle();


  late BLEController _handler;
  BLEConnectionController();
  void injectBLEController(BLEController controller) {
    _handler = controller;

  }


  List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;
  DiscoveredDevice? _connectedDevice;

  QualifiedCharacteristic? _commandCharacteristic;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  final Uuid serviceUuid = Uuid.parse("26ddc6b7-8d50-41d5-a1e2-8b2e1d0636fb");
  final Uuid characteristicUuid = Uuid.parse("11235a37-444a-4389-bc22-edf0b0a3997f");

  List<DiscoveredDevice> get devices => _devices;
  bool get isScanning => _isScanning;
  DiscoveredDevice? get connectedDevice => _connectedDevice;

  // Riconnessione automatica
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 3;
  final Duration _reconnectDelay = Duration(seconds: 2);
  bool _userRequestedDisconnect = false;



  /// Richiede i permessi necessari per BLE
  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }


  /// Avvia la scansione dei dispositivi BLE con filtraggio
  void startScan() async {
    await requestPermissions();

    _devices.clear();
    _isScanning = true;
    notifyListeners();

    _ble.scanForDevices(withServices: []).listen((device) {
      if (device.name.toLowerCase().contains("insulin") ||
          device.serviceUuids.contains(serviceUuid) ||
          device.name.toLowerCase().contains("esp")) {
        if (!_devices.any((d) => d.id == device.id)) {
          _devices.add(device);
          notifyListeners();
        }
      }
    }).onDone(() {
      _isScanning = false;
      notifyListeners();
    });
  }
    /// Scopre i servizi e si iscrive alla caratteristica
    Future<void> discoverServices(String deviceId, BuildContext context) async {
      final services = await _ble.discoverServices(deviceId);
      final service = services.firstWhere((s) => s.serviceId == serviceUuid);
      final characteristic = service.characteristics.firstWhere((c) =>
      c.characteristicId == characteristicUuid);

      _commandCharacteristic = QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: characteristicUuid,
        deviceId: deviceId,
      );
      _handler.setBLE(_ble, _commandCharacteristic!);
      _ble.subscribeToCharacteristic(_commandCharacteristic!).listen((data) {
        _handler.handleIncomingData(data, context);
      });
    }

    /// Connessione con gestione riconnessione automatica
    void connectToDevice(String deviceId, BuildContext context) {
      _connectionSubscription?.cancel();
      print("Tentativo di connessione al dispositivo $deviceId...");

      _connectionSubscription = _ble.connectToDevice(id: deviceId).listen(
            (connectionState) async {
          switch (connectionState.connectionState) {
            case DeviceConnectionState.connected:
              print("Dispositivo connesso!");
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Dispositivo connesso!"))
              );
              _connectedDevice = _devices.firstWhere((d) => d.id == deviceId);
              _reconnectAttempts = 0;
              _userRequestedDisconnect = false;
              notifyListeners();

              // <-- Aumenta MTU qui!
              final mtu = await _ble.requestMtu(deviceId: deviceId, mtu: 100);
              print("📡 MTU aggiornato a $mtu");

              discoverServices(deviceId, context);
              break;

            case DeviceConnectionState.disconnected:
              print("Dispositivo disconnesso.");
              _connectedDevice = null;
              notifyListeners();
              if (!_userRequestedDisconnect) {
                if (_reconnectAttempts < _maxReconnectAttempts) {
                  _reconnectAttempts++;
                  print(
                      "Tentativo di riconnessione ($_reconnectAttempts/$_maxReconnectAttempts)...");
                  Future.delayed(_reconnectDelay, () =>
                      connectToDevice(deviceId, context));
                } else {
                  print(
                      "Raggiunto il numero massimo di tentativi di riconnessione.");
                }
              } else {
                print("Disconnessione esplicita: non riconnetto.");
              }
              break;

            default:
              break;
          }
        },
        onError: (error) {
          print("Errore nella connessione: $error");
        },
      );
    }

    /// Disconnette il dispositivo
    Future<void> disconnectDevice() async {
      _userRequestedDisconnect = true;
      _connectedDevice = null;
      _commandCharacteristic = null;
      await _connectionSubscription?.cancel();
      notifyListeners();
    }
}