# Audit documentale: rischi e informazioni mancanti

[← README](../README.md) · [Protocollo BLE](BLE_PROTOCOL.md) · [Development](DEVELOPMENT.md)

**Ambito:** analisi statica della copia Drive `appInsulin`, confronto con le due tesi e con il simulatore Python allegato; **nessuna compilazione, prova di interoperabilità o validazione clinica**. Le priorità seguenti sono indicazioni per la verifica, non vulnerabilità confermate in un prodotto distribuito.

## Priorità tecniche

| Priorità | Ambito | Evidenza osservata | Impatto possibile / azione |
| --- | --- | --- | --- |
| P0 | Uso previsto | Prototipo impiegato per un contesto biomedicale senza validazione clinica documentata nel repository | Esplicitare **solo uso di ricerca**; nessuna decisione terapeutica |
| P0 | Privacy/autorizzazione | PIN staff predefinito `0000`, salvato come stringa in `shared_preferences`; anagrafica in preferenze | Definire modello di sicurezza, cifratura, accessi e minimizzazione dati prima di esposizione a pazienti |
| P1 | Protocollo: inizio misura | La UI invia `0x02` senza payload; il simulatore legge `value[1]` come frequenza | Disallineamento con possibile eccezione lato simulatore; stabilire wire contract |
| P1 | Protocollo: framing | `handleIncomingData` prova prima `data.length % 5 == 0`, poi `% 7 == 0` | Un frame sweep lungo 35 byte può percorrere il ramo a 5 byte e non essere accodato correttamente |
| P1 | Integrità ACK | `completeAck()` viene chiamato per risposte ACK con payload prima della verifica CRC | Comando potenzialmente segnalato come confermato nonostante payload non valido |
| P1 | Retry | `sendCommandWithAck` usa loop infinito senza limite/annullamento | Operazione UI bloccata in assenza di ACK applicativo persistente |
| P1 | Test statistici | Requisito deviazione standard su reale e immaginaria vs UI che valuta solo la reale | Verifica patch non equivalente alle condizioni descritte in tesi |
| P1 | Notifiche/manifest Android | Manifest registra `NotificationBootReceiver` / `NotificationForegroundService` non individuati fra i sorgenti accessibili | Risolvere classi native e tipi di service; test reboot/background |
| P1 | iOS BLE | `Info.plist` manca di `NSBluetoothAlwaysUsageDescription`; setup notifiche Android-only | Portabilità iOS non verificata; completare permessi e smoke test device |
| P1 | Rilascio | `release` firmato con `signingConfigs.debug` | Non usare per release distribuita |
| P1 | Test automatici | `widget_test.dart` è template counter | Non fornisce copertura dell'app; creare test realistici |
| P2 | Dati SQLite | Metodo riceve `meal` ma colonna non esiste; altri file leggono `meal` | Possibile dato assente / rendering incoerente |
| P2 | Formati data/ora | UI salva anche `TimeOfDay.format(context)`; altre funzioni parse `yyyy-MM-dd HH:mm` | Errori con locale 12h/AM-PM e ordinamento testuale |
| P2 | BLE scan/subscription | `.listen()` a scan e notify senza conservare/cancellare sempre le subscription | Possibili listener duplicati e memory leak dopo nuove scansioni/connessioni |
| P2 | Eventi UI | `BLEController.handleIncomingData` riceve `BuildContext` e chiama `Navigator.push` | Navigazione su context non più valido o route duplicate |
| P2 | Stato UI | `HomePage._buildPatchInsulinaCard()` crea `AppState()` nuovo | Card patch può leggere dati non ancora caricati/non allineati allo stato globale |
| P2 | Sweep payload | Tesi richiedono frequenza iniziale e intervallo; `sendSweepCommand()` invia solo numero spettri/frequenze | Impossibile attestare configurazione completa del trasduttore |
| P2 | Protocollo: pacchetti mancanti | `verifyCRC` rileva CRC errati ma non sequence number assenti | Perdita senza frame corrotto può non attivare il NACK corretto |
| P2 | Protocollo simulator | Variabile locale `pacchetti_singola_frequenza` nasconde quella globale usata per NACK | Ritrasmissione single-frequency da verificare/correggere |
| P2 | Identità package | `pubspec.yaml` si chiama `app`; package Android `com.example.app` | Branding e namespace di produzione da decidere |
| P3 | Code quality | `flutter_reactive_ble` / `permission_handler` senza constraint espliciti in pubspec | Limitare cambi non intenzionali quando si ricrea il lock |
| P3 | CI | Nessuna pipeline CI identificata nei materiali ispezionati | Non mostrare badge di build riuscita finché non esistono test eseguiti |

