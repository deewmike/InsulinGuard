import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'ble_connection.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:app/ui/pages/patch_confermation_page.dart';
import 'package:app/ui/pages/patch_application_failed.dart';
import 'package:provider/provider.dart';
import 'package:app/core/ble_commandSender.dart';

class BLEController extends ChangeNotifier {


  late BLECommandSender _commandSender;
  BLECommandSender get commandSender => _commandSender;

  static const int impedanceThreshold = 500;  // Usa il valore corretto per te


  bool? patchCorrectlyApplied;
  bool impedenzaConfermata = false;
  bool fineMisuraRicevuta = false;
  bool attesaTimeoutAvviata = false;  // ⏱️ Flag per avviare attesa solo una volta
  Timer? timerVerificaImpedanza;      // ⏳ Timer gestito
  bool inModSweep = false;
  int? _batteryLevel;
  int? get batteryLevel => _batteryLevel;
  // ⬇️ Salvo i blocchi di campioni validi ricevuti

  List<Uint8List> spettriRicevuti = [];
  List<double> bufferSpettro = [];
  List<List<int>> sweepDataReal = [];
  List<List<int>> sweepDataImag = [];

  List<int> sweepBuffer = [];

  //int sweepLength = 100;


  void setBLE(FlutterReactiveBle ble, QualifiedCharacteristic characteristic) {
    _commandSender = BLECommandSender(
      ble: ble,
      commandCharacteristic: characteristic,
    );
  }

  void resetPatchFlag() {
    patchCorrectlyApplied = null;
    notifyListeners();
  }

