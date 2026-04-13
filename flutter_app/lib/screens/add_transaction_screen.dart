import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Food';
  String _selectedType = 'debit';

  final List<String> categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Education',
    'Health',
    'Shopping',
    'Utilities',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ Add Transaction'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Type
              const Text(
                'Transaction Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'debit',
                          label: Text('🔴 Expense'),
                        ),
                        ButtonSegment(
                          value: 'credit',
                          label: Text('🟢 Income'),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => _selectedType = newSelection.first);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount
              Text(
                'Amount (₹)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 500',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Amount required';
                  if (double.tryParse(v!) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category
              Text(
                'Category',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value ?? 'Food');
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Description (Optional)
              Text(
                'Description (Optional)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g., Lunch at cafe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.check),
                  label: const Text('Add Transaction'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _selectedType == 'debit'
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    if (authProvider.userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Please login first')),
        );
      }
      return;
    }

    final amount = double.parse(_amountController.text);
    final payload = {
      'amount': amount,
      'category': _selectedCategory,
      'type': _selectedType,
      'description': _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
    };

    try {
      await transactionProvider.addTransaction(
        authProvider.userId!,
        payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Transaction added: ₹${amount.toStringAsFixed(2)}',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }
}
