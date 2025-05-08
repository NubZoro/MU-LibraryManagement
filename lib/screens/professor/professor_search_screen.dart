import 'package:flutter/material.dart';
import 'package:libmu/services/professor_service.dart';
import 'package:libmu/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessorSearchScreen extends StatefulWidget {
  const ProfessorSearchScreen({Key? key}) : super(key: key);

  @override
  _ProfessorSearchScreenState createState() => _ProfessorSearchScreenState();
}

class _ProfessorSearchScreenState extends State<ProfessorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProfessorService _professorService = ProfessorService();
  String _searchQuery = '';
  String _selectedFilter = 'title';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.firebaseUser;

    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search books...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Title', 'title'),
                      _buildFilterChip('Author', 'author'),
                      _buildFilterChip('ISBN', 'isbn'),
                      _buildFilterChip('Department', 'department'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .where(_selectedFilter, isGreaterThanOrEqualTo: _searchQuery)
                  .where(_selectedFilter, isLessThanOrEqualTo: '${_searchQuery}z')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final books = snapshot.data!.docs;

                if (books.isEmpty) {
                  return const Center(
                    child: Text('No books found'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index].data() as Map<String, dynamic>;
                    final isAvailable = book['status'] == 'available';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book['title'] ?? 'Unknown Title',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Author: ${book['author'] ?? 'Unknown'}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ISBN: ${book['isbn'] ?? 'Not available'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Department: ${book['department'] ?? 'Not specified'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isAvailable)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.book),
                                    label: const Text('Borrow'),
                                    onPressed: () async {
                                      try {
                                        await _professorService.borrowBook(
                                          user.uid,
                                          books[index].id,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Book borrowed successfully'),
                                          ),
                                        );
                                      } catch (e) {
                                        // Do not show any error SnackBar for technical errors
                                      }
                                    },
                                  )
                                else
                                  const Text(
                                    'Not Available',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == value,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
      ),
    );
  }
} 