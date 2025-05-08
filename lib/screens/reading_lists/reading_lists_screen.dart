import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/reading_list.dart';
import '../../models/book.dart';
import 'public_reading_lists_screen.dart';
import '../home/book_search_screen.dart';

class ReadingListsScreen extends StatefulWidget {
  const ReadingListsScreen({Key? key}) : super(key: key);

  @override
  _ReadingListsScreenState createState() => _ReadingListsScreenState();
}

class _ReadingListsScreenState extends State<ReadingListsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isPublic = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createReadingList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your reading list')),
      );
      return;
    }

    try {
      final readingList = ReadingList(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        ownerId: user.uid,
        bookIds: [],
        isPublic: _isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('reading_lists')
          .add(readingList.toMap());

      _nameController.clear();
      _descriptionController.clear();
      setState(() => _isPublic = true);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reading list created successfully')),
        );
      }
    } catch (e) {
      // Do not show any error SnackBar for technical errors
    }
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Reading List'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'List Name',
                  hintText: 'e.g., Physics Books, AI Books, Fantasy Novels',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your reading list',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Public List'),
                  Switch(
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                  ),
                ],
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
            onPressed: _createReadingList,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Reading Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: 'Explore Public Lists',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PublicReadingListsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateListDialog,
            tooltip: 'Create New List',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reading_lists')
            .where('ownerId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final readingLists = snapshot.data!.docs
              .map((doc) => ReadingList.fromFirestore(doc))
              .toList();

          if (readingLists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No reading lists yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreateListDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First List'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: readingLists.length,
            itemBuilder: (context, index) {
              final list = readingLists[index];
              return Card(
                child: ListTile(
                  title: Text(list.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(list.description),
                      const SizedBox(height: 4),
                      Text(
                        '${list.bookIds.length} books • ${list.isPublic ? 'Public' : 'Private'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReadingListDetailScreen(
                            readingList: list,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ReadingListDetailScreen extends StatelessWidget {
  final ReadingList readingList;

  const ReadingListDetailScreen({
    Key? key,
    required this.readingList,
  }) : super(key: key);

  Future<void> _addBookToList(BuildContext context) async {
    try {
      final books = await FirebaseFirestore.instance
          .collection('books')
          .get();

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Book to List'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: books.docs.length,
              itemBuilder: (context, index) {
                final book = Book.fromFirestore(books.docs[index]);
                final isInList = readingList.bookIds.contains(book.id);

                return ListTile(
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  trailing: isInList
                      ? const Icon(Icons.check, color: Colors.green)
                      : IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('reading_lists')
                                .doc(readingList.id)
                                .update({
                              'bookIds': FieldValue.arrayUnion([book.id]),
                              'updatedAt': DateTime.now().millisecondsSinceEpoch,
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Do not show any error SnackBar for technical errors
    }
  }

  Future<void> _removeBookFromList(BuildContext context, String bookId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reading_lists')
          .doc(readingList.id)
          .update({
        'bookIds': FieldValue.arrayRemove([bookId]),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Do not show any error SnackBar for technical errors
    }
  }

  @override
  Widget build(BuildContext context) {
    if (readingList.bookIds.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(readingList.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addBookToList(context),
              tooltip: 'Add Book',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No books in this list yet',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _addBookToList(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Books'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(readingList.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addBookToList(context),
            tooltip: 'Add Book',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .where(FieldPath.documentId, whereIn: readingList.bookIds)
            .snapshots(),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No books in this list yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _addBookToList(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Books'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                child: ListTile(
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
                      Text(book.author),
                      Text('Category: ${book.category ?? 'N/A'}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeBookFromList(context, book.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailsScreen(book: book),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PublicReadingListDetailScreen extends StatelessWidget {
  final Book book;

  const PublicReadingListDetailScreen({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          book.imageUrl != null
              ? Image.network(
                  book.imageUrl!,
                  width: 200,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.book, size: 200),
                )
              : const Icon(Icons.book, size: 200),
          const SizedBox(height: 16),
          Text(
            book.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            book.author,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Category: ${book.category ?? 'N/A'}',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsScreen(book: book),
                ),
              );
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
} 