class UserModel {
  final String uid;
  final String email;
  final String name;
  final String studentId;
  final String department;
  final bool isAdmin;
  final List<String> borrowedBooks;
  final int points;
  final int level;
  final List<String> badges;
  final int consecutiveReturns;
  final Map<String, int> genreStats;
  final DateTime? lastBookReturn;
  final String accountType;
  final String? facultyId;
  final String? designation;
  final List<String> researchAreas;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.studentId,
    required this.department,
    required this.isAdmin,
    required this.borrowedBooks,
    this.points = 0,
    this.level = 1,
    this.badges = const [],
    this.consecutiveReturns = 0,
    this.genreStats = const {},
    this.lastBookReturn,
    this.accountType = 'student',
    this.facultyId,
    this.designation,
    this.researchAreas = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'studentId': studentId,
      'department': department,
      'isAdmin': isAdmin,
      'borrowedBooks': borrowedBooks,
      'points': points,
      'level': level,
      'badges': badges,
      'consecutiveReturns': consecutiveReturns,
      'genreStats': genreStats,
      'lastBookReturn': lastBookReturn?.millisecondsSinceEpoch,
      'accountType': accountType,
      'facultyId': facultyId,
      'designation': designation,
      'researchAreas': researchAreas,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      studentId: map['studentId'] ?? '',
      department: map['department'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      borrowedBooks: List<String>.from(map['borrowedBooks'] ?? []),
      points: map['points'] ?? 0,
      level: map['level'] ?? 1,
      badges: List<String>.from(map['badges'] ?? []),
      consecutiveReturns: map['consecutiveReturns'] ?? 0,
      genreStats: Map<String, int>.from(map['genreStats'] ?? {}),
      lastBookReturn: map['lastBookReturn'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastBookReturn'])
          : null,
      accountType: map['accountType'] ?? 'student',
      facultyId: map['facultyId'],
      designation: map['designation'],
      researchAreas: List<String>.from(map['researchAreas'] ?? []),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? studentId,
    String? department,
    bool? isAdmin,
    List<String>? borrowedBooks,
    int? points,
    int? level,
    List<String>? badges,
    int? consecutiveReturns,
    Map<String, int>? genreStats,
    DateTime? lastBookReturn,
    String? accountType,
    String? facultyId,
    String? designation,
    List<String>? researchAreas,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      isAdmin: isAdmin ?? this.isAdmin,
      borrowedBooks: borrowedBooks ?? this.borrowedBooks,
      points: points ?? this.points,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      consecutiveReturns: consecutiveReturns ?? this.consecutiveReturns,
      genreStats: genreStats ?? this.genreStats,
      lastBookReturn: lastBookReturn ?? this.lastBookReturn,
      accountType: accountType ?? this.accountType,
      facultyId: facultyId ?? this.facultyId,
      designation: designation ?? this.designation,
      researchAreas: researchAreas ?? this.researchAreas,
    );
  }
} 