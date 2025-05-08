import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/book_service.dart';
import 'package:libmu/models/book.dart';
import 'package:libmu/screens/home/book_search_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final QRService _qrService = QRService();
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Run Firestore Debug Query',
            onPressed: () async {
              try {
                final snapshot = await FirebaseFirestore.instance.collection('books').limit(1).get();
                print('DEBUG: Books count: \\${snapshot.docs.length}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('DEBUG: Books count: \\${snapshot.docs.length}')),
                  );
                }
              } catch (e) {
                print('DEBUG: Firestore error: \\${e.toString()}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('DEBUG: Firestore error: \\${e.toString()}')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.upgrade),
            tooltip: 'Migrate Books to Status',
            onPressed: () async {
              try {
                await BookService().migrateBooksToStatus();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Migration completed!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Migration error: \\${e.toString()}')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_isProcessing) {
                  print('Already processing a QR code');
                  return;
                }
                setState(() => _isProcessing = true);
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isEmpty) {
                  print('No barcodes detected');
                  return;
                }

                final String bookId = (barcodes.first.rawValue ?? '').trim();
                print('DEBUG: Book ID from QR: "$bookId"');
                if (bookId.isEmpty) {
                  print('Empty QR code data');
                  return;
                }

                _processQRCode(bookId);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Scan the QR code on the book to borrow it',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processQRCode(String bookId) async {
    print('Processing QR code (bookId): "$bookId"');
    // Fetch the book document by ID
    final doc = await FirebaseFirestore.instance.collection('books').doc(bookId).get();
    if (!doc.exists) {
      print('DEBUG: Book not found for ID: "$bookId"');
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Book not found for ID: "$bookId"'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }
    // Create a Book object
    final book = Book.fromFirestore(doc);
    // Navigate to BookDetailsScreen and auto-borrow if possible
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst); // Close scanner
      Future.delayed(const Duration(milliseconds: 300), () async {
        final user = FirebaseAuth.instance.currentUser;
        final isAdmin = false; // You can add admin check if needed
        if (book.available && user != null && !isAdmin) {
          try {
            final borrowedBooks = await FirebaseFirestore.instance
                .collection('books')
                .where('borrowedBy', isEqualTo: user.uid)
                .get();
            if (borrowedBooks.docs.length < Book.maxBooksPerUser) {
              final batch = FirebaseFirestore.instance.batch();
              final bookRef = FirebaseFirestore.instance.collection('books').doc(book.id);
              batch.update(bookRef, {
                'available': false,
                'borrowedBy': user.uid,
                'borrowedAt': FieldValue.serverTimestamp(),
              });
              await batch.commit();
              // Show BookDetailsScreen and popup
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsScreen(book: book),
                ),
              );
              await Future.delayed(const Duration(milliseconds: 400));
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Success'),
                    content: const Text('Book borrowed successfully!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
              setState(() => _isProcessing = false);
              return;
            }
          } catch (e) {
            // fallback: just show details page
          }
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(book: book),
          ),
        );
        setState(() => _isProcessing = false);
      });
    }
  }
}