import 'package:flutter/material.dart';
import 'package:app/core/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:app/core/notification_service.dart';
import 'package:app/core/permission_handler_service.dart';

class AddSomministrazionePage extends StatefulWidget {
  @override
  _AddSomministrazionePageState createState() => _AddSomministrazionePageState();
}

class _AddSomministrazionePageState extends State<AddSomministrazionePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final TextEditingController dosageController = TextEditingController();
  String selectedMeal = "Colazione";
  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime selectedDate = DateTime.now();

  void _saveSomministrazione() async {
    await PermissionHandlerService.requestAllPermissions(context); // Assicura che i permessi siano concessi

    if (dosageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inserisci una dose valida!")),
      );
      return;
    }

    String formattedTime = selectedTime.format(context);
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    await dbHelper.insertSomministrazione(
      formattedDate,
      formattedTime,
      selectedMeal,
      dosageController.text,
      "",
    );

    final now = DateTime.now().toLocal();
    final scheduledTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    ).toLocal();

    /*if (scheduledTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("L'orario selezionato è già passato. La notifica verrà mostrata subito.")),
      );
    }
    */

    final reminderTime = scheduledTime.subtract(Duration(minutes: 1)); // Notifica 1 minuti prima
    final notificationId = int.parse(DateFormat('yyyyMMddHHmm').format(scheduledTime))% 1000000000;


    if (reminderTime.isAfter(now)) {
      NotificationService.showScheduledNotification(
        id: notificationId,
        title: "Promemoria Insulina",
        body: "È quasi ora della tua prossima somministrazione di insulina!",
        scheduledTime: reminderTime,
      );
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Notifica pianificata con successo!")),
      );*/
    } else {
      NotificationService.showScheduledNotification(
        id: notificationId,
        title: "Promemoria Insulina",
        body: "Non dimenticare la tua insulina!",
        scheduledTime: now.add(Duration(seconds: 1)), // Notifica immediata
      );
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("L'orario di notifica è già passato. Nessuna notifica impostata.")),
      );*/
    }

    Navigator.pop(context, true);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Aggiungi Somministrazione",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Data",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('yyyy-MM-dd').format(selectedDate),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Orario",
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  controller: TextEditingController(
                    text: selectedTime.format(context),
                  ),
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              value: selectedMeal,
              items: ["Colazione", "Pranzo", "Cena", "Spuntino"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedMeal = newValue!;
                });
              },
              decoration: InputDecoration(labelText: "Nome Pasto"),
            ),
            TextField(
              controller: dosageController,
              decoration: InputDecoration(labelText: "UI Insulina"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Annulla"),
                ),
                ElevatedButton(
                  onPressed: _saveSomministrazione,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text("OK"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
