import 'package:app/core/ble_connection.dart';
import 'package:app/core/ble_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/app_state.dart';
import 'package:app/ui/pages/medical_staff_page.dart';
import 'package:app/ui/pages/user_anag_page.dart';

class InsulinometerHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bleConnection = Provider.of<BLEConnectionController>(context);
    final bleController = Provider.of<BLEController>(context);
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Dispositivo',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
          // La view Home in stile Material, integrata in CupertinoTabView
            return CupertinoTabView(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text('Insulinometer'),
                  centerTitle: true,
                  backgroundColor: Colors.blue,
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDeviceStatusCard(bleConnection, bleController),
                      SizedBox(height: 12),
                      _buildPatientInfoCard(appState),
                      SizedBox(height: 32),
                      _buildActionButton(
                        'Staff Medico',
                        Colors.blue,
                        Colors.white,
                            () => _showPinDialog(context),
                      ),
                      SizedBox(height: 16),
                      _buildActionButton(
                        'Generalità',
                        Colors.green,
                        Colors.white,
                            () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.transparent,
                            builder: (context) => AddUserDetailsPage(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          case 1:
          // La view Dispositivo (puoi personalizzarla)
            return CupertinoTabView(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text('Dispositivo'),
                  centerTitle: true,
                  backgroundColor: Colors.blue,
                ),
                body: Center(child: Text('Contenuto Dispositivo')),
              ),
            );
          default:
            return Container();
        }
      },
    );
  }

  Widget _buildPatientInfoCard(AppState appState) {
    bool isRegistered = appState.nome.isNotEmpty && appState.cognome.isNotEmpty;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isRegistered ? Icons.person : Icons.error_outline,
              color: isRegistered ? Colors.blue : Colors.orangeAccent,
              size: 30,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                isRegistered
                    ? "Paziente: ${appState.nome} ${appState.cognome}"
                    : "⚠️ Registrare i dati anagrafici",
                style: TextStyle(
                  fontSize: 18,
                  color: isRegistered ? Colors.grey[700] : Colors.orangeAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinDialog(BuildContext context) {
    TextEditingController pinController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Enter PIN'),
          content: CupertinoTextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            placeholder: 'Enter 4-digit PIN',
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () {
                if (pinController.text == Provider.of<AppState>(context, listen: false).pin) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => MedicalStaffPage()),
                  );
                } else {
                  // Notifica l'errore con un dialog, poiché in Cupertino non esiste ScaffoldMessenger nativamente
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text('Error'),
                      content: Text('Incorrect PIN'),
                      actions: [
                        CupertinoDialogAction(
                          child: Text('OK'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceStatusCard(BLEConnectionController bleConnection, BLEController bleController) {
    bool isDeviceConnected = bleConnection.connectedDevice != null;
    String deviceName = bleConnection.connectedDevice?.name ?? "Nessun dispositivo";
    String batteryText = bleController.batteryLevel != null ? "${bleController.batteryLevel}%" : "--%";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Device", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                SizedBox(height: 4),
                Text(
                  isDeviceConnected ? deviceName : "Nessun dispositivo connesso",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDeviceConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Batteria", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isDeviceConnected ? Icons.battery_full : Icons.battery_unknown,
                      color: Colors.grey[700],
                    ),
                    SizedBox(width: 4),
                    Text(
                      batteryText,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        child: Text(text, style: TextStyle(fontSize: 18, color: textColor)),
      ),
    );
  }
}
