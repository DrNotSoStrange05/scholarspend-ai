import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/due.dart';
import '../providers/dues_provider.dart';

class DuesManagerScreen extends StatefulWidget {
  final int userId;

  const DuesManagerScreen({
    super.key,
    required this.userId,
  });

  @override
  State<DuesManagerScreen> createState() => _DuesManagerScreenState();
}

class _DuesManagerScreenState extends State<DuesManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DuesProvider>().loadDues(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('💳 Dues Tracker'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: '💰 What I Owe'),
              Tab(text: '💸 Who Owes Me'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddDueDialog(context),
          label: const Text('Add Due'),
          icon: const Icon(Icons.add),
        ),
        body: Consumer<DuesProvider>(
          builder: (context, duesProvider, _) {
            if (duesProvider.isLoading && duesProvider.dues.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }              if (duesProvider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('❌ Error: ${duesProvider.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            duesProvider.loadDues(widget.userId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return TabBarView(
              children: [
                // ── Tab 1: What I Owe (Red) ────────────────────
                _DuesList(
                  title: '🔴 What I Owe',
                  dues: duesProvider.iOwe,
                  isOwedToMe: false,
                  userId: widget.userId,
                ),

                // ── Tab 2: Who Owes Me (Green) ─────────────────
                _DuesList(
                  title: '🟢 Who Owes Me',
                  dues: duesProvider.owedToMe,
                  isOwedToMe: true,
                  userId: widget.userId,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddDueDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String personName = '';
    double amount = 0.0;
    String description = '';
    bool isOwedToMe = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('➕ Add New Due'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Person Name',
                    hintText: 'e.g., Rahul, Priya',
                  ),
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (v) => personName = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    hintText: '500',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(v!) == null) {
                      return 'Invalid amount';
                    }
                    return null;
                  },
                  onSaved: (v) => amount = double.tryParse(v ?? '0') ?? 0.0,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'e.g., Movie tickets',
                  ),
                  onSaved: (v) => description = v ?? '',
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Someone owes ME money'),
                  value: isOwedToMe,
                  onChanged: (v) =>
                      setState(() => isOwedToMe = v ?? false),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final payload = {
                  'person_name': personName,
                  'amount': amount,
                  'description': description.isNotEmpty ? description : null,
                  'is_owed_to_me': isOwedToMe,
                };
                context.read<DuesProvider>().addDue(widget.userId, payload);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Dues List Widget
// ═══════════════════════════════════════════════════════════════

class _DuesList extends StatelessWidget {
  final String title;
  final List<Due> dues;
  final bool isOwedToMe;
  final int userId;

  const _DuesList({
    required this.title,
    required this.dues,
    required this.isOwedToMe,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    if (dues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isOwedToMe ? '✅ Everyone paid up!' : '✅ No debts!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Add a new due to get started',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final totalAmount = dues.fold<double>(0, (sum, d) => sum + d.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOwedToMe ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOwedToMe ? Colors.green.shade300 : Colors.red.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOwedToMe ? '💸 Total Owed To Me' : '💰 Total I Owe',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isOwedToMe ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Dues List
        ...dues.map((due) {
          return _DueCard(
            due: due,
            isOwedToMe: isOwedToMe,
            onMarkPaid: () {
              context.read<DuesProvider>().markPaid(due.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Marked as paid')),
              );
            },
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Individual Due Card
// ═══════════════════════════════════════════════════════════════

class _DueCard extends StatelessWidget {
  final Due due;
  final bool isOwedToMe;
  final VoidCallback onMarkPaid;

  const _DueCard({
    required this.due,
    required this.isOwedToMe,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isOwedToMe ? Colors.green.shade100 : Colors.red.shade100;
    final borderColor = isOwedToMe ? Colors.green.shade400 : Colors.red.shade400;
    final textColor = isOwedToMe ? Colors.green.shade900 : Colors.red.shade900;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        due.personName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (due.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          due.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '₹${due.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            if (due.dueDate != null) ...[
              const SizedBox(height: 8),
              Text(
                '📅 Due: ${DateFormat('MMM d, yyyy').format(due.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkPaid,
                icon: const Icon(Icons.check),
                label: const Text('Mark as Paid'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOwedToMe ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
