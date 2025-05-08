import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libmu/services/fines_service.dart';
import 'package:libmu/widgets/animated_gradient_background.dart';
import 'package:libmu/models/book.dart';

class FinesScreen extends StatefulWidget {
  const FinesScreen({Key? key}) : super(key: key);

  @override
  _FinesScreenState createState() => _FinesScreenState();
}

class _FinesScreenState extends State<FinesScreen> {
  final FinesService _finesService = FinesService();
  bool _isLoading = true;
  double _totalFines = 0;
  List<Map<String, dynamic>> _overdueBooks = [];

  @override
  void initState() {
    super.initState();
    _loadFines();
  }

  Future<void> _loadFines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final finesData = await _finesService.calculateFines(user.uid);
        setState(() {
          _totalFines = finesData['totalFines'];
          _overdueBooks = finesData['overdueBooks'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading fines: $e')),
      );
    }
  }

  Future<void> _payFines() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _finesService.payFines(user.uid, _totalFines);
        await _loadFines();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fines paid successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error paying fines: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Fines'),
          backgroundColor: Colors.transparent,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Fines',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${_totalFines.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_totalFines > 0)
                              ElevatedButton(
                                onPressed: _payFines,
                                child: const Text('Pay Fines'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Overdue Books',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_overdueBooks.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No overdue books'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _overdueBooks.length,
                        itemBuilder: (context, index) {
                          final bookData = _overdueBooks[index];
                          final book = bookData['book'] as Book;
                          final dueDate = bookData['dueDate'] as DateTime;
                          final daysOverdue = bookData['daysOverdue'] as int;
                          final fineAmount = bookData['fineAmount'] as double;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              title: Text(book.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Author: ${book.author}'),
                                  Text('Due Date: ${dueDate.toString().split(' ')[0]}'),
                                  Text(
                                    'Overdue by $daysOverdue days',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  Text(
                                    'Fine: ₹${fineAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
} 