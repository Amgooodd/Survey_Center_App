import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final bool homee;
  final bool survv;
  final bool groupp;
  final bool anall;

  const BottomNavigationBarWidget({
    super.key,
    this.homee = false,
    this.survv = false,
    this.groupp = false,
    this.anall = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get isSuperAdmin value from the provider
    final userProvider = Provider.of<UserProvider>(context);
    final bool isSuperAdmin = userProvider.isSuperAdmin;

    int currentIndex;
    if (isSuperAdmin) {
      if (homee)
        currentIndex = 0;
      else if (survv)
        currentIndex = 1;
      else if (groupp)
        currentIndex = 2;
      else if (anall)
        currentIndex = 3;
      else
        currentIndex = 4;
    } else {
      if (homee)
        currentIndex = 0;
      else if (survv)
        currentIndex = 1;
      else if (groupp)
        currentIndex = 2;
      else if (anall)
        currentIndex = 3;
      else
        currentIndex = 0;
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 28, 51, 95),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: BottomNavigationBar(
        backgroundColor: Color.fromARGB(255, 28, 51, 95),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          const BottomNavigationBarItem(
            backgroundColor: Color.fromARGB(255, 28, 51, 95),
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            backgroundColor: Color.fromARGB(255, 28, 51, 95),
            icon: Icon(Icons.edit),
            label: 'Create Survey',
          ),
          const BottomNavigationBarItem(
            backgroundColor: Color.fromARGB(255, 28, 51, 95),
            icon: Icon(Icons.group),
            label: "Groups",
          ),
          const BottomNavigationBarItem(
            backgroundColor: Color.fromARGB(255, 28, 51, 95),
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          if (isSuperAdmin)
            const BottomNavigationBarItem(
              backgroundColor: Color.fromARGB(255, 28, 51, 95),
              icon: Icon(Icons.person_add),
              label: 'Add Admins',
            ),
        ],
        currentIndex: currentIndex,
        onTap: (index) {
          if (isSuperAdmin) {
            switch (index) {
              case 0:
                Navigator.popUntil(
                  context,
                  (route) => route.settings.name == '/firsrforadminn',
                );
                break;
              case 1:
                Navigator.pushNamed(context, '/createsurvv');
                break;
              case 2:
                Navigator.pushNamed(context, '/groupp');
                break;
              case 3:
                Navigator.pushNamed(context, '/elanall');
                break;
              case 4:
                Navigator.pushNamed(context, '/admin-management');
                break;
            }
          } else {
            switch (index) {
              case 0:
                Navigator.popUntil(
                  context,
                  (route) => route.settings.name == '/firsrforadminn',
                );
                break;
              case 1:
                Navigator.pushNamed(context, '/createsurvv');
                break;
              case 2:
                Navigator.pushNamed(context, '/groupp');
                break;
              case 3:
                Navigator.pushNamed(context, '/elanall');
                break;
            }
          }
        },
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.blueGrey,
      ),
    );
  }
}
