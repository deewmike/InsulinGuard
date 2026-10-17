import 'package:app/ui/pages/diario_paziente.dart';
import 'package:flutter/material.dart';

class PatchConfermationPage extends StatelessWidget {
  @override
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
            Stack(
              alignment: Alignment.center,
              children: [
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

                // Scritta "1/2" in basso a destra
                Positioned(
                  bottom: 5,  // Distanza dal basso
                  right: 5,    // Distanza da destra
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,  // Sfondo leggermente scuro per visibilità
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "2/2",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),


            const SizedBox(height: 20),

            // Testo "Livello della Batteria Sufficiente"
            const Text(
              "Patch applicata correttamente",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 10),

            // Testo "Procedere con l'applicazione della patch"
            const Text(
              "Procedere con la misurazione",
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
                onPressed: () {
                  // Navigazione alla prossima pagina
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DiarioPazientePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
