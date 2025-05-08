import 'package:flutter/material.dart';
import 'package:libmu/models/professor_model.dart';
import 'package:libmu/services/auth_service.dart';
import 'package:provider/provider.dart';

class ProfessorProfileScreen extends StatefulWidget {
  final ProfessorModel professor;

  const ProfessorProfileScreen({
    Key? key,
    required this.professor,
  }) : super(key: key);

  @override
  _ProfessorProfileScreenState createState() => _ProfessorProfileScreenState();
}

class _ProfessorProfileScreenState extends State<ProfessorProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _facultyIdController;
  late TextEditingController _designationController;
  final List<String> _researchAreas = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.professor.name);
    _departmentController = TextEditingController(text: widget.professor.department);
    _facultyIdController = TextEditingController(text: widget.professor.facultyId);
    _designationController = TextEditingController(text: widget.professor.designation);
    _researchAreas.addAll(widget.professor.researchAreas);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _facultyIdController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
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
                            _saveProfile();
                          }
                          setState(() {
                            _isEditing = !_isEditing;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    'Name',
                    _nameController,
                    enabled: _isEditing,
                  ),
                  _buildProfileField(
                    'Department',
                    _departmentController,
                    enabled: _isEditing,
                  ),
                  _buildProfileField(
                    'Faculty ID',
                    _facultyIdController,
                    enabled: _isEditing,
                  ),
                  _buildProfileField(
                    'Designation',
                    _designationController,
                    enabled: _isEditing,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Research Areas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addResearchArea,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _researchAreas.map((area) {
                      return Chip(
                        label: Text(area),
                        onDeleted: _isEditing
                            ? () {
                                setState(() {
                                  _researchAreas.remove(area);
                                });
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Professor Privileges',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivilegeItem(
                    Icons.book,
                    'Borrow up to ${ProfessorModel.MAX_BOOKS_ALLOWED} books',
                  ),
                  _buildPrivilegeItem(
                    Icons.calendar_today,
                    '${ProfessorModel.BORROWING_DURATION_DAYS} days borrowing period',
                  ),
                  _buildPrivilegeItem(
                    Icons.refresh,
                    'Up to ${ProfessorModel.MAX_RENEWALS} renewals per book',
                  ),
                  _buildPrivilegeItem(
                    Icons.priority_high,
                    'Priority reservation',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    TextEditingController controller, {
    bool enabled = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        enabled: enabled,
      ),
    );
  }

  Widget _buildPrivilegeItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _addResearchArea() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Research Area'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Research Area',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _researchAreas.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.updateProfessor(widget.professor.uid, {
        'name': _nameController.text,
        'department': _departmentController.text,
        'facultyId': _facultyIdController.text,
        'designation': _designationController.text,
        'researchAreas': _researchAreas,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );
    } catch (e) {
      // Do not show any error SnackBar for technical errors
    }
  }
} 