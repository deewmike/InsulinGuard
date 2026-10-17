import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:app/ui/pages/home_page.dart';
import 'package:app/ui/pages/secondary_page.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({Key? key, required this.currentIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Dispositivo',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        // Per evitare problemi di focus, avvolgiamo le pagine in un widget Material
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (context) => Material(child: HomePage()),
            );
          case 1:
            return CupertinoTabView(
              builder: (context) => Material(child: InsulinometerHome()),
            );
          default:
            return Container();
        }
      },
    );
  }
}
