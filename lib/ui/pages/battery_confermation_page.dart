import 'package:flutter/material.dart';
import 'package:app/ui/pages/patch_application_failed.dart';
import 'package:app/ui/pages/patch_confermation_page.dart';
import 'package:app/utils/complex_numbers.dart';
import 'dart:math';
import 'package:app/core/ble_handler.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:app/core/ble_commandSender.dart';

class BatteryConfirmationPage extends StatefulWidget {
  @override
  _BatteryConfirmationPageState createState() => _BatteryConfirmationPageState();
}

class _BatteryConfirmationPageState extends State<BatteryConfirmationPage> {

  @override
  bool _isChecking = false;
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Procedura Completata"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Icona di successo
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(30),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 120,
              ),
            ),

            const SizedBox(height: 20),

            // Testo "Livello della Batteria Sufficiente"
            const Text(
              "Livello della Batteria Sufficiente",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 10),

            // Testo "Procedere con l'applicazione della patch"
            const Text(
              "Procedere con l'applicazione della patch",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // Pulsante "Premi per Continuare"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: _isChecking
                    ? null
                    : () async {
                  setState(() => _isChecking = true);

                  final bleController = Provider.of<BLEController>(context, listen: false);
                  bleController.resetPatchFlag();

                  bleController.resetPatchFlag();  // Esiste già
                  bleController.impedenzaConfermata = false;  // 🔧 AGGIUNGI QUESTO

                  bool success = await bleController.commandSender.sendCommandWithAck(
                    commandId: 0x02,
                    payload: Uint8List.fromList([]), // frequenza se necessaria
                  );

                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Errore avvio misura")),
                    );
                    setState(() => _isChecking = false);
                    return;
                  }

                  bool impedenzaOk = await waitForImpedanceCheck(bleController);
                  print("🚨 waitForImpedanceCheck completata: $impedenzaOk");
                  if (!impedenzaOk) {
                    print("⛔ Impedenza fallita, niente sweep.");
                    setState(() => _isChecking = false);
                    return;
                  }
                  bleController.patchCorrectlyApplied = true;
                  bleController.notifyListeners();
                  // ✅ Invia ora STOP
                  bool stopSuccess = await bleController.commandSender.sendCommandWithAck(
                    commandId: 0xFF,
                    payload: Uint8List(0),
                  );

                  if (!stopSuccess) {
                    print("⛔ ACK STOP non ricevuto, blocco sweep.");
                    setState(() => _isChecking = false);
                    return;
                  }


                  print("🛑 STOP completato, ora invio sweep...");
                  bleController.impedenzaConfermata = false;
                  await bleController.avviaSweep(3, 100);
                  bleController.inModSweep = true;

                  // ⏳ ASPETTA completamento dei 3 sweep prima del check
                  await bleController.waitForSweepCompletion(3);
                  // Dopo che lo sweep è stato avviato, esegui i controlli sui dati ricevuti
                  print("🔍 Avvio controllo sweep dopo invio");
                  bool sweepDataOk = await checkSweepData(bleController);
                  print("✅ Controllo sweep completato: $sweepDataOk");

                  if (sweepDataOk) {
                    print("✅ Sweep validi. Procedo con la patch.");
                    bleController.patchCorrectlyApplied = true;
                    bleController.notifyListeners();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PatchConfermationPage()));
                  } else {
                    print("❌ Sweep non validi.");
                    setState(() => _isChecking = false);
                    return;
                  }

                  setState(() => _isChecking = false);
                },


                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),


                child: _isChecking
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Premi per Continuare",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),

              ),
            ),
            if (_isChecking)
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "Attendere: verifica adesione patch in corso...",
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<bool> waitForImpedanceCheck(BLEController bleController) async {

    if (bleController.impedenzaConfermata) {
      print("✅ Impedenza già confermata all'avvio");
      return true;
    }

    final completer = Completer<bool>();
    print("👂 Listener attivato – impedenzaConfermata: ${bleController.impedenzaConfermata}");
    void listener() {
      if (bleController.impedenzaConfermata) {
        bleController.removeListener(listener);
        completer.complete(true);
      }
    }

    bleController.addListener(listener);

    return completer.future.timeout(Duration(seconds: 60), onTimeout: () {
      bleController.removeListener(listener);
      return false;
    });
  }

  Future<bool> checkSweepData(BLEController bleController) async {
    print("🔬 Inizio checkSweepData...");
    print("📊 sweepDataReal: ${bleController.sweepDataReal}");
    print("📊 sweepDataImag: ${bleController.sweepDataImag}");

    // ✅ Verifica monotonicità su entrambe le parti
    bool monotonaReale = bleController.checkMonotonicity(bleController.sweepDataReal[0]);
    bool monotonaImmaginaria = bleController.checkMonotonicity(bleController.sweepDataImag[0]);

    // ✅ Verifica deviazione standard solo sulla parte reale
    bool deviazioneOk = bleController.checkStandardDeviation(bleController.sweepDataReal);

    print("📉 Monotona Reale: $monotonaReale");
    print("📉 Monotona Immaginaria: $monotonaImmaginaria");
    print("📊 Deviazione OK: $deviazioneOk");

    return monotonaReale && monotonaImmaginaria && deviazioneOk;
  }



}



