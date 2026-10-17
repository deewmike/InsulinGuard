import 'package:flutter/material.dart';
import 'package:app/core/database_helper.dart';
import 'package:app/ui/pages/add_somministrazione_page.dart';
import 'package:intl/intl.dart';
import 'package:app/core/notification_service.dart';
import 'package:app/core/permission_handler_service.dart';
import 'package:app/core/app_state.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> somministrazioni = [];
  Map<String, dynamic>? nextSomministrazione;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionHandlerService.requestAllPermissions(context);
    });
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadSomministrazioni();
    await _loadNextSomministrazione();
  }

  Future<void> _loadSomministrazioni() async {
    final data = await dbHelper.getSomministrazioni();
    setState(() {
      somministrazioni = data;
    });
  }

  Future<void> _loadNextSomministrazione() async {
    final now = DateTime.now();
    // Filtra solo le somministrazioni non effettuate
    final data = somministrazioni.where((s) {
      if (s['isTaken'] == 1) return false;
      DateTime sTime = DateFormat('yyyy-MM-dd HH:mm').parse("${s['date']} ${s['time']}");
      return sTime.isAfter(now); // Filtra solo somministrazioni future
    }).toList();

    if (data.isNotEmpty) {
      data.sort((a, b) {
        DateTime aTime = DateFormat('yyyy-MM-dd HH:mm').parse("${a['date']} ${a['time']}");
        DateTime bTime = DateFormat('yyyy-MM-dd HH:mm').parse("${b['date']} ${b['time']}");
        return aTime.compareTo(bTime);
      });
      setState(() {
        nextSomministrazione = data.first;
      });
      _scheduleNextNotification();
    } else {
      setState(() {
        nextSomministrazione = null;
      });
    }
  }

  void _scheduleNextNotification() {
    if (nextSomministrazione != null) {
      DateTime sTime = DateFormat('yyyy-MM-dd HH:mm').parse(
          "${nextSomministrazione!['date']} ${nextSomministrazione!['time']}"
      );
      DateTime reminderTime = sTime.subtract(Duration(minutes: 1));
      int notificationId = int.parse(DateFormat('yyyyMMddHHmm').format(sTime)) % 1000000000;
      if (reminderTime.isAfter(DateTime.now())) {
        NotificationService.showScheduledNotification(
          id: nextSomministrazione!['id'],
          title: "Promemoria Insulina",
          body: "È quasi ora della tua prossima somministrazione di insulina!",
          scheduledTime: reminderTime,
        );
      }
    }
  }

  void _deleteSomministrazione(int id) async {
    await dbHelper.deleteSomministrazione(id);
    _loadData();
  }

  void _markAsTaken(int id) async {
    await dbHelper.markAsTaken(id);
    _loadData();
  }

  Widget _buildNotificationCard() {
    if (nextSomministrazione == null) {
      return Card(
        color: Colors.grey.shade300,
        child: ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Nessuna somministrazione prevista'),
        ),
      );
    }
    DateTime now = DateTime.now();
    DateTime scheduledTime = DateFormat('yyyy-MM-dd HH:mm').parse(
        "${nextSomministrazione!['date']} ${nextSomministrazione!['time']}"
    );
    Color cardColor = scheduledTime.isBefore(now) ? Colors.red.shade300 : Colors.amber.shade100;
    return Card(
      color: cardColor,
      child: ListTile(
        leading: Icon(Icons.notifications),
        title: Text(
            "Prossima somministrazione:\n${nextSomministrazione!['date']} ${nextSomministrazione!['time']}"
        ),
      ),
    );
  }

  Widget _buildPatchInsulinaCard() {
    return Card(
      color: Colors.lightGreen.shade100,
      child: ListTile(
        leading: Icon(Icons.medication_liquid),
        title: Text('Patch Insulina'),
        subtitle: Text(AppState().getExpirationDate() ?? 'Data non disponibile'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario Somministrazioni'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildNotificationCard(),
            SizedBox(height: 16),
            _buildPatchInsulinaCard(),
            SizedBox(height: 16),

            // Lista somministrazioni
            ...somministrazioni.map((s) {
              return Card(
                child: ListTile(
                  title: Text('${s['date']} ${s['time']}'),
                  subtitle: Text('${s['dosage']} UI'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      s['isTaken'] == 1
                          ? Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Somministrato', style: TextStyle(color: Colors.green)),
                        ],
                      )
                          : IconButton(
                        icon: Icon(Icons.check_circle_outline),
                        onPressed: () => _markAsTaken(s['id']),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSomministrazione(s['id']),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return AddSomministrazionePage();
                  },
                );
                if (result == true) {
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                textStyle: TextStyle(fontSize: 19),
              ),
              child: Text('Aggiungi Somministrazione', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),

    );
  }
}