  Future<void> handleIncomingData(List<int> data, BuildContext context) async {

    if (data.isEmpty) return;

    // --- ACK senza payload ---
    if (data[0] == BLECommandSender.ACK_BYTE) {
      if (data.length == 1) {
        print("✅ ACK semplice ricevuto (solo 0x55)");
        _commandSender.completeAck();
        return; // Fine
      }

      // --- ACK con payload e CRC ---
      if (data.length >= 4) {
        print("🔍 ACK con payload ricevuto: $data");
        _commandSender.completeAck();

        Uint8List payload = Uint8List.fromList(data.sublist(1, data.length - 2));
        int receivedCrc = (data[data.length - 2] << 8) | data[data.length - 1];
        int calculatedCrc = _commandSender.calculateCrc16(payload);

        print("📥 Payload ricevuto: $payload");
        print("CRC ricevuto: $receivedCrc, CRC calcolato: $calculatedCrc");

        if (receivedCrc == calculatedCrc && payload.isNotEmpty) {
          int commandId = payload[0];
          Uint8List actualData = payload.sublist(1);
          print("🎯 commandId ACK: $commandId, actualData: $actualData");

          _commandSender.handleResponse(commandId, actualData);
        } else {
          print("❌ CRC non valido o payload vuoto per dati: $data");
        }
        return;
      }
      // --- Qualsiasi altra lunghezza non valida ---
      print("⚠️ Pacchetto ACK con lunghezza non prevista: $data");
      return;
    } else if (data[0] == BLECommandSender.NACK_BYTE) {
      print("❌ NACK ricevuto dal dispositivo");
      _commandSender.completeAck(success: false);
      return;
    }

    // --- Fine misura: comando 0xFE con CRC ---
    if (data.length >= 3 && data[0] == 0xFE) {
      int receivedCrc = (data[data.length - 2] << 8) | data[data.length - 1];
      int calculatedCrc = _commandSender.calculateCrc16(Uint8List.fromList([0xFE]));

      print("🏁 Fine misura ricevuta. CRC ricevuto: $receivedCrc, calcolato: $calculatedCrc");

      if (receivedCrc == calculatedCrc) {
        print("✅ Fine misura validata. Blocco ACK e aggiorno UI.");
        //fineMisuraRicevuta = true;  // Blocca eventuali ACK futuri

        // Vai alla pagina di conferma o mostra snackbar
        Navigator.push(context, MaterialPageRoute(builder: (_) => PatchConfermationPage()));
        return;
      } else {
        print("❌ CRC non valido per fine misura, pacchetto ignorato.");
        return;
      }
    }

    if (impedenzaConfermata && !inModSweep) {
      print("⛔ Pacchetto ignorato: stop già inviato.");
      return;
    }

    // --- Ricezione pacchetti di campioni dal dispositivo (con verifica CRC) ---
    if (data.length % 5 == 0 ) {
      print("📡 Ricevuti campioni dal dispositivo: $data");

      List<int> errors = verifyCRC(data);

      if (errors.isEmpty) {
        print("✅ Tutti i campioni ricevuti correttamente, invio ACK cumulativo");
        _commandSender.sendAckWithCRC();
        avviaTimerVerificaImpedanza(context);
        if(!inModSweep){
          if (checkImpedanceCondition(data)) {
            print("🎯 Condizione impedenza soddisfatta, invio comando di stop");
            //patchCorrectlyApplied = true;  // Se serve notifica
            impedenzaConfermata = true;
            //notifyListeners();
            if (timerVerificaImpedanza?.isActive ?? false) {
              timerVerificaImpedanza?.cancel();
              print("🛑 Timer timeout impedenza cancellato");
            }
          } else {
            print("⚠️ Condizione impedenza NON ancora soddisfatta. Attendo timeout...");
          }
        }

      } else {
        print("⚠️ Errori CRC nei campioni ${errors}, invio NACK selettivo");
        _commandSender.sendNackWithCRC(errors);
      }
      return;
    }
    if(data.length % 7 == 0){
      print("📡 Ricevuti campioni dal dispositivo: $data");

      List<int> errors = verifyCRC(data);

      if (errors.isEmpty) {
        print(
            "✅ Tutti i campioni ricevuti correttamente, invio ACK cumulativo");
        _commandSender.sendAckWithCRC();
        if (inModSweep) {
          sweepBuffer.addAll(data);
          if (sweepBuffer.length >= 700) {
            List<int> sweepReal = [];
            List<int> sweepImag = [];


            for (int i = 0; i < 700; i += 7) {
              // Estrai byte 1 e 2 come int16 (valore reale)
              int low = sweepBuffer[i + 1];
              int high = sweepBuffer[i + 2];
              int real = (high << 8) | low;
              // Se è un numero con segno (int16), converti correttamente
              if (real >= 0x8000) real -= 0x10000;
              sweepReal.add(real);

              int imagLow = sweepBuffer[i + 3];
              int imagHigh = sweepBuffer[i + 4];
              int imag = (imagHigh << 8) | imagLow;
              if (imag >= 0x8000) imag -= 0x10000;
              sweepImag.add(imag);

            }

            sweepDataReal.add(sweepReal);
            sweepDataImag.add(sweepImag);

            sweepBuffer.clear();
            notifyListeners();
            print("📊 Sweep parziale ricevuto (${sweepDataReal.length}/3) (check: reali=${sweepDataReal.length}, immaginari=${sweepDataImag.length})");

          }
        }
      } else {
        print("⚠️ Errori CRC nei campioni ${errors}, invio NACK selettivo");
        _commandSender.sendNackWithCRC(errors);
      }
      return;
    }

    // --- Dati sconosciuti ---
    print("⚠️ Dati non riconosciuti: $data");
}

  Future<void> waitForSweepCompletion(int numSweep) async {
    final completer = Completer<void>();

    void listener() {
      if (sweepDataReal.length >= numSweep && sweepDataImag.length >= numSweep) {
        removeListener(listener);
        completer.complete();
      }
    }

    addListener(listener);

    return completer.future.timeout(Duration(seconds: 50), onTimeout: () {
      removeListener(listener);
      throw Exception("Timeout: sweep non completati");
    });
  }


