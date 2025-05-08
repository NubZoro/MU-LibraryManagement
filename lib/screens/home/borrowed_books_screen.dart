import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libmu/models/book.dart';
import 'package:libmu/widgets/animated_gradient_background.dart';

class BorrowedBooksScreen extends StatelessWidget {
  const BorrowedBooksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Debug: Test the borrowed books query
    (() async {
      try {
        print('DEBUG: Querying borrowed books for user: \\${user?.uid}');
        final snapshot = await FirebaseFirestore.instance
            .collection('books')
            .where('borrowedBy', isEqualTo: user?.uid)
            .get();
        print('DEBUG: Borrowed books count: \\${snapshot.docs.length}');
      } catch (e) {
        print('DEBUG: Borrowed books query error: \\${e.toString()}');
      }
    })();

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Borrowed Books',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('books')
                        .where('borrowedBy', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final books = snapshot.data!.docs
                          .map((doc) => Book.fromFirestore(doc))
                          .toList();

                      if (books.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No books borrowed yet',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Visit the home page to borrow books',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          final borrowedAt = book.borrowedAt;
                          final dueDate = borrowedAt?.add(const Duration(days: 14));

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: book.imageUrl != null
                                    ? Image.network(
                                        book.imageUrl!,
                                        width: 50,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.book, size: 50),
                                      )
                                    : const Icon(Icons.book, size: 50),
                              ),
                              title: Text(
                                book.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Author: ${book.author}'),
                                  if (dueDate != null)
                                    Text(
                                      'Due: ${_formatDate(dueDate)}',
                                      style: TextStyle(
                                        color: dueDate.isBefore(DateTime.now())
                                            ? Theme.of(context).colorScheme.error
                                            : null,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _returnBook(context, book),
                                child: const Text('Return'),
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
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _returnBook(BuildContext context, Book book) async {
    try {
      await FirebaseFirestore.instance.collection('books').doc(book.id).update({
        'available': true,
        'borrowedBy': null,
        'borrowedAt': null,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book returned successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Do not show any error SnackBar for technical errors
      }
    }
  }
} 