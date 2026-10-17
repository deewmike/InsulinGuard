# Contribuire a InsulinGuard

InsulinGuard è un **prototipo accademico**. Il flusso seguente è **proposto** e non costituisce una policy già approvata dai maintainer.

## Proporre una modifica

1. Aprire una issue con problema, impatto, passi per riprodurlo e file coinvolti.
2. Creare una pull request limitata allo scopo dell'issue e aggiornare README o `/docs` quando cambia un comportamento.
3. Allegare `flutter analyze`, `flutter test` e prove su device/OS dichiarati; **non indicare test come superati se non eseguiti**. Il test widget esistente è un template, non una copertura significativa.

## Checklist PR

- [ ] **BLE:** riportati byte/CRC di esempio, compatibilità firmware/simulatore e test per ACK/NACK, timeout ed errori (se pertinenti).
- [ ] **UI:** considerati caricamento, permessi negati, disconnessioni, accessibilità e navigazione.
- [ ] **Dati:** previste migrazioni e test SQLite per cambi di schema; niente dati sanitari reali, identificativi o segreti in codice, screenshot e log.
- [ ] **Lifecycle:** subscription/controller rilasciati correttamente, nessuna gestione di errori nascosta.
- [ ] **Piattaforme:** compatibilità Android/iOS rivendicata solo dove effettivamente testata.

Le questioni prioritarie (framing BLE, CRC/ACK, retry, permessi iOS, manifest Android e PIN dimostrativo) sono in [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md).
