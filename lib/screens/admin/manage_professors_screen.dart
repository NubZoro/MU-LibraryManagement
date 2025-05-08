import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libmu/models/professor_model.dart';
import 'package:libmu/services/auth_service.dart';
import 'package:provider/provider.dart';

class ManageProfessorsScreen extends StatefulWidget {
  const ManageProfessorsScreen({Key? key}) : super(key: key);

  @override
  _ManageProfessorsScreenState createState() => _ManageProfessorsScreenState();
}

class _ManageProfessorsScreenState extends State<ManageProfessorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Professors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProfessorDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search professors...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('professors').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final professors = snapshot.data!.docs
                    .map((doc) => ProfessorModel.fromMap(doc.data() as Map<String, dynamic>))
                    .where((professor) =>
                        professor.name.toLowerCase().contains(_searchQuery) ||
                        professor.department.toLowerCase().contains(_searchQuery) ||
                        professor.facultyId.toLowerCase().contains(_searchQuery))
                    .toList();

                if (professors.isEmpty) {
                  return const Center(
                    child: Text('No professors found'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: professors.length,
                  itemBuilder: (context, index) {
                    final professor = professors[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(professor.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${professor.designation} - ${professor.department}'),
                            Text('Faculty ID: ${professor.facultyId}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditProfessorDialog(context, professor);
                            } else if (value == 'delete') {
                              _showDeleteConfirmationDialog(context, professor);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProfessorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final departmentController = TextEditingController();
    final facultyIdController = TextEditingController();
    final designationController = TextEditingController();
    final researchAreasController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Professor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              TextField(
                controller: facultyIdController,
                decoration: const InputDecoration(labelText: 'Faculty ID'),
              ),
              TextField(
                controller: designationController,
                decoration: const InputDecoration(labelText: 'Designation'),
              ),
              TextField(
                controller: researchAreasController,
                decoration: const InputDecoration(
                  labelText: 'Research Areas (comma-separated)',
                ),
              ),
            ],
          ),
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
                await authService.signUp(
                  email: emailController.text,
                  password: 'defaultPassword123', // You might want to implement a better way to set initial password
                  name: nameController.text,
                  department: departmentController.text,
                  studentId: '', // Empty string since it's not needed for professors
                  isProfessor: true,
                  facultyId: facultyIdController.text,
                  designation: designationController.text,
                  researchAreas: researchAreasController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Professor added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditProfessorDialog(BuildContext context, ProfessorModel professor) {
    final nameController = TextEditingController(text: professor.name);
    final departmentController = TextEditingController(text: professor.department);
    final facultyIdController = TextEditingController(text: professor.facultyId);
    final designationController = TextEditingController(text: professor.designation);
    final researchAreasController = TextEditingController(
      text: professor.researchAreas.join(', '),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Professor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              TextField(
                controller: facultyIdController,
                decoration: const InputDecoration(labelText: 'Faculty ID'),
              ),
              TextField(
                controller: designationController,
                decoration: const InputDecoration(labelText: 'Designation'),
              ),
              TextField(
                controller: researchAreasController,
                decoration: const InputDecoration(
                  labelText: 'Research Areas (comma-separated)',
                ),
              ),
            ],
          ),
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
                await authService.updateProfessor(professor.uid, {
                  'name': nameController.text,
                  'department': departmentController.text,
                  'facultyId': facultyIdController.text,
                  'designation': designationController.text,
                  'researchAreas': researchAreasController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Professor updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, ProfessorModel professor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Professor'),
        content: Text('Are you sure you want to delete ${professor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('professors')
                    .doc(professor.uid)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Professor deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 