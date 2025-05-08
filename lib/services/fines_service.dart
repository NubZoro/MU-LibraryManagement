import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libmu/models/book.dart';

class FinesService {
  static const int FINE_PER_DAY = 50; // 50 INR per day
  static const int GRACE_PERIOD_DAYS = 3; // 3 days grace period before fines start

  Future<Map<String, dynamic>> calculateFines(String userId) async {
    final now = DateTime.now();
    final books = await FirebaseFirestore.instance
        .collection('books')
        .where('borrowedBy', isEqualTo: userId)
        .get();

    double totalFines = 0;
    List<Map<String, dynamic>> overdueBooks = [];

    for (var doc in books.docs) {
      final data = doc.data();
      final borrowedAt = data['borrowedAt'] as Timestamp?;
      final dueDate = data['dueDate'] as Timestamp?;

      if (borrowedAt != null && dueDate != null) {
        final dueDateTime = dueDate.toDate();
        final daysOverdue = now.difference(dueDateTime).inDays;

        if (daysOverdue > GRACE_PERIOD_DAYS) {
          final fineDays = daysOverdue - GRACE_PERIOD_DAYS;
          final fineAmount = fineDays * FINE_PER_DAY;
          totalFines += fineAmount;

          overdueBooks.add({
            'book': Book.fromFirestore(doc),
            'borrowedDate': borrowedAt.toDate(),
            'dueDate': dueDateTime,
            'daysOverdue': daysOverdue,
            'fineAmount': fineAmount,
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