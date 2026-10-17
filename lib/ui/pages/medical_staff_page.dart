import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/app_state.dart';
import 'package:app/ui/pages/patch_instruction_page.dart';
class MedicalStaffPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    appState.loadPin(); // Ricarica il PIN ogni volta che si accede alla pagina

    return Scaffold(
      appBar: AppBar(
        title: Text('Medical Staff', style: TextStyle()),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 150,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 200, color: Colors.blue[700]),
            ),
            SizedBox(height: 20),
            _buildActionButton(
              'Procedura di Applicazione Patch',
              Colors.green,
              Colors.white,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PatchInstructionsPage()),
                );
              },
            ),

            SizedBox(height: 15),
            _buildActionButton('Cambia Pin', Colors.blue, Colors.white, () => _showChangePinDialog(context, appState)),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, AppState appState) {
    TextEditingController newPinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cambia PIN'),
          content: TextField(
            controller: newPinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'Inserisci nuovo PIN a 4 cifre'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                if (newPinController.text.length == 4) {
                  appState.setPin(newPinController.text);
                  appState.loadPin(); // Ricarica il PIN appena viene cambiato
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PIN cambiato con successo')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Il PIN deve avere 4 cifre')),
                  );
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(String text, Color color, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 70,
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