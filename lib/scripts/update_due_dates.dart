import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/book_service.dart';

void main() async {
  final bookService = BookService();
  final firestore = FirebaseFirestore.instance;

  try {
    // Get the "Flow" book
    final flowBook = await firestore
        .collection('books')
        .where('title', isEqualTo: 'Flow')
        .get();

    // Get a test book (first available book)
    final testBook = await firestore
        .collection('books')
        .where('title', isNotEqualTo: 'Flow')
        .limit(1)
        .get();

    if (flowBook.docs.isNotEmpty) {
      await bookService.makeBookOverdue(flowBook.docs.first.id, 3); // 3 days overdue
      print('Updated "Flow" book to be 3 days overdue');
    } else {
      print('Could not find "Flow" book');
    }

    if (testBook.docs.isNotEmpty) {
      await bookService.makeBookOverdue(testBook.docs.first.id, 1); // 1 day overdue
      print('Updated test book to be 1 day overdue');
    } else {
      print('Could not find a test book');
    }
  } catch (e) {
    print('Error updating due dates: $e');
  }
} 