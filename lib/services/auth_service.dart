import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libmu/models/user_model.dart';
import 'package:libmu/models/professor_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get firebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> isAdmin() async {
    if (firebaseUser == null) return false;
    final doc = await _firestore.collection('users').doc(firebaseUser!.uid).get();
    return doc.data()?['isAdmin'] ?? false;
  }

  Stream<bool> get adminStatus {
    if (firebaseUser == null) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(firebaseUser!.uid)
        .snapshots()
        .map((doc) => doc.data()?['isAdmin'] ?? false);
  }

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create a new document for the user in Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'name': '',
        'studentId': '',
        'department': '',
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String department,
    bool isProfessor = false,
    String? facultyId,
    String? designation,
    List<String>? researchAreas,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (isProfessor) {
        // Create professor document in Firestore
        await _firestore.collection('professors').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
          'department': department,
          'facultyId': facultyId,
          'isAdmin': false,
          'borrowedBooks': [],
          'lastBookReturn': null,
          'genreStats': {},
          'researchAreas': researchAreas ?? [],
          'designation': designation ?? 'Assistant Professor',
          'accountType': 'professor',
        });
      } else {
        // Create student document in Firestore with initial gamification data
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'studentId': studentId,
        'department': department,
        'isAdmin': false,
        'borrowedBooks': [],
        'points': 0,
        'level': 1,
        'badges': [],
        'consecutiveReturns': 0,
        'genreStats': {},
        'lastBookReturn': null,
          'accountType': 'student',
      });
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user has gamification data, if not initialize it
      await initializeGamificationData(credential.user!.uid);

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Stream<dynamic> getUserData(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data()!;
            if (data['accountType'] == 'professor') {
              return ProfessorModel.fromMap(data);
            }
            return UserModel.fromMap(data);
          }
          return null;
        });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Initialize gamification data for existing user
  Future<void> initializeGamificationData(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    if (!data.containsKey('points')) {
      await _firestore.collection('users').doc(uid).update({
        'points': 0,
        'level': 1,
        'badges': [],
        'consecutiveReturns': 0,
        'genreStats': {},
        'lastBookReturn': null,
      });
    }
  }

  // Check if user is a professor
  Future<bool> isProfessor() async {
    if (firebaseUser == null) return false;
    final doc = await _firestore.collection('professors').doc(firebaseUser!.uid).get();
    return doc.exists;
  }

  // Get professor data
  Stream<ProfessorModel?> getProfessorData(String uid) {
    return _firestore
        .collection('professors')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? ProfessorModel.fromMap(doc.data()!) : null);
  }

  // Update professor data
  Future<void> updateProfessor(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('professors').doc(uid).update(data);
  }
} 