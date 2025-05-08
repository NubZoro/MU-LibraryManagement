import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/reading_list.dart';
import '../../models/book.dart';
import '../home/book_search_screen.dart';

class PublicReadingListsScreen extends StatefulWidget {
  const PublicReadingListsScreen({Key? key}) : super(key: key);

  @override
  State<PublicReadingListsScreen> createState() => _PublicReadingListsScreenState();
}

class _PublicReadingListsScreenState extends State<PublicReadingListsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Explore Public Reading Lists'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search public lists',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reading_lists')
                  .where('isPublic', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lists = snapshot.data!.docs
                    .map((doc) => ReadingList.fromFirestore(doc))
                    .where((list) {
                      if (_searchQuery.isEmpty) return true;
                      return list.name.toLowerCase().contains(_searchQuery) ||
                          list.description.toLowerCase().contains(_searchQuery) ||
                          list.ownerId.toLowerCase().contains(_searchQuery);
                    })
                    .toList();
                if (lists.isEmpty) {
                  return const Center(child: Text('No public reading lists found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    return Card(
                      child: ListTile(
                        title: Text(list.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(list.description),
                            const SizedBox(height: 4),
                            Text(
                              '${list.bookIds.length} books • by ${list.ownerId.substring(0, 6)}... • Public',
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
                                builder: (context) => PublicReadingListDetailScreen(readingList: list),
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
          ),
        ],
      ),
    );
  }
}

class PublicReadingListDetailScreen extends StatelessWidget {
  final ReadingList readingList;
  const PublicReadingListDetailScreen({Key? key, required this.readingList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (readingList.bookIds.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text(readingList.name)),
        body: const Center(child: Text('No books in this list yet.')),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(readingList.name)),
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
            return const Center(child: Text('No books in this list yet.'));
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