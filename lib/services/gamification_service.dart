import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libmu/models/user_model.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Points constants
  static const int BORROW_POINTS = 50;
  static const int EARLY_RETURN_POINTS = 25;
  static const int STREAK_BONUS = 20;
  static const int GENRE_EXPLORATION_BONUS = 30;

  // Level thresholds (points needed for each level)
  static const Map<int, int> LEVEL_THRESHOLDS = {
    1: 0,      // Freshman
    2: 200,    // Sophomore
    3: 500,    // Junior
    4: 1000,   // Senior
    5: 2000,   // Scholar
    6: 3500,   // Master
    7: 5000,   // Grand Master
  };

  // Badge definitions
  static const String FIRST_TIME_BORROWER = 'First-Time Borrower';
  static const String BOOKWORM = 'Bookworm';
  static const String SPEED_READER = 'Speed Reader';
  static const String GENRE_EXPLORER = 'Genre Explorer';
  static const String PERFECT_RECORD = 'Perfect Record';
  static const String ACADEMIC_EXCELLENCE = 'Academic Excellence';

  // Calculate level based on points
  int calculateLevel(int points) {
    int level = 1;
    for (var entry in LEVEL_THRESHOLDS.entries) {
      if (points >= entry.value) {
        level = entry.key;
      } else {
        break;
      }
    }
    return level;
  }

  // Award points for borrowing a book
  Future<void> awardBorrowPoints(String userId, String bookGenre) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final user = UserModel.fromMap(userDoc.data()!);
      
      int newPoints = user.points + BORROW_POINTS;
      
      // Update genre stats and check for Genre Explorer badge
      Map<String, int> newGenreStats = Map.from(user.genreStats);
      newGenreStats[bookGenre] = (newGenreStats[bookGenre] ?? 0) + 1;
      
      List<String> newBadges = List.from(user.badges);
      
      // First-Time Borrower badge
      if (user.borrowedBooks.isEmpty && !newBadges.contains(FIRST_TIME_BORROWER)) {
        newBadges.add(FIRST_TIME_BORROWER);
      }
      
      // Bookworm badge
      if (user.borrowedBooks.length >= 9 && !newBadges.contains(BOOKWORM)) {
        newBadges.add(BOOKWORM);
      }
      
      // Genre Explorer badge
      if (newGenreStats.length >= 5 && !newBadges.contains(GENRE_EXPLORER)) {
        newBadges.add(GENRE_EXPLORER);
        newPoints += GENRE_EXPLORATION_BONUS;
      }

      // Calculate new level
      int newLevel = calculateLevel(newPoints);
      
      transaction.update(userRef, {
        'points': newPoints,
        'level': newLevel,
        'badges': newBadges,
        'genreStats': newGenreStats,
      });
    });
  }

  // Award points for returning a book early
  Future<void> awardReturnPoints(String userId, int daysEarly) async {
    if (daysEarly <= 0) return;

    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final user = UserModel.fromMap(userDoc.data()!);
      
      int earlyReturnPoints = daysEarly * EARLY_RETURN_POINTS;
      int streakBonus = user.consecutiveReturns * STREAK_BONUS;
      int newPoints = user.points + earlyReturnPoints + streakBonus;
      
      List<String> newBadges = List.from(user.badges);
      
      // Speed Reader badge
      if (daysEarly >= 3 && !newBadges.contains(SPEED_READER)) {
        newBadges.add(SPEED_READER);
      }
      
      // Perfect Record badge
      if (user.consecutiveReturns >= 5 && !newBadges.contains(PERFECT_RECORD)) {
        newBadges.add(PERFECT_RECORD);
      }

      // Calculate new level
      int newLevel = calculateLevel(newPoints);
      
      transaction.update(userRef, {
        'points': newPoints,
        'level': newLevel,
        'badges': newBadges,
        'consecutiveReturns': user.consecutiveReturns + 1,
        'lastBookReturn': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  // Reset streak if book is returned late
  Future<void> resetStreak(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'consecutiveReturns': 0,
    });
  }

  // Get maximum allowed books based on level
  int getMaxBooksAllowed(int level) {
    if (level == 7) return 10; // Grand Master level gets 10 books
    return level + 2; // Base of 3 books at level 1, increasing by 1 per level
  }

  // Get borrowing duration in days based on level
  int getBorrowingDuration(int level) {
    if (level == 7) return 30; // Grand Master level gets 30 days
    return 14 + ((level - 1) * 2); // Base of 14 days, increasing by 2 days per level
  }

  // Check if user has priority reservation privilege
  bool hasPriorityReservation(int level) {
    return level >= 5; // Scholar level and above get priority reservation
  }
} 