import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/database_helper.dart';

class AppState extends ChangeNotifier {
  bool isDeviceConnected = false;
  bool _isPatchApplied = false;
  bool get isPatchApplied => _isPatchApplied;

  Future<void> setPatchApplied(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("is_patch_applied", value);
    _isPatchApplied = value;
    notifyListeners();
  }

  Future<void> loadPatchApplied() async {
    final prefs = await SharedPreferences.getInstance();
    _isPatchApplied = prefs.getBool("is_patch_applied") ?? false;
    notifyListeners();
  }

  DateTime? _patchReplacementDate;
  String _pin = '0000';
  Map<String, dynamic>? _nextSomministrazione;

  // Variabili per le generalità dell'utente
  String _nome = "";
  String _cognome = "";
  String _dataNascita = "";

  final DatabaseHelper dbHelper = DatabaseHelper();

  // Getter per accedere ai dati
  String get pin => _pin;
  Map<String, dynamic>? get nextSomministrazione => _nextSomministrazione;
  String get nome => _nome;
  String get cognome => _cognome;
  String get dataNascita => _dataNascita;

  AppState() {
    loadPin();
    loadPatchReplacementDate();
    loadNextSomministrazione();
    loadUserDetails(); // Carica le generalità all'avvio
  }

  void toggleConnection() {
    isDeviceConnected = !isDeviceConnected;
    notifyListeners();
  }

  Future<void> setPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("staff_pin", newPin);
    _pin = newPin;
    notifyListeners();
  }

  Future<void> loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString("staff_pin") ?? '0000';
    notifyListeners();
  }

  Future<void> setPatchReplacementDate(DateTime newDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("patch_replacement_date", newDate.toIso8601String());
    _patchReplacementDate = newDate;
    notifyListeners();
  }

  Future<void> loadPatchReplacementDate() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedDate = prefs.getString("patch_replacement_date");
    if (savedDate != null) {
      _patchReplacementDate = DateTime.parse(savedDate);
    }
    notifyListeners();
  }

  String? getExpirationDate() {
    if (_patchReplacementDate == null) {
      return "Patch non applicata";
    } else {
      DateTime next = _patchReplacementDate!.add(Duration(days: 2));
      return "Prossima sostituzione: ${DateFormat('dd/MM/yyyy').format(next)}";
    }
  }

  Future<void> loadNextSomministrazione() async {
    _nextSomministrazione = await dbHelper.getNextSomministrazione();
    notifyListeners();
  }

  String getNextSomministrazioneText() {
    if (_nextSomministrazione == null) return "Nessuna somministrazione programmata";
    return "Prossima somministrazione: ${_nextSomministrazione!['time']} - ${_nextSomministrazione!['meal']} (${_nextSomministrazione!['dosage']} UI)";
  }

  // Funzioni per gestire le generalità dell'utente
  Future<void> saveUserDetails(String nome, String cognome, String dataNascita) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_nome", nome);
    await prefs.setString("user_cognome", cognome);
    await prefs.setString("user_data_nascita", dataNascita);

    _nome = nome;
    _cognome = cognome;
    _dataNascita = dataNascita;

    notifyListeners();
  }

  Future<void> loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    _nome = prefs.getString("user_nome") ?? "";
    _cognome = prefs.getString("user_cognome") ?? "";
    _dataNascita = prefs.getString("user_data_nascita") ?? "";

    notifyListeners();
  }

  String getUserDetailsText() {
    if (_nome.isEmpty || _cognome.isEmpty || _dataNascita.isEmpty) {
      return "Dati utente non impostati";
    }
    return "Utente: $_nome $_cognome, Nato il $_dataNascita";
  }
}
