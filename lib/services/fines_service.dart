import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libmu/models/book.dart';

class FinesService {
  static const double FINE_PER_DAY = 50.0; // 50 INR per day

  Future<Map<String, dynamic>> calculateFines(String userId) async {
    final now = DateTime.now();
    final books = await FirebaseFirestore.instance
        .collection('books')
        .where('borrowedBy', isEqualTo: userId)
        .get();

    double totalFines = 0.0;
    List<Map<String, dynamic>> overdueBooks = [];

    for (var doc in books.docs) {
      final data = doc.data();
      final dueDateRaw = data['dueDate'];
      final borrowedAtRaw = data['borrowedAt'];
      
      DateTime? dueDate;
      DateTime? borrowedAt;
      
      // Parse borrowedAt
      if (borrowedAtRaw != null) {
        try {
          if (borrowedAtRaw is int) {
            borrowedAt = DateTime.fromMillisecondsSinceEpoch(borrowedAtRaw);
          } else if (borrowedAtRaw is Timestamp) {
            borrowedAt = borrowedAtRaw.toDate();
          } else if (borrowedAtRaw is String) {
            borrowedAt = DateTime.parse(borrowedAtRaw);
          }
        } catch (e) {
          print('Error parsing borrowedAt in fines service: $e');
        }
      }

      // Parse dueDate
      if (dueDateRaw != null) {
        try {
          if (dueDateRaw is int) {
            dueDate = DateTime.fromMillisecondsSinceEpoch(dueDateRaw);
          } else if (dueDateRaw is Timestamp) {
            dueDate = dueDateRaw.toDate();
          } else if (dueDateRaw is String) {
            dueDate = DateTime.parse(dueDateRaw);
          }
        } catch (e) {
          print('Error parsing dueDate in fines service: $e');
        }
      }

      // If dates are missing, try to get them from the Book model
      if (borrowedAt == null || dueDate == null) {
        final book = Book.fromFirestore(doc);
        borrowedAt ??= book.borrowedAt;
        dueDate ??= book.getDueDate();
      }

      if (dueDate != null) {
        if (dueDate.isBefore(now)) {
          final daysOverdue = now.difference(dueDate).inDays;
          // Calculate fine: ₹50 per day overdue
          final fineAmount = daysOverdue * FINE_PER_DAY;
          totalFines += fineAmount;

          overdueBooks.add({
            'book': Book.fromFirestore(doc),
            'dueDate': dueDate,
            'daysOverdue': daysOverdue,
            'fineAmount': fineAmount.toDouble(), // Ensure it's a double
          });
        }
      }
    }

    return {
      'totalFines': totalFines,
      'overdueBooks': overdueBooks,
    };
  }

  Future<void> payFines(String userId, double amount) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'finesPaid': FieldValue.increment(amount),
      'lastFinePayment': FieldValue.serverTimestamp(),
    });
  }
} 