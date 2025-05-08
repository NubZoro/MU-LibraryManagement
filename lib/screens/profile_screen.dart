import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libmu/models/user_model.dart';
import 'package:libmu/services/gamification_service.dart';
import 'package:libmu/widgets/progress_dashboard.dart';
import 'package:libmu/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:libmu/widgets/animated_gradient_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _departmentController;
  late TextEditingController _designationController;
  List<String> _researchAreas = [];
  String _newResearchArea = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _idController = TextEditingController();
    _departmentController = TextEditingController();
    _designationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(UserModel userData) async {
    try {
      Map<String, dynamic> updateData = {
        'name': _nameController.text,
        'department': _departmentController.text,
      };

      if (userData.accountType == 'professor') {
        updateData.addAll({
          'facultyId': _idController.text,
          'designation': _designationController.text,
          'researchAreas': _researchAreas,
        });
      } else {
        updateData['studentId'] = _idController.text;
      }

      await FirebaseFirestore.instance.collection('users').doc(userData.uid).update(updateData);

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addResearchArea() {
    if (_newResearchArea.isNotEmpty) {
      setState(() {
        _researchAreas.add(_newResearchArea);
        _newResearchArea = '';
      });
    }
  }

  void _removeResearchArea(String area) {
    setState(() {
      _researchAreas.remove(area);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.firebaseUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view profile'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.9),
        elevation: 0,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = UserModel.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
          );

          // Update controllers with current values
          _nameController.text = userData.name;
          _idController.text = userData.accountType == 'professor' 
              ? userData.facultyId ?? ''
              : userData.studentId;
          _departmentController.text = userData.department;
          if (userData.accountType == 'professor') {
            _designationController.text = userData.designation ?? '';
            _researchAreas = List<String>.from(userData.researchAreas);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profile Information',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: Icon(_isEditing ? Icons.save : Icons.edit),
                              onPressed: () {
                                if (_isEditing) {
                                  _saveProfile(userData);
                                } else {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                userData.name.isNotEmpty 
                                    ? userData.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _isEditing
                                      ? TextField(
                                          controller: _nameController,
                                          decoration: const InputDecoration(
                                            labelText: 'Name',
                                            border: OutlineInputBorder(),
                                          ),
                                        )
                                      : Text(
                                          userData.name,
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userData.email,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _InfoItem(
                              icon: userData.accountType == 'professor' ? Icons.badge : Icons.school,
                              label: userData.accountType == 'professor' ? 'Faculty ID' : 'Student ID',
                              value: _isEditing
                                  ? TextField(
                                      controller: _idController,
                                      decoration: InputDecoration(
                                        labelText: userData.accountType == 'professor' ? 'Faculty ID' : 'Student ID',
                                        border: const OutlineInputBorder(),
                                      ),
                                    )
                                  : userData.accountType == 'professor' ? userData.facultyId : userData.studentId,
                            ),
                            _InfoItem(
                              icon: Icons.business,
                              label: 'Department',
                              value: _isEditing
                                  ? TextField(
                                      controller: _departmentController,
                                      decoration: const InputDecoration(
                                        labelText: 'Department',
                                        border: OutlineInputBorder(),
                                      ),
                                    )
                                  : userData.department,
                            ),
                            _InfoItem(
                              icon: Icons.book,
                              label: 'Books',
                              value: userData.borrowedBooks.length.toString(),
                            ),
                          ],
                        ),
                        if (userData.accountType == 'professor') ...[
                          const SizedBox(height: 16),
                          _InfoItem(
                            icon: Icons.work,
                            label: 'Designation',
                            value: _isEditing
                                ? TextField(
                                    controller: _designationController,
                                    decoration: const InputDecoration(
                                      labelText: 'Designation',
                                      border: OutlineInputBorder(),
                                    ),
                                  )
                                : userData.designation,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Research Areas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_isEditing) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Add Research Area',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => _newResearchArea = value,
                                    onSubmitted: (_) => _addResearchArea(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _addResearchArea,
                                ),
                              ],
                            ),
                          ],
                          Wrap(
                            spacing: 8,
                            children: _researchAreas.map((area) {
                              return Chip(
                                label: Text(area),
                                onDeleted: _isEditing ? () => _removeResearchArea(area) : null,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Progress Dashboard (only for students)
                if (userData.accountType != 'professor')
                  ProgressDashboard(user: userData),

                // Privileges Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Privileges',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (userData.accountType == 'professor') ...[
                          _PrivilegeItem(
                            icon: Icons.book,
                            title: 'Maximum Books',
                            value: '15 books',
                          ),
                          const SizedBox(height: 12),
                          _PrivilegeItem(
                            icon: Icons.timer,
                            title: 'Borrowing Duration',
                            value: '60 days',
                          ),
                          const SizedBox(height: 12),
                          _PrivilegeItem(
                            icon: Icons.priority_high,
                            title: 'Priority Reservation',
                            value: 'Available',
                          ),
                          const SizedBox(height: 12),
                          _PrivilegeItem(
                            icon: Icons.repeat,
                            title: 'Book Renewals',
                            value: '3 renewals per book',
                          ),
                        ] else ...[
                          _PrivilegeItem(
                            icon: Icons.book,
                            title: 'Maximum Books',
                            value: '${GamificationService().getMaxBooksAllowed(userData.level)} books',
                          ),
                          const SizedBox(height: 12),
                          _PrivilegeItem(
                            icon: Icons.timer,
                            title: 'Borrowing Duration',
                            value: '${GamificationService().getBorrowingDuration(userData.level)} days',
                          ),
                          const SizedBox(height: 12),
                          _PrivilegeItem(
                            icon: Icons.priority_high,
                            title: 'Priority Reservation',
                            value: GamificationService().hasPriorityReservation(userData.level)
                                ? 'Available'
                                : 'Unlock at Scholar level',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        value is Widget
            ? value
            : Text(
                value.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
      ],
    );
  }
}

class _PrivilegeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _PrivilegeItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 