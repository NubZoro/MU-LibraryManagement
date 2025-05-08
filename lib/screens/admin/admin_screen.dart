import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/book.dart';
import '../../services/book_service.dart';
import '../../services/qr_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'manage_students_screen.dart';
import 'manage_professors_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final BookService _bookService = BookService();
  final QRService _qrService = QRService();
  final TextEditingController _copiesController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _categoryController.dispose();
    _summaryController.dispose();
    _imageUrlController.dispose();
    _copiesController.dispose();
    super.dispose();
  }

  Future<void> _addBook() async {
    try {
      // Add the book to Firestore
      final docRef = await FirebaseFirestore.instance.collection('books').add({
        'title': _titleController.text,
        'author': _authorController.text,
        'isbn': _isbnController.text,
        'category': _categoryController.text,
        'available': true,
        'addedAt': FieldValue.serverTimestamp(),
        'reviews': [],
        'averageRating': 0.0,
      });

      // Generate QR codes for each copy
      final numCopies = int.tryParse(_copiesController.text) ?? 1;
      for (int i = 0; i < numCopies; i++) {
        await _qrService.generateQRCode(docRef.id);
      }

      _titleController.clear();
      _authorController.clear();
      _isbnController.clear();
      _categoryController.clear();
      _copiesController.text = '1';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book and QR codes added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding book: $e')),
        );
      }
    }
  }

  Future<void> _deleteBook(String bookId) async {
    try {
      await FirebaseFirestore.instance.collection('books').doc(bookId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting book: $e')),
      );
    }
  }

  Future<void> _editBook(Book book) async {
    try {
      await FirebaseFirestore.instance.collection('books').doc(book.id).update({
        'title': _titleController.text,
        'author': _authorController.text,
        'isbn': _isbnController.text,
        'category': _categoryController.text,
        'summary': _summaryController.text,
        'imageUrl': _imageUrlController.text,
      });

      _titleController.clear();
      _authorController.clear();
      _isbnController.clear();
      _categoryController.clear();
      _summaryController.clear();
      _imageUrlController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating book: $e')),
      );
    }
  }

  Future<void> _updateDueDates() async {
    try {
      await _bookService.updateDueDates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Due dates updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating due dates: $e')),
      );
    }
  }

  void _showEditDialog(Book book) {
    _titleController.text = book.title;
    _authorController.text = book.author;
    _isbnController.text = book.isbn ?? '';
    _categoryController.text = book.category ?? '';
    _summaryController.text = book.summary ?? '';
    _imageUrlController.text = book.imageUrl ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Book'),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _isbnController,
                decoration: const InputDecoration(
                  labelText: 'ISBN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            TextField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
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
            onPressed: () {
                  Navigator.pop(context);
              _editBook(book);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalFines(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .where('borrowedBy', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final books = snapshot.data!.docs;
        double totalFines = 0.0;
        int overdueBooks = 0;

        for (var doc in books) {
          final data = doc.data() as Map<String, dynamic>;
          final dueDateRaw = data['dueDate'];
          final borrowedAtRaw = data['borrowedAt'];
          
          DateTime? dueDate;
          DateTime? borrowedAt;
          
          // Parse borrowedAt
          if (borrowedAtRaw != null) {
            try {
              if (borrowedAtRaw is int) {
                borrowedAt = DateTime.fromMillisecondsSinceEpoch(borrowedAtRaw);
              } else if (borrowedAtRaw is Timestamp) {
                borrowedAt = borrowedAtRaw.toDate();
              } else if (borrowedAtRaw is String) {
                borrowedAt = DateTime.parse(borrowedAtRaw);
              }
            } catch (e) {
              print('Error parsing borrowedAt in total fines: $e');
            }
          }

          // Parse dueDate
          if (dueDateRaw != null) {
            try {
              if (dueDateRaw is int) {
                dueDate = DateTime.fromMillisecondsSinceEpoch(dueDateRaw);
              } else if (dueDateRaw is Timestamp) {
                dueDate = dueDateRaw.toDate();
              } else if (dueDateRaw is String) {
                dueDate = DateTime.parse(dueDateRaw);
              }
            } catch (e) {
              print('Error parsing dueDate in total fines: $e');
            }
          }

          // If dates are missing, try to get them from the Book model
          if (borrowedAt == null || dueDate == null) {
            final book = Book.fromFirestore(doc);
            borrowedAt ??= book.borrowedAt;
            dueDate ??= book.getDueDate();
          }

          if (dueDate != null) {
            final now = DateTime.now();
            if (dueDate.isBefore(now)) {
              final daysOverdue = now.difference(dueDate).inDays;
              // Calculate fine: ₹50 per day overdue
              final fine = daysOverdue * 50.0;
              totalFines += fine;
              overdueBooks++;
            }
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Fines: ₹${totalFines.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: totalFines > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (overdueBooks > 0)
                  Text(
                    '$overdueBooks book${overdueBooks > 1 ? 's' : ''} overdue',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                if (totalFines > 0)
                  const Text(
                    'Fine rate: ₹50 per day per book',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBorrowedBooksList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .where('borrowedBy', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final books = snapshot.data!.docs;

        if (books.isEmpty) {
          return const Text('No books borrowed');
        }

        return Column(
          children: books.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final book = Book.fromFirestore(doc);
            
            // Get loan information
            final borrowedAtRaw = data['borrowedAt'];
            final dueDateRaw = data['dueDate'];
            DateTime? borrowedAt;
            DateTime? dueDateTime;
            
            // Parse borrowedAt
            if (borrowedAtRaw != null) {
              try {
                if (borrowedAtRaw is int) {
                  borrowedAt = DateTime.fromMillisecondsSinceEpoch(borrowedAtRaw);
                } else if (borrowedAtRaw is Timestamp) {
                  borrowedAt = borrowedAtRaw.toDate();
                } else if (borrowedAtRaw is String) {
                  borrowedAt = DateTime.parse(borrowedAtRaw);
                }
              } catch (e) {
                print('Error parsing borrowedAt: $e');
              }
            }

            // Parse dueDate
            if (dueDateRaw != null) {
              try {
                if (dueDateRaw is int) {
                  dueDateTime = DateTime.fromMillisecondsSinceEpoch(dueDateRaw);
                } else if (dueDateRaw is Timestamp) {
                  dueDateTime = dueDateRaw.toDate();
                } else if (dueDateRaw is String) {
                  dueDateTime = DateTime.parse(dueDateRaw);
                }
              } catch (e) {
                print('Error parsing dueDate: $e');
              }
            }

            // If we couldn't parse the dates, use the book's built-in methods
            if (borrowedAt == null) {
              borrowedAt = book.borrowedAt;
            }
            if (dueDateTime == null) {
              dueDateTime = book.getDueDate();
            }

            final now = DateTime.now();
            final remainingDays = dueDateTime?.difference(now).inDays ?? 0;
            final isOverdue = remainingDays < 0;
            final fine = isOverdue ? -remainingDays * 50.0 : 0.0; // ₹50 per day overdue

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(book.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Author: ${book.author}'),
                    if (borrowedAt != null)
                      Text('Borrowed: ${borrowedAt.toString().split(' ')[0]}'),
                    if (dueDateTime != null)
                      Text('Due Date: ${dueDateTime.toString().split(' ')[0]}'),
                    Text(
                      isOverdue
                          ? 'Overdue by ${-remainingDays} days'
                          : 'Remaining Days: $remainingDays',
                      style: TextStyle(
                        color: isOverdue || remainingDays <= 3
                            ? Colors.red
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOverdue)
                      Text(
                        'Fine: ₹${fine.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                trailing: Icon(
                  isOverdue ? Icons.warning : Icons.check_circle,
                  color: isOverdue ? Colors.red : Colors.green,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showQRCodeDialog(String qrData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              const Text(
                'Book QR Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 300.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      qrData,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan this QR code to borrow the book',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, String userId, Map<String, dynamic> userData) {
    final nameController = TextEditingController(text: userData['name'] ?? '');
    final departmentController = TextEditingController(text: userData['department'] ?? '');
    final studentIdController = TextEditingController(text: userData['studentId'] ?? '');
    final facultyIdController = TextEditingController(text: userData['facultyId'] ?? '');
    final designationController = TextEditingController(text: userData['designation'] ?? '');
    final researchAreasController = TextEditingController(
      text: (userData['researchAreas'] as List<dynamic>?)?.join(', ') ?? '',
    );
    String accountType = userData['accountType'] ?? 'student';
    bool isProfessor = accountType == 'professor';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
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
                  controller: studentIdController,
                  decoration: const InputDecoration(labelText: 'Student ID'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Account Type: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: accountType,
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Student'),
                        ),
                        DropdownMenuItem(
                          value: 'professor',
                          child: Text('Professor'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            accountType = value;
                            isProfessor = value == 'professor';
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (isProfessor) ...[
                  const SizedBox(height: 16),
                  const Text('Professor Details:'),
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
                    decoration: const InputDecoration(labelText: 'Research Areas (comma-separated)'),
                  ),
                ],
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
                  
                  // Update user document
                  Map<String, dynamic> updateData = {
                    'name': nameController.text,
                    'department': departmentController.text,
                    'accountType': accountType,
                  };

                  if (isProfessor) {
                    updateData.addAll({
                      'facultyId': facultyIdController.text,
                      'designation': designationController.text,
                      'researchAreas': researchAreasController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                    });
                  } else {
                    updateData['studentId'] = studentIdController.text;
                  }

                  await FirebaseFirestore.instance.collection('users').doc(userId).update(updateData);

                  // Handle professor-specific updates
                  if (isProfessor) {
                    final professorData = {
                      'uid': userId,
                      'email': userData['email'],
                      'name': nameController.text,
                      'department': departmentController.text,
                      'facultyId': facultyIdController.text,
                      'designation': designationController.text,
                      'researchAreas': researchAreasController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      'isAdmin': false,
                    };

                    // Create or update professor document
                    await FirebaseFirestore.instance
                        .collection('professors')
                        .doc(userId)
                        .set(professorData);
                  } else {
                    // Remove professor document if converting to student
                    await FirebaseFirestore.instance
                        .collection('professors')
                        .doc(userId)
                        .delete();
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating user: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Add Book'),
            Tab(text: 'Manage Books'),
            Tab(text: 'Manage Students'),
            Tab(text: 'Manage Professors'),
            Tab(text: 'User Management'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.update),
            onPressed: _updateDueDates,
            tooltip: 'Update Due Dates',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Add Book Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _isbnController,
                    decoration: const InputDecoration(
                      labelText: 'ISBN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _summaryController,
                    decoration: const InputDecoration(
                      labelText: 'Summary',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _copiesController,
                    decoration: const InputDecoration(
                      labelText: 'Number of Copies',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addBook,
                    child: const Text('Add Book'),
                  ),
                ],
              ),
            ),
          ),
          // Manage Books Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('books').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final books = snapshot.data!.docs
                  .map((doc) => Book.fromFirestore(doc))
                  .toList();

              if (books.isEmpty) {
                return const Center(child: Text('No books available'));
              }

              return ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: book.imageUrl != null
                              ? Image.network(
                                  book.imageUrl!,
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.book, size: 50),
                                )
                              : const Icon(Icons.book, size: 50),
                          title: Text(book.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Author: ${book.author}'),
                              Text('ISBN: ${book.isbn ?? 'N/A'}'),
                              Text('Category: ${book.category ?? 'N/A'}'),
                              Text('Status: ${book.available ? 'Available' : 'Borrowed'}'),
                              if (book.averageRating > 0)
                                Text('Rating: ${book.averageRating.toStringAsFixed(1)}/5.0'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code),
                                onPressed: () async {
                                  // Show a single QR code for the book's document ID
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                                          maxHeight: MediaQuery.of(context).size.height * 0.9,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'QR Code for ${book.title}',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 16),
                                            QrImageView(
                                              data: book.id,
                                              version: QrVersions.auto,
                                              size: 300.0,
                                              backgroundColor: Colors.white,
                                              eyeStyle: const QrEyeStyle(
                                                eyeShape: QrEyeShape.square,
                                                color: Colors.black,
                                              ),
                                              dataModuleStyle: const QrDataModuleStyle(
                                                dataModuleShape: QrDataModuleShape.square,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SelectableText(
                                              book.id,
                                              style: const TextStyle(fontSize: 12),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                tooltip: 'View QR Code',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(book),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
                                      content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
                                          onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteBook(book.id);
                                          },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
                                },
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          // Manage Students Tab
          const ManageStudentsScreen(),
          // Manage Professors Tab
          const ManageProfessorsScreen(),
          // User Management Tab
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                  final user = users[index];
                  final userData = user.data() as Map<String, dynamic>;
                  
                    return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ExpansionTile(
                      title: Text(userData['email'] ?? 'No email'),
                      subtitle: Text(userData['name'] ?? 'No name'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditUserDialog(context, user.id, userData),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Student ID: ${userData['studentId'] ?? 'N/A'}'),
                              Text('Department: ${userData['department'] ?? 'N/A'}'),
                              Text('Account Type: ${userData['accountType'] ?? 'N/A'}'),
                              const SizedBox(height: 16),
                              const Text(
                                'Borrowed Books:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              _buildBorrowedBooksList(user.id),
                              const SizedBox(height: 16),
                              const Text(
                                'Total Fines:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              _buildTotalFines(user.id),
                            ],
                          ),
                        ),
                      ],
                    ),
                    );
                  },
                );
              },
          ),
        ],
      ),
    );
  }
} 