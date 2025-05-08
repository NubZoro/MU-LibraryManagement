import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libmu/models/book.dart';

class BookListScreen extends StatelessWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('books').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = snapshot.data!.docs
            .map((doc) => Book.fromFirestore(doc))
            .toList();

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(book.title),
                subtitle: Text(book.author),
                trailing: book.available
                    ? ElevatedButton(
                        onPressed: () => _borrowBook(context, book),
                        child: const Text('Borrow'),
                      )
                    : const Text('Unavailable'),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _borrowBook(BuildContext context, Book book) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('books').doc(book.id).update({
        'available': false,
        'borrowedBy': user.uid,
        'borrowedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book borrowed successfully!')),
      );
    } catch (e) {
      // Do not show any error SnackBar for technical errors
    }
  }
} 