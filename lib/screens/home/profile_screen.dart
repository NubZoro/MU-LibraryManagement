import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libmu/models/user_model.dart';
import 'package:libmu/services/auth_service.dart';
import 'package:provider/provider.dart';

class HomeProfileScreen extends StatelessWidget {
  const HomeProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.firebaseUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view profile'));
    }

    return StreamBuilder<UserModel?>(
      stream: authService.getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${userData.name}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Email: ${userData.email}',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text('Student ID: ${userData.studentId}',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text('Department: ${userData.department}',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      // Do not show any error SnackBar for technical errors
                    }
                  }
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editProfile(
      BuildContext context, Map<String, dynamic> userData) async {
    final nameController = TextEditingController(text: userData['name']);
    final studentIdController =
        TextEditingController(text: userData['studentId']);
    final departmentController =
        TextEditingController(text: userData['department']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: studentIdController,
              decoration: const InputDecoration(labelText: 'Student ID'),
            ),
            TextField(
              controller: departmentController,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                final user = authService.firebaseUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'name': nameController.text,
                    'studentId': studentIdController.text,
                    'department': departmentController.text,
                  });
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  // Do not show any error SnackBar for technical errors
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 