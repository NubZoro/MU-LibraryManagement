import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libmu/models/professor_model.dart';

class ProfessorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Borrow a book with professor privileges
  Future<void> borrowBook(String professorId, String bookId) async {
    final professorRef = _firestore.collection('professors').doc(professorId);
    final bookRef = _firestore.collection('books').doc(bookId);

    await _firestore.runTransaction((transaction) async {
      final professorDoc = await transaction.get(professorRef);
      final bookDoc = await transaction.get(bookRef);

      if (!bookDoc.exists) {
        throw Exception('Book not found');
      }

      final bookData = bookDoc.data()!;
      String status = bookData['status'] ?? (bookData['available'] == true ? 'available' : 'borrowed');
      if (status != 'available') {
        throw Exception('Book is not available');
      }

      final professorData = professorDoc.data()!;
      final borrowedBooks = List<String>.from(professorData['borrowedBooks'] ?? []);

      if (borrowedBooks.length >= ProfessorModel.MAX_BOOKS_ALLOWED) {
        throw Exception('Maximum books limit reached');
      }

      // Calculate due date based on professor privileges
      final dueDate = DateTime.now().add(
        Duration(days: ProfessorModel.BORROWING_DURATION_DAYS),
      );

      // Update book status
      transaction.update(bookRef, {
        'status': 'borrowed',
        'borrowedBy': professorId,
        'borrowedAt': DateTime.now().millisecondsSinceEpoch,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'borrowerType': 'professor',
      });

      // Update professor's borrowed books
      borrowedBooks.add(bookId);
      transaction.update(professorRef, {
        'borrowedBooks': borrowedBooks,
      });
    });
  }

  // Renew a book with professor privileges
  Future<void> renewBook(String professorId, String bookId) async {
    final professorRef = _firestore.collection('professors').doc(professorId);
    final bookRef = _firestore.collection('books').doc(bookId);

    await _firestore.runTransaction((transaction) async {
      final bookDoc = await transaction.get(bookRef);
      if (!bookDoc.exists) {
        throw Exception('Book not found');
      }

      final bookData = bookDoc.data()!;
      if (bookData['borrowedBy'] != professorId) {
        throw Exception('Book was not borrowed by this professor');
      }

      final renewals = bookData['renewals'] ?? 0;
      if (renewals >= ProfessorModel.MAX_RENEWALS) {
        throw Exception('Maximum renewals reached');
      }

      // Calculate new due date
      final currentDueDate = DateTime.fromMillisecondsSinceEpoch(bookData['dueDate']);
      final newDueDate = currentDueDate.add(
        Duration(days: ProfessorModel.BORROWING_DURATION_DAYS),
      );

      // Update book with new due date and renewal count
      transaction.update(bookRef, {
        'dueDate': newDueDate.millisecondsSinceEpoch,
        'renewals': renewals + 1,
        'lastRenewedAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  // Return a book
  Future<void> returnBook(String professorId, String bookId) async {
    final professorRef = _firestore.collection('professors').doc(professorId);
    final bookRef = _firestore.collection('books').doc(bookId);

    await _firestore.runTransaction((transaction) async {
      final bookDoc = await transaction.get(bookRef);
      if (!bookDoc.exists) {
        throw Exception('Book not found');
      }

      final bookData = bookDoc.data()!;
      if (bookData['borrowedBy'] != professorId) {
        throw Exception('Book was not borrowed by this professor');
      }

      // Update book status
      transaction.update(bookRef, {
        'status': 'available',
        'borrowedBy': null,
        'borrowedAt': null,
        'dueDate': null,
        'renewals': 0,
        'returnedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Update professor's borrowed books
      final professorDoc = await transaction.get(professorRef);
      final borrowedBooks = List<String>.from(professorDoc.data()!['borrowedBooks']);
      borrowedBooks.remove(bookId);
      transaction.update(professorRef, {
        'borrowedBooks': borrowedBooks,
        'lastBookReturn': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  // Get borrowed books with due dates
  Stream<List<Map<String, dynamic>>> getBorrowedBooks(String professorId) {
    return _firestore
        .collection('books')
        .where('borrowedBy', isEqualTo: professorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'dueDate': data['dueDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['dueDate'])
              : null,
        };
      }).toList();
    });
  }

  // Check if professor can borrow more books
  Future<bool> canBorrowMore(String professorId) async {
    final professorDoc = await _firestore.collection('professors').doc(professorId).get();
    if (!professorDoc.exists) return false;

    final borrowedBooks = List<String>.from(professorDoc.data()!['borrowedBooks'] ?? []);
    return borrowedBooks.length < ProfessorModel.MAX_BOOKS_ALLOWED;
  }
} 