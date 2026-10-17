# Riferimenti accademici e tracciabilità

[← README](../README.md) · [Architettura](ARCHITECTURE.md) · [Frontend & UX](FRONTEND_UX.md)

## Citazioni delle tesi

**Modulo BLE**

Bartoli, Lorenzo. *Connessioni vitali: progettazione e simulazione di un sistema BLE embedded per la comunicazione in applicazioni biomedicali*. Elaborato finale in Fondamenti di misure, Corso di Laurea in Ingegneria Informatica, Scuola Politecnica e delle Scienze di Base, Università degli Studi di Napoli Federico II, **anno accademico 2024/2025**. Relatore: **Ch.mo Prof. Nicola Moccaldi**. Correlatori: **Ing. Francesco Caputo** e **Ing. Rosanna Manzo**.

**Modulo Front-End / UI/UX**

Contino, Michele. *Progettazione e realizzazione del front-end di un’app mobile per il monitoraggio della terapia insulinica*. Tesi di Laurea in Ingegneria Informatica, Dipartimento di Ingegneria Elettrica e delle Tecnologie dell'Informazione (DIETI), Università degli Studi di Napoli Federico II, **anno accademico 2025/2026**. Relatore: **Ch.mo Prof. Nicola Moccaldi**. Correlatori: **Ing. Francesco Caputo** e **Ing. Rosanna Manzo**.

> I metadati bibliografici sono trascritti dai frontespizi dei PDF forniti. Per inserire DOI, permalink di archivio istituzionale o file PDF nel repository è necessario disporre di un URL pubblicabile e dei relativi diritti: **TODO: [Confermare autorizzazione e link alle tesi]**.

## Mappa dei capitoli

| Area documentata | Tesi BLE — Bartoli | Tesi Front-End — Contino | Codice di riferimento |
| --- | --- | --- | --- |
| Requisiti di funzionamento | Cap. 1, §§1.2.1–1.2.7 | Cap. 1, §§1.2–1.3 | `core/`, `ui/pages/` |
| Flusso di UX e mockup | §1.3, figura 1.3 | §§2.3.1–2.3.3, figura 2.2 | `ui/widgets/bottom_navigation_bar.dart`; `ui/pages/*` |
| Struttura modulare | §1.4 (Flutter) | §§2.1–2.4 | `lib/main.dart`, `core/`, `ui/`, `utils/` |
| Permessi, scan, connessione, pairing | Cap. 2, §§2.1.1–2.1.4 | §3.3.2 | `core/ble_connection.dart`, `ui/pages/blue_connection.dart` |
| Comandi, parsing, ACK/NACK | Cap. 3, §§3.1–3.3 | §1.2.4 e flussi UI cap. 3 | `core/ble_commandSender.dart`, `core/ble_handler.dart` |
| Batteria, contatto elettrodi, sweep | Cap. 3, §3.4 | §§1.3.2, 3.3.3 | `ui/pages/battery_confermation_page.dart`, `core/ble_handler.dart` |
| Simulator e CRC16 | Cap. 4, §§4.1–4.4 | Testing, §3.4 | `ble_simulator.py` allegato separatamente |
| Diario, notifiche e persistenza | Requisiti paziente §1.2.6 | §§3.2–3.4 | `database_helper.dart`, `notification_service.dart`, pagine paziente |

## Metodo di citazione nella documentazione

- **Tesi:** attestano motivazioni, requisiti, mockup e scelte progettuali storiche; non dimostrano automaticamente che il codice presente ora rispetti ogni specifica.
- **Sorgenti Dart:** attestano classi, funzioni e costanti testualmente presenti nella copia analizzata; non dimostrano da soli runtime, interoperabilità o validazione clinica.
- **Manifest/pod/Gradle:** attestano dichiarazioni di piattaforma; non bastano a certificare un build su device.
- **Simulatore Python:** evidenzia una possibile controparte GATT per il testing; è stato fornito come file separato e non va descritto come firmware di produzione.

