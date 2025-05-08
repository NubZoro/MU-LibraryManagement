import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessorModel {
  final String uid;
  final String email;
  final String name;
  final String department;
  final String facultyId;
  final bool isAdmin;
  final List<String> borrowedBooks;
  final DateTime? lastBookReturn;
  final Map<String, int> genreStats;
  final List<String> researchAreas;
  final String designation; // e.g., "Assistant Professor", "Associate Professor", "Professor"

  // Professor-specific privileges
  static const int MAX_BOOKS_ALLOWED = 15;
  static const int BORROWING_DURATION_DAYS = 60;
  static const bool HAS_PRIORITY_RESERVATION = true;
  static const bool CAN_RENEW_MULTIPLE_TIMES = true;
  static const int MAX_RENEWALS = 3;

  ProfessorModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.department,
    required this.facultyId,
    this.isAdmin = false,
    this.borrowedBooks = const [],
    this.lastBookReturn,
    this.genreStats = const {},
    this.researchAreas = const [],
    required this.designation,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'department': department,
      'facultyId': facultyId,
      'isAdmin': isAdmin,
      'borrowedBooks': borrowedBooks,
      'lastBookReturn': lastBookReturn?.millisecondsSinceEpoch,
      'genreStats': genreStats,
      'researchAreas': researchAreas,
      'designation': designation,
      'accountType': 'professor', // To distinguish from student accounts
    };
  }

  factory ProfessorModel.fromMap(Map<String, dynamic> map) {
    return ProfessorModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      facultyId: map['facultyId'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      borrowedBooks: List<String>.from(map['borrowedBooks'] ?? []),
      lastBookReturn: map['lastBookReturn'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastBookReturn'])
          : null,
      genreStats: Map<String, int>.from(map['genreStats'] ?? {}),
      researchAreas: List<String>.from(map['researchAreas'] ?? []),
      designation: map['designation'] ?? '',
    );
  }

  ProfessorModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? department,
    String? facultyId,
    bool? isAdmin,
    List<String>? borrowedBooks,
    DateTime? lastBookReturn,
    Map<String, int>? genreStats,
    List<String>? researchAreas,
    String? designation,
  }) {
    return ProfessorModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      department: department ?? this.department,
      facultyId: facultyId ?? this.facultyId,
      isAdmin: isAdmin ?? this.isAdmin,
      borrowedBooks: borrowedBooks ?? this.borrowedBooks,
      lastBookReturn: lastBookReturn ?? this.lastBookReturn,
      genreStats: genreStats ?? this.genreStats,
      researchAreas: researchAreas ?? this.researchAreas,
      designation: designation ?? this.designation,
    );
  }
} 