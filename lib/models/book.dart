import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  // Lending Rules Constants
  static const int maxBooksPerUser = 5;
  static const int loanDurationDays = 14;
  static const double overdueFineDailyRateInr = 100.0;

  final String id;
  final String title;
  final String author;
  final bool available;
  final String? borrowedBy;
  final DateTime? borrowedAt;
  final String? genre;
  final String? category;
  final String? isbn;
  final String? imageUrl;
  final String? summary;
  final List<Map<String, dynamic>> reviews;
  final double averageRating;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.available,
    this.borrowedBy,
    this.borrowedAt,
    this.genre,
    this.category,
    this.isbn,
    this.imageUrl,
    this.summary,
    this.reviews = const [],
    this.averageRating = 0.0,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime? borrowedAt;
    if (data['borrowedAt'] != null) {
      if (data['borrowedAt'] is int) {
        borrowedAt = DateTime.fromMillisecondsSinceEpoch(data['borrowedAt']);
      } else if (data['borrowedAt'] is Timestamp) {
        borrowedAt = data['borrowedAt'].toDate();
      }
    }
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      available: data['available'] ?? true,
      borrowedBy: data['borrowedBy'],
      borrowedAt: borrowedAt,
      genre: data['genre'],
      category: data['category'],
      isbn: data['isbn'],
      imageUrl: data['imageUrl'],
      summary: data['summary'],
      reviews: List<Map<String, dynamic>>.from(data['reviews'] ?? []),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'available': available,
      'borrowedBy': borrowedBy,
      'borrowedAt': borrowedAt,
      'genre': genre,
      'category': category,
      'isbn': isbn,
      'imageUrl': imageUrl,
      'summary': summary,
      'reviews': reviews,
      'averageRating': averageRating,
    };
  }

  // Calculate due date for a borrowed book
  DateTime? getDueDate() {
    if (borrowedAt == null) return null;
    return borrowedAt!.add(Duration(days: loanDurationDays));
  }

  // Calculate remaining days before due
  int? getRemainingDays() {
    if (borrowedAt == null) return null;
    final dueDate = getDueDate()!;
    final today = DateTime.now();
    return dueDate.difference(today).inDays;
  }

  // Calculate overdue days
  int? getOverdueDays() {
    if (borrowedAt == null) return null;
    final dueDate = getDueDate()!;
    final today = DateTime.now();
    if (today.isBefore(dueDate)) return 0;
    return today.difference(dueDate).inDays;
  }

  // Calculate overdue fine if any
  double? getOverdueFine() {
    final overdueDays = getOverdueDays();
    if (overdueDays == null || overdueDays <= 0) return 0;
    return overdueDays * overdueFineDailyRateInr;
  }

  // Check if book is overdue
  bool isOverdue() {
    if (borrowedAt == null) return false;
    final dueDate = getDueDate()!;
    return DateTime.now().isAfter(dueDate);
  }

  // Get loan status information
  Map<String, dynamic> getLoanStatus() {
    if (!available || borrowedAt == null) {
      return {
        'isOverdue': false,
        'remainingDays': 0,
        'overdueDays': 0,
        'dueDate': null,
      };
    }

    final dueDate = borrowedAt!.add(Duration(days: loanDurationDays));
    final now = DateTime.now();
    final remainingDays = dueDate.difference(now).inDays;
    final isOverdue = remainingDays < 0;

    return {
      'isOverdue': isOverdue,
      'remainingDays': isOverdue ? 0 : remainingDays,
      'overdueDays': isOverdue ? -remainingDays : 0,
      'dueDate': dueDate,
    };
  }
} 