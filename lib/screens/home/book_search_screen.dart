import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/book.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class BookSearchScreen extends StatefulWidget {
  final String? initialQuery;
  
  const BookSearchScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  _BookSearchScreenState createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _searchResults = [];
  List<Book> _recommendations = [];
  bool _isLoading = false;
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchBooks(widget.initialQuery!);
    }
    _loadCategories();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('books').get();
      final Set<String> categories = {};
      
      for (var doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      setState(() {
        _categories = categories.toList()..sort();
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user's borrowed books
      final borrowedBooks = await FirebaseFirestore.instance
          .collection('books')
          .where('borrowedBy', isEqualTo: user.uid)
          .get();

      if (borrowedBooks.docs.isEmpty) return;

      // Get categories and authors from borrowed books
      final Set<String> categories = {};
      final Set<String> authors = {};
      
      for (var doc in borrowedBooks.docs) {
        final book = Book.fromFirestore(doc);
        if (book.category != null) categories.add(book.category!);
        authors.add(book.author);
      }

      // Get recommended books based on categories and authors
      final recommendedSnapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('available', isEqualTo: true)
          .get();

      final recommendations = recommendedSnapshot.docs
          .map((doc) => Book.fromFirestore(doc))
          .where((book) => 
              (book.category != null && categories.contains(book.category)) ||
              authors.contains(book.author))
          .where((book) => !borrowedBooks.docs.any((borrowed) => borrowed.id == book.id))
          .toList();

      setState(() {
        _recommendations = recommendations;
      });
    } catch (e) {
      print('Error loading recommendations: $e');
    }
  }

  Future<void> _searchBooks(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .get();

      final List<Book> results = snapshot.docs
          .map((doc) => Book.fromFirestore(doc))
          .where((book) {
            final matchesTitle = book.title.toLowerCase().contains(query.toLowerCase());
            final matchesCategory = _selectedCategory == null || book.category == _selectedCategory;
            return matchesTitle && matchesCategory;
          })
          .toList();

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildBookCard(Book book, {bool isRecommendation = false}) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(book: book),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book.imageUrl != null)
              Image.network(
                book.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.book, size: 50),
                    ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${book.author}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (book.category != null)
                    Chip(
                      label: Text(book.category!),
                      backgroundColor: Colors.blue[100],
                    ),
                  if (book.averageRating > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(' ${book.averageRating.toStringAsFixed(1)}/5.0'),
                      ],
                    ),
                  Text(
                    book.available ? 'Available' : 'Borrowed',
                    style: TextStyle(
                      color: book.available ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
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
        title: const Text('Search Books'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search books by title...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _searchBooks,
                ),
                const SizedBox(height: 8),
                if (_categories.isNotEmpty)
                  DropdownButton<String>(
                    value: _selectedCategory,
                    hint: const Text('Filter by category'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ..._categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _searchBooks(_searchController.text);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchController.text.isEmpty && _recommendations.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recommended for you',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 320,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _recommendations.length,
                                    itemBuilder: (context, index) {
                                      return SizedBox(
                                        width: 200,
                                        child: _buildBookCard(
                                          _recommendations[index],
                                          isRecommendation: true,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_searchController.text.isNotEmpty || _selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Search Results (${_searchResults.length})',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildBookCard(_searchResults[index]);
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  _BookDetailsScreenState createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateBookDetails() async {
    try {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.book.id)
          .update({
        'summary': _summaryController.text,
        'imageUrl': _imageUrlController.text,
      });

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book details updated successfully')),
      );
    } catch (e) {
      // Do not show any error SnackBar for technical errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .doc(widget.book.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.book.title)),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.book.title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final bookData = snapshot.data!.data() as Map<String, dynamic>;
        final book = Book.fromFirestore(snapshot.data!);
        final loanStatus = book.getLoanStatus();

        return Scaffold(
          appBar: AppBar(
            title: Text(book.title),
            actions: [
              StreamBuilder<bool>(
                stream: Provider.of<AuthService>(context).adminStatus,
                builder: (context, snapshot) {
                  final isAdmin = snapshot.data ?? false;
                  if (!isAdmin) return const SizedBox.shrink();

                  return IconButton(
                    icon: Icon(_isEditing ? Icons.save : Icons.edit),
                    onPressed: () {
                      if (_isEditing) {
                        _updateBookDetails();
                      } else {
                        _summaryController.text = bookData['summary'] ?? '';
                        _imageUrlController.text = bookData['imageUrl'] ?? '';
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bookData['imageUrl'] != null)
                  Center(
                    child: Image.network(
                      bookData['imageUrl'],
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.book, size: 200),
                    ),
                  ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Author: ${book.author}',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('ISBN: ${book.isbn ?? 'N/A'}'),
                      Text('Category: ${book.category ?? 'N/A'}'),
                      const SizedBox(height: 16),
                      if (book.averageRating > 0)
                        Row(
                          children: [
                            const Text('Rating: ',
                                style: TextStyle(fontSize: 16)),
                            ...List.generate(5, (index) {
                              return Icon(
                                index < book.averageRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                              );
                            }),
                            Text(
                              ' (${book.averageRating.toStringAsFixed(1)}/5.0)',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      const Text('Summary:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_isEditing)
                        TextField(
                          controller: _summaryController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        )
                      else
                        Text(bookData['summary'] ?? 'No summary available.'),
                      const SizedBox(height: 24),
                      if (!book.available && loanStatus['dueDate'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Due Date: ${loanStatus['dueDate'].toString().split(' ')[0]}'),
                            Text('Remaining Days: ${loanStatus['remainingDays']}'),
                            if (loanStatus['isOverdue'])
                              Text('Overdue by ${loanStatus['overdueDays']} days',
                                  style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      const SizedBox(height: 24),
                      if (book.available)
                        StreamBuilder<bool>(
                          stream: Provider.of<AuthService>(context).adminStatus,
                          builder: (context, snapshot) {
                            final isAdmin = snapshot.data ?? false;
                            if (isAdmin) return const SizedBox.shrink();
                            return Center(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please log in to borrow books')),
                                    );
                                    return;
                                  }
                                  try {
                                    final borrowedBooks = await FirebaseFirestore.instance
                                        .collection('books')
                                        .where('borrowedBy', isEqualTo: user.uid)
                                        .get();
                                    if (borrowedBooks.docs.length >= Book.maxBooksPerUser) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('You have reached the maximum number of borrowed books'),
                                        ),
                                      );
                                      return;
                                    }
                                    final batch = FirebaseFirestore.instance.batch();
                                    final bookRef = FirebaseFirestore.instance.collection('books').doc(book.id);
                                    batch.update(bookRef, {
                                      'available': false,
                                      'borrowedBy': user.uid,
                                      'borrowedAt': FieldValue.serverTimestamp(),
                                    });
                                    await batch.commit();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Book borrowed successfully')),
                                    );
                                    if (context.mounted) Navigator.pop(context);
                                  } catch (e) {
                                    // Do not show any error SnackBar for technical errors
                                  }
                                },
                                child: const Text('Borrow'),
                              ),
                            );
                          },
                        ),
                      const Text('Reviews:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ...book.reviews.map((review) => Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        review['userName'] ?? 'Anonymous',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      ...List.generate(
                                        5,
                                        (index) => Icon(
                                          index < (review['rating'] ?? 0)
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(review['review'] ?? ''),
                                  const SizedBox(height: 4),
                                  Text(
                                    review['timestamp'] ?? 'Unknown date',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BookReviewsScreen(book: book),
                              ),
                            );
                          },
                          child: const Text('Add Review'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BookReviewsScreen extends StatefulWidget {
  final Book book;

  const BookReviewsScreen({Key? key, required this.book}) : super(key: key);

  @override
  _BookReviewsScreenState createState() => _BookReviewsScreenState();
}

class _BookReviewsScreenState extends State<BookReviewsScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to submit a review')),
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      final review = {
        'userId': user.uid,
        'userName': userName,
        'rating': _rating,
        'review': _reviewController.text,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final bookDoc = await FirebaseFirestore.instance.collection('books').doc(widget.book.id).get();
      final currentReviews = List<Map<String, dynamic>>.from(bookDoc.data()?['reviews'] ?? []);
      final currentRating = bookDoc.data()?['averageRating'] ?? 0.0;
      final totalRatings = currentReviews.length;
      
      final newAverageRating = ((currentRating * totalRatings) + _rating) / (totalRatings + 1);

      await FirebaseFirestore.instance.collection('books').doc(widget.book.id).update({
        'reviews': FieldValue.arrayUnion([review]),
        'averageRating': newAverageRating,
      });

      setState(() {
        _reviewController.clear();
        _rating = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
    } catch (e) {
      // Do not show any error SnackBar for technical errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Reviews'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.book.reviews.length,
              itemBuilder: (context, index) {
                final review = widget.book.reviews[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(review['userName'] ?? 'Anonymous',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Rating: ${review['rating']}/5'),
                        const SizedBox(height: 8),
                        Text(review['review'] ?? ''),
                        const SizedBox(height: 8),
                        Text(
                          review['timestamp'] ?? 'Unknown date',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Add Your Review'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                TextField(
                  controller: _reviewController,
                  decoration: const InputDecoration(
                    hintText: 'Write your review...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitReview,
                  child: const Text('Submit Review'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 