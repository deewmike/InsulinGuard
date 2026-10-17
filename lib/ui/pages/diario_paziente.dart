import 'package:app/ui/pages/add_somministrazione_page.dart';
import 'package:app/ui/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/core/database_helper.dart';
import 'package:app/core/permission_handler_service.dart';
import 'package:app/core/notification_service.dart';
import 'package:app/ui/widgets/bottom_navigation_bar.dart';



class DiarioPazientePage extends StatefulWidget {
  @override
  _DiarioPazientePageState createState() => _DiarioPazientePageState();
}

class _DiarioPazientePageState extends State<DiarioPazientePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Selezione della data per le somministrazioni
  DateTime selectedDate = DateTime.now();

  // --- Mattina ---
  TimeOfDay morningTime = TimeOfDay(hour: 8, minute: 0);
  final TextEditingController morningDosageController = TextEditingController();
  String morningInsulinType = "Rapida";
  final TextEditingController morningInsulinTypeController = TextEditingController();

  // --- Pomeriggio ---
  TimeOfDay afternoonTime = TimeOfDay(hour: 13, minute: 0);
  final TextEditingController afternoonDosageController = TextEditingController();
  String afternoonInsulinType = "Rapida";
  final TextEditingController afternoonInsulinTypeController = TextEditingController();

  // --- Sera ---
  TimeOfDay eveningTime = TimeOfDay(hour: 19, minute: 0);
  final TextEditingController eveningDosageController = TextEditingController();
  String eveningInsulinType = "Rapida";
  final TextEditingController eveningInsulinTypeController = TextEditingController();

  // Lista delle opzioni per il tipo di insulina
  final List<String> insulinTypes = ["Rapida", "Basale", "Mista", "Altro"];

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

  Future<void> _selectTime(BuildContext context, String window) async {
    TimeOfDay initial;
    if (window == "morning") {
      initial = morningTime;
    } else if (window == "afternoon") {
      initial = afternoonTime;
    } else {
      initial = eveningTime;
    }
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (window == "morning") {
          morningTime = picked;
        } else if (window == "afternoon") {
          afternoonTime = picked;
        } else {
          eveningTime = picked;
        }
      });
    }
  }

  Widget _buildTimeRow(
      String label,
      String window,
      TimeOfDay time,
      TextEditingController dosageController,
      String selectedInsulinType,
      Function(String?) onInsulinChanged,
      TextEditingController insulinTypeController,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(context, window),
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Orario",
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    controller: TextEditingController(text: time.format(context)),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: dosageController,
                decoration: InputDecoration(labelText: "UI Insulina"),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: selectedInsulinType,
          items: insulinTypes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onInsulinChanged,
          decoration: InputDecoration(labelText: "Tipo di Insulina"),
        ),
        if (selectedInsulinType == "Altro")
          TextField(
            controller: insulinTypeController,
            decoration: InputDecoration(labelText: "Inserisci il tipo di insulina"),
          ),
        Divider(),
      ],
    );
  }

  void _saveSomministrazioni() async {
    await PermissionHandlerService.requestAllPermissions(context);

    // Controllo che per ogni finestra il dosaggio sia compilato
    if (morningDosageController.text.isEmpty ||
        afternoonDosageController.text.isEmpty ||
        eveningDosageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inserisci le dosi per tutte le finestre!")),
      );
      return;
    }

    // Se l'utente ha scelto "Altro", controlla che il campo sia compilato
    if (morningInsulinType == "Altro" && morningInsulinTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inserisci il tipo di insulina per la finestra Mattina!")),
      );
      return;
    }
    if (afternoonInsulinType == "Altro" && afternoonInsulinTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inserisci il tipo di insulina per la finestra Pomeriggio!")),
      );
      return;
    }
    if (eveningInsulinType == "Altro" && eveningInsulinTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inserisci il tipo di insulina per la finestra Sera!")),
      );
      return;
    }

    // Determina il tipo di insulina per ciascuna finestra
    String morningInsulin = morningInsulinType == "Altro"
        ? morningInsulinTypeController.text
        : morningInsulinType;
    String afternoonInsulin = afternoonInsulinType == "Altro"
        ? afternoonInsulinTypeController.text
        : afternoonInsulinType;
    String eveningInsulin = eveningInsulinType == "Altro"
        ? eveningInsulinTypeController.text
        : eveningInsulinType;

    // Formatta la data
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Formatta gli orari
    String morningTimeStr = morningTime.format(context);
    String afternoonTimeStr = afternoonTime.format(context);
    String eveningTimeStr = eveningTime.format(context);

    // Inserisce tre record nel database; il campo "meal" viene passato come stringa vuota
    await dbHelper.insertSomministrazione(
        formattedDate, morningTimeStr, "", morningDosageController.text, morningInsulin);
    await dbHelper.insertSomministrazione(
        formattedDate, afternoonTimeStr, "", afternoonDosageController.text, afternoonInsulin);
    await dbHelper.insertSomministrazione(
        formattedDate, eveningTimeStr, "", eveningDosageController.text, eveningInsulin);

    // Pianifica le notifiche per ogni finestra (1 minuto prima)
    DateTime morningScheduled = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      morningTime.hour,
      morningTime.minute,
    );
    DateTime afternoonScheduled = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      afternoonTime.hour,
      afternoonTime.minute,
    );
    DateTime eveningScheduled = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      eveningTime.hour,
      eveningTime.minute,
    );

    DateTime morningReminder = morningScheduled.subtract(Duration(minutes: 1));
    DateTime afternoonReminder = afternoonScheduled.subtract(Duration(minutes: 1));
    DateTime eveningReminder = eveningScheduled.subtract(Duration(minutes: 1));

    DateTime now = DateTime.now().toLocal();

    int morningNotifId = int.parse(DateFormat('yyyyMMddHHmm').format(morningScheduled)) % 1000000000;
    int afternoonNotifId = int.parse(DateFormat('yyyyMMddHHmm').format(afternoonScheduled)) % 1000000000;
    int eveningNotifId = int.parse(DateFormat('yyyyMMddHHmm').format(eveningScheduled)) % 1000000000;

    if (morningReminder.isAfter(now)) {
      NotificationService.showScheduledNotification(
        id: morningNotifId,
        title: "Promemoria Insulina - Mattina",
        body: "È quasi ora della tua somministrazione mattutina!",
        scheduledTime: morningReminder,
      );
    }
    if (afternoonReminder.isAfter(now)) {
      NotificationService.showScheduledNotification(
        id: afternoonNotifId,
        title: "Promemoria Insulina - Pomeriggio",
        body: "È quasi ora della tua somministrazione pomeridiana!",
        scheduledTime: afternoonReminder,
      );
    }
    if (eveningReminder.isAfter(now)) {
      NotificationService.showScheduledNotification(
        id: eveningNotifId,
        title: "Promemoria Insulina - Sera",
        body: "È quasi ora della tua somministrazione serale!",
        scheduledTime: eveningReminder,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Somministrazioni salvate con successo!")),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Diario Paziente"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Selezione della data
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
              SizedBox(height: 20),
              // Finestre di somministrazione
              _buildTimeRow(
                "Mattina",
                "morning",
                morningTime,
                morningDosageController,
                morningInsulinType,
                    (val) {
                  setState(() {
                    morningInsulinType = val!;
                  });
                },
                morningInsulinTypeController,
              ),
              _buildTimeRow(
                "Pomeriggio",
                "afternoon",
                afternoonTime,
                afternoonDosageController,
                afternoonInsulinType,
                    (val) {
                  setState(() {
                    afternoonInsulinType = val!;
                  });
                },
                afternoonInsulinTypeController,
              ),
              _buildTimeRow(
                "Sera",
                "evening",
                eveningTime,
                eveningDosageController,
                eveningInsulinType,
                    (val) {
                  setState(() {
                    eveningInsulinType = val!;
                  });
                },
                eveningInsulinTypeController,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveSomministrazioni();  // Salva i dati

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => CustomBottomNav(currentIndex: 0)),
                        (route) => false, // Rimuove tutte le pagine precedenti
                  );

                },
                child: Text("Salva Somministrazioni"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }
}
