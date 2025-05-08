import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libmu/services/auth_service.dart';
import 'package:libmu/screens/home/book_list_screen.dart';
import 'package:libmu/screens/home/borrowed_books_screen.dart';
import 'package:libmu/screens/profile_screen.dart';
import 'package:libmu/screens/admin/admin_screen.dart';
import 'package:libmu/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/book.dart';
import 'book_search_screen.dart';
import 'package:libmu/widgets/animated_gradient_background.dart';
import 'package:libmu/services/gamification_service.dart';
import 'package:libmu/screens/home/fines_screen.dart';
import 'package:libmu/screens/reading_lists/reading_lists_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: Provider.of<AuthService>(context).adminStatus,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return const AdminScreen();
        }

        final List<Widget> _screens = [
          _buildHomeContent(),
          const BorrowedBooksScreen(),
          const FinesScreen(),
          const ReadingListsScreen(),
          const ProfileScreen(),
        ];

        return AnimatedGradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.9),
              elevation: 0,
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/mu_logo.png',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 8),
                  const Text('MU Library'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BookSearchScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Provider.of<ThemeProvider>(context).isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () {
                    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                  },
                ),
              ],
            ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: _screens[_selectedIndex],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).bottomNavigationBarTheme.backgroundColor?.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.book),
                    label: 'Borrowed',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.money),
                    label: 'Fines',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list),
                    label: 'Lists',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Recently Added Books',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('books')
              .orderBy('addedAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final books = snapshot.data!.docs
                .map((doc) => Book.fromFirestore(doc))
                .toList();

            if (books.isEmpty) {
              return const Center(child: Text('No books available'));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book.imageUrl != null
                          ? Image.network(
                              book.imageUrl!,
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.book, size: 50),
                            )
                          : const Icon(Icons.book, size: 50),
                    ),
                    title: Text(book.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Author: ${book.author}'),
                        Text('Category: ${book.category ?? 'N/A'}'),
                      ],
                    ),
                    trailing: book.available
                        ? ElevatedButton(
                            onPressed: () => _borrowBook(context, book),
                            child: const Text('Borrow'),
                          )
                        : const Text(
                            'Borrowed',
                            style: TextStyle(color: Colors.red),
                          ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/qr_scanner');
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR Code'),
        ),
      ],
    );
  }

  Future<void> _borrowBook(BuildContext context, Book book) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to borrow books')),
        );
        return;
      }

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

      // Start a batch write to ensure atomicity
      final batch = FirebaseFirestore.instance.batch();
      final bookRef = FirebaseFirestore.instance.collection('books').doc(book.id);
      
      batch.update(bookRef, {
        'available': false,
        'borrowedBy': user.uid,
        'borrowedAt': FieldValue.serverTimestamp(),
      });

      // Execute the batch
      await batch.commit();

      // Award points and badges
      final gamificationService = GamificationService();
      await gamificationService.awardBorrowPoints(user.uid, book.category ?? 'Unknown');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book borrowed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error borrowing book: $e')),
      );
    }
  }
} 