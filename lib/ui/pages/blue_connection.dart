import 'package:app/core/ble_connection.dart';
import 'package:app/core/ble_handler.dart';
import 'package:app/core/data_manager.dart';
import 'package:app/ui/pages/battery_confermation_page.dart';
import 'package:app/ui/pages/battery_low_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:typed_data';
import 'package:app/ui/widgets/BLEstatusBanner.dart';
import 'package:app/core/ble_connection.dart';
import 'package:app/core/ble_commandSender.dart';

class BLEScanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bleConnection = Provider.of<BLEConnectionController>(context);
    final deviceManager = DeviceDataManager();

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Connessione")),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          BLEStatusBanner(),  // 👈 Banner connessione BLE

          Expanded(  // 👈 Questo espande il contenuto scrollabile
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.blue, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 5.0, spreadRadius: 2.0),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "Seleziona dispositivo per la connessione",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // ✅ Lista dispositivi con altezza flessibile
                    Expanded(
                      child: Consumer<BLEConnectionController>(
                        builder: (context, bleConnection, child) {
                          if (bleConnection.devices.isEmpty) {
                            return const Center(
                              child: Text("Nessun dispositivo trovato", style: TextStyle(color: Colors.grey)),
                            );
                          }
                          return ListView.builder(
                            itemCount: bleConnection.devices.length,
                            itemBuilder: (context, index) {
                              final device = bleConnection.devices[index];
                              return deviceButton(
                                device.id.isNotEmpty ? "${device.name} ${device.id}" : "Unknown Device",
                                device,
                                bleConnection,
                                context,
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔍 Pulsante Scan
                    ElevatedButton(
                      onPressed: bleConnection.startScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      child: Text(bleConnection.isScanning ? "Scanning..." : "Scan"),
                    ),

                    const SizedBox(height: 16),

                    // 🔋 Pulsante Continua (controlla batteria)
                    ElevatedButton(
                      onPressed: () async {
                        final bleController = Provider.of<BLEController>(context, listen: false);

                        await bleController.updateBattery();  // 🔋 aggiorna valore batteria

                        final batteryLevel = bleController.batteryLevel;

                        if (batteryLevel != null) {
                          print("🔋 Batteria aggiornata: $batteryLevel%");

                          if (batteryLevel > 50) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BatteryConfirmationPage()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BatteryLowPage()),
                            );
                          }
                        } else {
                          print("⚠️ Nessun valore di batteria disponibile");
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        minimumSize: const Size(200, 50),
                      ),
                      child: const Text("Continua", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }

  Widget deviceButton(String deviceName, DiscoveredDevice device, BLEConnectionController bleConnection, BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(deviceName),
        trailing: const Icon(Icons.bluetooth),
        onTap: () {
          // Passa anche il context alla funzione di connessione
          bleConnection.connectToDevice(device.id, context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🔄 Connessione al dispositivo...")),
          );
        },
      ),
    );
  }


  /// Pulsante per selezionare il tipo di connessione (Bluetooth / USB)
  Widget connectionButton(String type) {
    return ElevatedButton(
      onPressed: () {
        // Qui puoi gestire il cambio di tipo di connessione
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(120, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type == "Bluetooth" ? Icons.bluetooth : Icons.usb, size: 30),
          const SizedBox(height: 5),
          Text(type, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

}