**Nota Android:** sono presenti le directory native `java/` e `kotlin/`, ma i receiver e service dichiarati nel manifest non sono stati trovati nei percorsi accessibili; controllare il repository Git originale prima di considerarli assenti.

## Differenze tra tesi e implementazione

- **Monitoraggio 48 ore:** le tesi prevedono campionamento rapido da **−20 a +40 minuti** intorno al bolo e lento altrimenti; uno scheduler BLE end-to-end delle commutazioni non è stato verificato.
- **Sweep:** oltre a numero di spettri/frequenze, la specifica accademica cita frequenza iniziale e passo su scala logaritmica; il comando Dart invia soltanto i primi due parametri.
- **Trasmissione:** le tesi descrivono gruppi (anche da 10) e ACK cumulativo/NACK selettivo, senza essere del tutto uniformi sulla cadenza; il codice risponde per buffer di notifica, non per un gruppo esplicito da 10.
- **Verifica patch:** la tesi BLE descrive monotonicità della parte reale su una finestra minima di 10 e deviazione standard su **reale e immaginaria**; il codice verifica monotonicità di entrambe tramite medie su 10, ma la deviazione standard solo della reale. La misura single-frequency calcola invece la media del chunk ricevuto (soglia 500), non necessariamente su 10 punti.
- **Calendario e piattaforme:** sincronizzazione completa col device e funzionamento iOS sono obiettivi dichiarati, non dimostrati da test su questa copia.

## Limiti delle evidenze

Non sono certificati **build/test riusciti, compatibilità col firmware reale, precisione o validazione medica del sensore, autenticazione sicura, comportamento notifiche dopo riavvio o realizzazione di ogni requisito accademico**. La descrizione del codice non implica sicurezza né idoneità a decisioni terapeutiche.

## Informazioni richieste prima di dichiarare compatibilità o readiness

1. **Protocollo/firmware:** versione e sorgenti, UUID/proprietà, payload/evento `0xFE`, CRC, framing, gruppi, MTU, ACK/NACK, endianess, timeout e retry, oltre a golden test byte-level.
2. **Toolchain e prove:** output `flutter --version`, commit/tag, SDK/Gradle/Kotlin, risultati di `flutter analyze`, test e build, almeno un Android e un iPhone fisici **se iOS è dichiarato supportato**.
3. **Dati e utilizzo previsto:** modello di accesso al personale, cifratura/minimizzazione, privacy, politiche di logging e distinzione formale tra studio e prodotto per pazienti.
4. **Manutenzione (secondario):** URL GitHub, maintainer, policy di review, roadmap, matrice OS/device, eventuale backend futuro e pipeline CI; badge build/coverage soltanto dopo prove effettive.

**Percorso di risoluzione suggerito:** implementare framing e retry limitati, correlare/verificare il CRC **prima** di accettare ACK, controllare sequenze mancanti, validare i criteri statistici, gestire il ciclo di vita dei listener, allineare schema SQLite/date, correggere PIN/permessi/componenti Android e testare notifiche, BLE e rilascio su device. Le azioni sono proposte, non funzionalità già implementate. La conformità regolatoria richiede valutazione separata.
