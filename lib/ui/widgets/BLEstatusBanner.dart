import 'package:app/core/ble_connection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/ble_handler.dart';

class BLEStatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bleController = Provider.of<BLEConnectionController>(context);

    final isConnected = bleController.connectedDevice != null;
    final deviceName = bleController.connectedDevice?.name ?? "Nessun dispositivo";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: isConnected ? Colors.green[400] : Colors.red[300],
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected
                  ? "Connesso a $deviceName"
                  : "Dispositivo non connesso",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
