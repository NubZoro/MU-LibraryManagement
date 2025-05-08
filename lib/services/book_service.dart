import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libmu/services/gamification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationService _gamification = GamificationService();

  // Borrow a book
  Future<void> borrowBook(String userId, String bookId) async {
    print('DEBUG: borrowBook called with userId: $userId, bookId: $bookId');
    final userRef = _firestore.collection('users').doc(userId);
    final bookRef = _firestore.collection('books').doc(bookId);

    await _firestore.runTransaction((transaction) async {
      print('DEBUG: Inside Firestore transaction');
      final userDoc = await transaction.get(userRef);
      final bookDoc = await transaction.get(bookRef);

      print('DEBUG: userDoc.exists: ${userDoc.exists}, bookDoc.exists: ${bookDoc.exists}');
      if (!bookDoc.exists) {
        print('DEBUG: Book not found');
        throw Exception('Book not found');
      }

      final bookData = bookDoc.data()!;
      print('DEBUG: bookData: $bookData');
      // Fallback for legacy books: treat available: true as status: 'available'
      String status = bookData['status'] ?? (bookData['available'] == true ? 'available' : 'borrowed');
      if (status != 'available') {
        print('DEBUG: Book is not available (status: $status)');
        throw Exception('Book is not available');
      }

      final userData = userDoc.data()!;
      print('DEBUG: userData: $userData');
      final borrowedBooks = List<String>.from(userData['borrowedBooks'] ?? []);
      final userLevel = userData['level'] ?? 1;

      if (borrowedBooks.length >= _gamification.getMaxBooksAllowed(userLevel)) {
        print('DEBUG: Maximum books limit reached');
        throw Exception('Maximum books limit reached for your level');
      }

      // Calculate due date based on user's level
      final dueDate = DateTime.now().add(
        Duration(days: _gamification.getBorrowingDuration(userLevel)),
      );
      print('DEBUG: dueDate: $dueDate');

      // Update book status
      transaction.update(bookRef, {
        'status': 'borrowed',
        'borrowedBy': userId,
        'borrowedAt': DateTime.now().millisecondsSinceEpoch,
        'dueDate': dueDate.millisecondsSinceEpoch,
      });
      print('DEBUG: Book status updated in transaction');

      // Update user's borrowed books
      borrowedBooks.add(bookId);
      transaction.update(userRef, {
        'borrowedBooks': borrowedBooks,
      });
      print('DEBUG: User borrowedBooks updated in transaction');

      // Award points for borrowing
      await _gamification.awardBorrowPoints(userId, bookData['category']);
      print('DEBUG: awardBorrowPoints completed');
    });
    print('DEBUG: Firestore transaction completed');
  }

  // Return a book
  Future<void> returnBook(String userId, String bookId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final bookRef = _firestore.collection('books').doc(bookId);

    await _firestore.runTransaction((transaction) async {
      final bookDoc = await transaction.get(bookRef);
      if (!bookDoc.exists) {
        throw Exception('Book not found');
      }

      final bookData = bookDoc.data()!;
      if (bookData['borrowedBy'] != userId) {
        throw Exception('Book was not borrowed by this user');
      }

      final dueDate = DateTime.fromMillisecondsSinceEpoch(bookData['dueDate']);
      final now = DateTime.now();

      // Update book status
      transaction.update(bookRef, {
        'status': 'available',
        'borrowedBy': null,
        'borrowedAt': null,
        'dueDate': null,
        'returnedAt': now.millisecondsSinceEpoch,
      });

      // Update user's borrowed books
      final userDoc = await transaction.get(userRef);
      final borrowedBooks = List<String>.from(userDoc.data()!['borrowedBooks']);
      borrowedBooks.remove(bookId);
      transaction.update(userRef, {
        'borrowedBooks': borrowedBooks,
      });

      // Handle points for early/late return
      if (now.isBefore(dueDate)) {
        final daysEarly = dueDate.difference(now).inDays;
        await _gamification.awardReturnPoints(userId, daysEarly);
      } else if (now.isAfter(dueDate)) {
        await _gamification.resetStreak(userId);
      }
    });
  }

  // Get borrowed books with due dates
  Stream<List<Map<String, dynamic>>> getBorrowedBooks(String userId) {
    return _firestore
        .collection('books')
        .where('borrowedBy', isEqualTo: userId)
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

  // Check if user can borrow more books
  Future<bool> canBorrowMore(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;

    final userData = userDoc.data()!;
    final borrowedBooks = List<String>.from(userData['borrowedBooks'] ?? []);
    final userLevel = userData['level'] ?? 1;

    return borrowedBooks.length < _gamification.getMaxBooksAllowed(userLevel);
  }

  // Get remaining days for a borrowed book
  int getRemainingDays(int dueDateMillis) {
    final dueDate = DateTime.fromMillisecondsSinceEpoch(dueDateMillis);
    final now = DateTime.now();
    return dueDate.difference(now).inDays;
  }

  // Update borrowed date to make a book overdue
  Future<void> makeBookOverdue(String bookId, int daysOverdue) async {
    final bookRef = _firestore.collection('books').doc(bookId);
    final now = DateTime.now();
    final overdueDate = now.subtract(Duration(days: 14 + daysOverdue)); // 14 days is the normal borrowing period
    final dueDate = overdueDate.add(const Duration(days: 14)); // Due date is 14 days after borrowing
    
    await bookRef.update({
      'borrowedAt': overdueDate.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'status': 'borrowed',
      'borrowedBy': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  // Update due dates for multiple books
  Future<void> updateDueDates() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get the "Flow" book
      final flowBook = await _firestore
          .collection('books')
          .where('title', isEqualTo: 'Flow')
          .get();

      // Get a test book (first available book)
      final testBook = await _firestore
          .collection('books')
          .where('title', isNotEqualTo: 'Flow')
          .limit(1)
          .get();

      if (flowBook.docs.isNotEmpty) {
        await makeBookOverdue(flowBook.docs.first.id, 3); // 3 days overdue
        print('Updated "Flow" book to be 3 days overdue');
      }

      if (testBook.docs.isNotEmpty) {
        await makeBookOverdue(testBook.docs.first.id, 1); // 1 day overdue
        print('Updated test book to be 1 day overdue');
      }
    } catch (e) {
      print('Error updating due dates: $e');
    }
  }

  // Helper: Migrate all books to use 'status' field
  Future<void> migrateBooksToStatus() async {
    final books = await _firestore.collection('books').get();
    for (var doc in books.docs) {
      final data = doc.data();
      if (data['status'] == null) {
        final status = data['available'] == true ? 'available' : 'borrowed';
        await doc.reference.update({'status': status});
        print('Migrated book ${doc.id} to status: $status');
      }
    }
  }
} 