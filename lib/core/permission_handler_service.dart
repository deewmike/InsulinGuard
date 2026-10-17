import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  // 📌 Controlla se le notifiche sono abilitate
  static Future<bool> _isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  // 📌 Controlla se il permesso di allarme esatto è attivo (necessario per notifiche precise su Android 12+)
  static Future<bool> _isExactAlarmPermissionGranted() async {
    return await Permission.scheduleExactAlarm.isGranted;
  }

  // 📌 Richiede i permessi e mostra un alert se negati
  static Future<void> requestAllPermissions(BuildContext context) async {
    bool notificationGranted = await _isNotificationPermissionGranted();
    bool exactAlarmGranted = await _isExactAlarmPermissionGranted();

    if (!notificationGranted) {
      await Permission.notification.request();
      notificationGranted = await _isNotificationPermissionGranted();
    }

    if (!exactAlarmGranted) {
      await Permission.scheduleExactAlarm.request();
      exactAlarmGranted = await _isExactAlarmPermissionGranted();
    }

    // 🔥 Se l'utente ha rifiutato i permessi, mostriamo un messaggio
    if (!notificationGranted || !exactAlarmGranted) {
      _showPermissionDialog(context);
    }
  }

  // 📌 Mostra un avviso se i permessi sono stati negati
  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Permessi Necessari"),
          content: Text(
              "L'app ha bisogno dei permessi di notifica per funzionare correttamente.\n"
                  "Per favore, concedi i permessi dalle impostazioni."),
          actions: [
            TextButton(
              child: Text("Apri Impostazioni"),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Annulla"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
