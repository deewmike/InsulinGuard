import 'dart:math';
import 'package:app/utils/complex_numbers.dart';

class DeviceDataManager {
  static final DeviceDataManager _instance = DeviceDataManager._internal();

  factory DeviceDataManager() {
    return _instance;
  }

  DeviceDataManager._internal();

  /// Simula il livello della batteria (tra 20% e 100%)
  int getSimulatedBatteryLevel() {
    return Random().nextInt(81) + 20; // Genera un valore casuale tra 20 e 100
  }

  static List<Complex> generateRandomComplexArray(int length, {double min = -10, double max = 10}) {
    Random random = Random();
    return List.generate(length, (_) {
      double real = min + random.nextDouble() * (max - min);
      double imag = min + random.nextDouble() * (max - min);
      return Complex(real, imag);
    });
  }


}

