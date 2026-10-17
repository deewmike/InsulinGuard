# Academic References and Traceability

[← README](../README.md) · [Architecture](ARCHITECTURE.md) · [Frontend and UX](FRONTEND_UX.md)

## Thesis citations

**BLE module**

Bartoli, Lorenzo. *Connessioni vitali: progettazione e simulazione di un sistema BLE embedded per la comunicazione in applicazioni biomedicali* [*Vital Connections: Design and Simulation of an Embedded BLE System for Communication in Biomedical Applications*]. Final project in Fundamentals of Measurement, Degree in Computer Engineering, Polytechnic School and Basic Sciences, University of Naples Federico II, **academic year 2024/2025**. Supervisor: **Prof. Nicola Moccaldi**. Co-supervisors: **Eng. Francesco Caputo** and **Eng. Rosanna Manzo**.

**Frontend / UI/UX module**

Contino, Michele. *Progettazione e realizzazione del front-end di un’app mobile per il monitoraggio della terapia insulinica* [*Design and Implementation of the Frontend of a Mobile Application for Monitoring Insulin Therapy*]. Bachelor's thesis in Computer Engineering, Department of Electrical Engineering and Information Technology (DIETI), University of Naples Federico II, **academic year 2025/2026**. Supervisor: **Prof. Nicola Moccaldi**. Co-supervisors: **Eng. Francesco Caputo** and **Eng. Rosanna Manzo**.

## Chapter-to-code traceability

| Documentation area | BLE thesis — Bartoli | Frontend thesis — Contino | Related source code |
| --- | --- | --- | --- |
| Functional requirements | Ch. 1, §§1.2.1–1.2.7 | Ch. 1, §§1.2–1.3 | `core/`, `ui/pages/` |
| UX flow and mockups | §1.3, Fig. 1.3 | §§2.3.1–2.3.3, Fig. 2.2 | `ui/widgets/bottom_navigation_bar.dart`; `ui/pages/*` |
| Module boundaries | §1.4 (Flutter) | §§2.1–2.4 | `lib/main.dart`, `core/`, `ui/`, `utils/` |
| Permissions, scanning, connection, pairing | Ch. 2, §§2.1.1–2.1.4 | §3.3.2 | `core/ble_connection.dart`, `ui/pages/blue_connection.dart` |
| Commands, parsing, ACK/NACK | Ch. 3, §§3.1–3.3 | §1.2.4 and UI workflows in Ch. 3 | `core/ble_commandSender.dart`, `core/ble_handler.dart` |
| Battery, electrode contact, sweep | Ch. 3, §3.4 | §§1.3.2, 3.3.3 | `ui/pages/battery_confermation_page.dart`, `core/ble_handler.dart` |
| Simulator and CRC16 | Ch. 4, §§4.1–4.4 | Testing, §3.4 | Python BLE test simulator |
| Administration log, notifications, persistence | Patient requirements, §1.2.6 | §§3.2–3.4 | `database_helper.dart`, `notification_service.dart`, patient screens |


