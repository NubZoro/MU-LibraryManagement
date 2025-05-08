import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libmu/services/fines_service.dart';
import 'package:libmu/widgets/animated_gradient_background.dart';
import 'package:intl/intl.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final finesData = await _finesService.calculateFines(user.uid);
      setState(() {
        _totalFines = finesData['totalFines'];
        _overdueBooks = finesData['overdueBooks'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading fines: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.9),
          elevation: 0,
          title: const Text('Fines & Overdue Books'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadFines,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Fines Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Fines',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${_totalFines.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _totalFines > 0
                                      ? () => _showPaymentDialog(context)
                                      : null,
                                  child: const Text('Pay Fines'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Overdue Books List
                        Text(
                          'Overdue Books',
                          style: Theme.of(context).textTheme.titleLarge,
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
                              final book = bookData['book'];
                              final dueDate = bookData['dueDate'];
                              final daysOverdue = bookData['daysOverdue'];
                              final fineAmount = bookData['fineAmount'];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: ListTile(
                                  title: Text(book.title),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Due Date: ${DateFormat('MMM dd, yyyy').format(dueDate)}'),
                                      Text('Days Overdue: $daysOverdue'),
                                      Text(
                                        'Fine: ₹$fineAmount',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.error,
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
              ),
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pay Fines'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Fines: ₹${_totalFines.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to Pay',
                prefixText: '₹',
              ),
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null && amount <= _totalFines) {
                  Navigator.pop(context, amount);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await _finesService.payFines(user.uid, result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment successful')),
            );
            _loadFines();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error processing payment: $e')),
            );
          }
        }
      }
    }
  }
} 