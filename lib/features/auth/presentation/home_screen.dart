import 'package:ccu_mobile/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _HomeMainPage(),
    Center(child: Text("Horario")),
    Center(child: Text("Tareas")),
    Center(child: Text("Notas")),
    Center(child: Text("Perfil")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 70,
        leading: Row(
          children: [
            const SizedBox(width: 8),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ],
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(width: 4),
            Text(
              "CCU",
              key: Key("app_title"),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Image.asset("assets/images/logo.png", height: 80),
            ),
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text("Configuración"),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Cerrar sesión"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(onToggleTheme: () {}),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Horario",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: "Tareas",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "Notas"),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}

class _HomeMainPage extends StatelessWidget {
  const _HomeMainPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "¡Bienvenido, estudiante!",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              children: const [
                _QuickAccessCard(
                  icon: Icons.event,
                  title: "Agregar evento rápido",
                ),
                _QuickAccessCard(
                  icon: Icons.assignment_add,
                  title: "Agregar tarea",
                ),
                _QuickAccessCard(icon: Icons.calculate, title: "Calcular PPS"),
                _QuickAccessCard(
                  icon: Icons.notifications_active,
                  title: "Recordatorios",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _QuickAccessCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
