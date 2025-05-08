import 'package:flutter/material.dart';
import 'package:libmu/services/professor_service.dart';
import 'package:libmu/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ProfessorBooksScreen extends StatefulWidget {
  const ProfessorBooksScreen({Key? key}) : super(key: key);

  @override
  _ProfessorBooksScreenState createState() => _ProfessorBooksScreenState();
}

class _ProfessorBooksScreenState extends State<ProfessorBooksScreen> {
  final ProfessorService _professorService = ProfessorService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.firebaseUser;

    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _professorService.getBorrowedBooks(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = snapshot.data!;

        if (books.isEmpty) {
          return const Center(
            child: Text('No books borrowed yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            final dueDate = book['dueDate'] as DateTime?;
            final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

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
                      'Due Date: ${dueDate != null ? DateFormat('MMM dd, yyyy').format(dueDate) : 'Not set'}',
                      style: TextStyle(
                        color: isOverdue ? Colors.red : null,
                        fontWeight: isOverdue ? FontWeight.bold : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (book['renewals'] < 3)
                          TextButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Renew'),
                            onPressed: () async {
                              try {
                                await _professorService.renewBook(user.uid, book['id']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Book renewed successfully'),
                                  ),
                                );
                              } catch (e) {
                                // Do not show any error SnackBar for technical errors
                              }
                            },
                          ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.assignment_return),
                          label: const Text('Return'),
                          onPressed: () async {
                            try {
                              await _professorService.returnBook(user.uid, book['id']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Book returned successfully'),
                                ),
                              );
                            } catch (e) {
                              // Do not show any error SnackBar for technical errors
                            }
                          },
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
    );
  }
} 