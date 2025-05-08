import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingList {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> bookIds;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReadingList({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.bookIds,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'bookIds': bookIds,
      'isPublic': isPublic,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ReadingList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReadingList(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      bookIds: List<String>.from(data['bookIds'] ?? []),
      isPublic: data['isPublic'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? 0),
    );
  }

  ReadingList copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    List<String>? bookIds,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      bookIds: bookIds ?? this.bookIds,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 