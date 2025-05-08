import 'package:flutter/material.dart';
import 'package:libmu/models/professor_model.dart';
import 'package:libmu/services/professor_service.dart';
import 'package:libmu/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:libmu/screens/professor/professor_books_screen.dart';
import 'package:libmu/screens/professor/professor_profile_screen.dart';
import 'package:libmu/screens/professor/professor_search_screen.dart';

class ProfessorDashboard extends StatefulWidget {
  const ProfessorDashboard({Key? key}) : super(key: key);

  @override
  _ProfessorDashboardState createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
  int _selectedIndex = 0;
  final ProfessorService _professorService = ProfessorService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.firebaseUser;

    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<ProfessorModel?>(
      stream: authService.getProfessorData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final professor = snapshot.data!;
        final List<Widget> _screens = [
          _buildHomeContent(professor),
          const ProfessorBooksScreen(),
          const ProfessorSearchScreen(),
          ProfessorProfileScreen(professor: professor),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(
                  'assets/images/mu_logo.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 8),
                const Text('MU Library - Professor'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfessorSearchScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: 'My Books',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeContent(ProfessorModel professor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${professor.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${professor.designation} - ${professor.department}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Professor Privileges',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivilegeItem(
                    Icons.book,
                    'Borrow up to ${ProfessorModel.MAX_BOOKS_ALLOWED} books',
                  ),
                  _buildPrivilegeItem(
                    Icons.calendar_today,
                    '${ProfessorModel.BORROWING_DURATION_DAYS} days borrowing period',
                  ),
                  _buildPrivilegeItem(
                    Icons.refresh,
                    'Up to ${ProfessorModel.MAX_RENEWALS} renewals per book',
                  ),
                  _buildPrivilegeItem(
                    Icons.priority_high,
                    'Priority reservation',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Research Areas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: professor.researchAreas.map((area) {
                      return Chip(
                        label: Text(area),
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegeItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
} 