  bool checkImpedanceCondition(List<int> data) {
    double sumReal = 0;
    double sumImag = 0;
    int sampleCount = data.length ~/ 5;

    for (int i = 0; i < data.length; i += 5) {
      int real = data[i + 1];
      int imag = data[i + 2];

      sumReal += real;
      sumImag += imag;
    }

    double avgReal = sumReal / sampleCount;
    double avgImag = sumImag / sampleCount;

    print("📈 Media Reale: $avgReal, Media Immaginaria: $avgImag");

    if (avgReal < impedanceThreshold && avgImag < impedanceThreshold) {
      patchCorrectlyApplied = true;
      impedenzaConfermata = true;
      notifyListeners();
      return true;
    } else {
      patchCorrectlyApplied = false;
      notifyListeners();
      return false;
    }
  }

  void avviaTimerVerificaImpedanza(BuildContext context) {
    if (attesaTimeoutAvviata) return;  // ❌ Non riavviare se già avviato

    attesaTimeoutAvviata = true;
    print("⏳ Attesa attiva: controllo impedenza entro 5 secondi...");

    timerVerificaImpedanza = Timer(Duration(seconds: 5), () {
      if (!impedenzaConfermata) {
        print("❌ Timeout: impedenza NON soddisfatta, navigo a fallita.");
        patchCorrectlyApplied = false;
        notifyListeners();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PatchApplicationFailed()),
        );
      } else {
        print("✅ Impedenza già confermata, nessuna azione.");
      }
    });
  }

  bool checkStandardDeviation(List<List<int>> sweeps, {double threshold = 10}) {
    if (sweeps.length != 3) return false;

    for (int i = 0; i < sweeps[0].length; i++) {
      final values = [
        sweeps[0][i].toDouble(),
        sweeps[1][i].toDouble(),
        sweeps[2][i].toDouble(),
      ];
      final mean = values.reduce((a, b) => a + b) / 3;
      final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / 3;
      final std = sqrt(variance);

      if (std > threshold) return false;
    }

    return true;
  }


  bool checkMonotonicity(List<int> sweep) {
    List<double> means = [];
    for (int i = 0; i < sweep.length; i += 10) {
      final window = sweep.sublist(i, i + 10);
      final mean = window.reduce((a, b) => a + b) / window.length;
      means.add(mean);
    }

    for (int i = 0; i < means.length - 1; i++) {
      if (means[i] < means[i + 1]) return false; // non decrescente
    }

    return true;
  }


  List<int> verifyCRC(List<int> data) {
    List<int> incorrect = [];
    if(!inModSweep){
      for (int i = 0; i < data.length; i += 5) {
        int seq = data[i];
        int real = data[i + 1];
        int imag = data[i + 2];
        int receivedCRC = (data[i + 3] << 8) | data[i + 4];
        int calculatedCRC = commandSender.calculateCrc16([seq, real, imag]);
        if (receivedCRC != calculatedCRC) incorrect.add(seq);
      }
    }else if(inModSweep){
      for (int i = 0; i <= data.length - 7; i += 7) {
        int seq = data[i];
        int real = data[i + 1];
        int realHigh = data[i + 2];
        int imag = data[i + 3];
        int imagHigh = data[i + 4];
        int receivedCRC = (data[i + 5] << 8) | data[i + 6];

        List<int> payload = [seq, real, realHigh, imag, imagHigh];
        int calculatedCRC = commandSender.calculateCrc16(payload);

        if (receivedCRC != calculatedCRC) incorrect.add(seq);
      }
    }

    return incorrect;
  }


  Future<void> updateBattery() async {
    await _commandSender.updateBattery(
      onBatteryLevelUpdated: (level) {
        _batteryLevel = level;
      },
      notifyListeners: notifyListeners,
    );
  }

  Future<void> avviaSweep(int spettri, int frequenze) async {
    await _commandSender.sendSweepCommand(
      numSpettri: spettri,
      numFrequenze: frequenze,
      onResponse: (data) {
        print("🔔 Sweep confermato con dati: $data");
      },
    );
  }
}


