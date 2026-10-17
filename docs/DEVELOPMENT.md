# Sviluppo, configurazione e test locale

[← README](../README.md) · [Protocollo BLE](BLE_PROTOCOL.md) · [Verifiche](KNOWN_ISSUES.md)

> **Stato:** istruzioni ricavate dalla copia Drive `appInsulin`, **non testate con una build** in questa revisione. `TODO: [Confermare versione Flutter, commit e dispositivi con build funzionante]`.

## Requisiti e avvio

| Elemento | Evidenza / limite |
| --- | --- |
| Flutter/Dart | `pubspec.yaml`: Dart `^3.6.2`; lock: `>=3.7.0-0 <4.0.0`. Versione Flutter concreta da confermare. |
| Android | SDK min/target/compile derivati dalla toolchain Flutter; Java/Kotlin target **17**, quindi configurare JDK 17. |
| iOS | Richiede macOS, Xcode e CocoaPods; permessi BLE/notifiche da completare. |
| Dipendenze | Conservare `pubspec.lock`; contiene `flutter_reactive_ble 5.4.0`, `provider 6.1.2`, `sqflite 2.4.1`, `flutter_local_notifications 17.2.4`, `permission_handler 11.3.1`. Per le altre versioni, vedi [Stack nel README](../README.md#stack-tecnologico). |
| BLE | Serve hardware compatibile o simulatore con stack BLE che consenta advertising GATT. |

```bash
cd appInsulin
flutter --version
flutter doctor -v
flutter pub get
flutter devices
flutter run -d <device-id>

# Controlli consigliati: eseguirli e registrare i risultati
flutter analyze
flutter test
flutter build apk --debug
```

`test/widget_test.dart` è ancora il template Flutter del contatore, non un test dell'app. In `pubspec.yaml`, `flutter_reactive_ble` e `permission_handler` non hanno constraint espliciti: se il lock cambia, verificare nuovamente BLE e permessi.

## Android: permessi e configurazione

Sorgente: `android/app/src/main/AndroidManifest.xml`.

| Area | Dichiarazioni osservate | Verifiche richieste |
| --- | --- | --- |
| BLE | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`; `BLUETOOTH`, `BLUETOOTH_ADMIN` fino a SDK 30; `android.hardware.bluetooth_le` opzionale | Richieste runtime Android 12+, gestione permessi negati e assenza radio. |
| Posizione | `ACCESS_FINE_LOCATION` (fino a 30), `ACCESS_COARSE_LOCATION` (fino a 28), `ACCESS_BACKGROUND_LOCATION` | Motivare/limitare il permesso in background; verificare policy e comportamento legacy. |
| Notifiche | `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE` | Permessi runtime/speciali, pianificazione e ripristino dopo reboot. |
| Componenti nativi | `.core.NotificationBootReceiver`, `.core.NotificationForegroundService` con tipo `mediaProjection` | Componenti **non individuati nei file accessibili**; verificare classi e tipo del servizio. |

Il manifest contiene metadata per un canale Firebase, ma **non è emersa una dipendenza Firebase nel `pubspec.yaml`**: non documentarlo come servizio funzionante. Nel build Gradle, il blocco `release` usa `signingConfigs.debug`: predisporre una firma separata prima della distribuzione. Testare almeno Android pre-12, 12+ e notifiche 13+, con manifest merger e stack Bluetooth verificati.

## iOS: completamento richiesto

`ios/Runner/Info.plist` **non contiene** `NSBluetoothAlwaysUsageDescription`. Esempio **non presente nel repository**, da adattare dopo approvazione del testo:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Il Bluetooth consente la connessione al dispositivo di monitoraggio associato.</string>
```

`NotificationService.initialize()` configura soltanto `AndroidInitializationSettings`: permessi, inizializzazione notifiche iOS, eventuali capability, firma e provisioning restano da verificare. Non affermare compatibilità iOS senza una prova fisica.

## Simulatore BLE (allegato separatamente)

`ble_simulator.py` usa la libreria Python `bless` e pubblicizza `insulin_sim`, servizio `26ddc6b7-8d50-41d5-a1e2-8b2e1d0636fb` e caratteristica `11235a37-444a-4389-bc22-edf0b0a3997f`. Lo script **non risulta incluso nella root Drive** e va copiato esplicitamente nella cartella di esecuzione:

```bash
python -m venv .venv
# Linux/macOS: source .venv/bin/activate
# Windows PowerShell: .venv\Scripts\Activate.ps1
python -m pip install bless
python ble_simulator.py
```

Non sono stati eseguiti test di advertising o interoperabilità. **Prima dell'uso** confrontare comando `0x02`, frame da 5/7 byte, ACK/NACK e ritrasmissioni con [la specifica osservata](BLE_PROTOCOL.md).

## Verifica e rilascio

Per ogni prova registrare **device/OS, Flutter/Dart, pacchetti risolti, UUID, MTU negoziato, bytes di comandi e notifiche, CRC, sequenze e timeout**, omettendo dati sanitari o anagrafici reali. Coprire scan, batteria, misura/STOP, sweep 3×100, NACK, disconnessione, notifiche dopo riavvio e accesso staff. I casi attesi e i problemi aperti sono in [Protocollo BLE](BLE_PROTOCOL.md#8-matrice-di-test-del-protocollo-da-eseguire) e [Known Issues](KNOWN_ISSUES.md).

**Nessuna pubblicazione come prodotto medico** è giustificata da questa documentazione: richiederebbe almeno verifiche su hardware, sicurezza dei dati, permessi, test, signing e valutazione dell'uso previsto/regolatoria.
