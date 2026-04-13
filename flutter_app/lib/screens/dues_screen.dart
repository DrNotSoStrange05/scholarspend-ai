import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/due.dart';
import '../providers/dues_provider.dart';
import '../theme/app_theme.dart';

class DuesScreen extends StatefulWidget {
  const DuesScreen({super.key});

  @override
  State<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends State<DuesScreen> {
  static const int _userId = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DuesProvider>().loadDues(_userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DuesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.card : Colors.white;
    final bgColor   = isDark ? AppTheme.bg   : const Color(0xFFF5F5F8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dues Tracker'),
      ),
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDueSheet(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Due', style: TextStyle(color: Colors.white)),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadDues(_userId),
              child: provider.dues.isEmpty
                  ? _EmptyDues()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                      children: [
                        // ── Summary chips ────────────────────────
                        _SummaryRow(
                          iOweTotal: provider.iOwe
                              .fold(0.0, (s, d) => s + d.amount),
                          owedToMeTotal: provider.owedToMe
                              .fold(0.0, (s, d) => s + d.amount),
                        ),
                        const SizedBox(height: 24),

                        // ── Who Owes Me ─────────────────────────
                        if (provider.owedToMe.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'WHO OWES ME',
                            color: AppTheme.success,
                            count: provider.owedToMe.length,
                          ),
                          const SizedBox(height: 8),
                          ...provider.owedToMe.map(
                            (d) => _DueCard(
                              due: d,
                              isOwedToMe: true,
                              cardColor: cardColor,
                              onMarkPaid: () => provider.markPaid(d.id),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── What I Owe ──────────────────────────
                        if (provider.iOwe.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'WHAT I OWE',
                            color: AppTheme.danger,
                            count: provider.iOwe.length,
                          ),
                          const SizedBox(height: 8),
                          ...provider.iOwe.map(
                            (d) => _DueCard(
                              due: d,
                              isOwedToMe: false,
                              cardColor: cardColor,
                              onMarkPaid: () => provider.markPaid(d.id),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }

  void _showAddDueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddDueSheet(userId: _userId),
    );
  }
}

// ─────────────────────── Sub-widgets ───────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final double iOweTotal;
  final double owedToMeTotal;

  const _SummaryRow({required this.iOweTotal, required this.owedToMeTotal});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            label: 'I OWE',
            value: '₹${fmt.format(iOweTotal)}',
            color: AppTheme.danger,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryChip(
            label: 'OWED TO ME',
            value: '₹${fmt.format(owedToMeTotal)}',
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _SectionHeader(
      {required this.label, required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _DueCard extends StatelessWidget {
  final Due due;
  final bool isOwedToMe;
  final Color cardColor;
  final VoidCallback onMarkPaid;

  const _DueCard({
    required this.due,
    required this.isOwedToMe,
    required this.cardColor,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isOwedToMe ? AppTheme.success : AppTheme.danger;
    final fmt = NumberFormat('#,##0.00');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: accent, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Person avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: accent.withOpacity(0.15),
            child: Text(
              due.personName.isNotEmpty
                  ? due.personName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  due.personName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (due.description != null && due.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    due.description!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
                if (due.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Due ${DateFormat('dd MMM yyyy').format(due.dueDate!)}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Amount + Mark Paid
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${fmt.format(due.amount)}',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _confirmMarkPaid(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.success.withOpacity(0.4), width: 1),
                  ),
                  child: const Text(
                    '✓ Paid',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmMarkPaid(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Paid?'),
        content: Text('Mark ₹${due.amount.toStringAsFixed(0)} with ${due.personName} as settled?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onMarkPaid();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
  }
}

class _EmptyDues extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_outlined,
                size: 72,
                color: AppTheme.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text(
              'No pending dues!\nTap + to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────── Add Due Bottom Sheet ───────────────────────────────────

class _AddDueSheet extends StatefulWidget {
  final int userId;
  const _AddDueSheet({required this.userId});

  @override
  State<_AddDueSheet> createState() => _AddDueSheetState();
}

class _AddDueSheetState extends State<_AddDueSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _personCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isOwedToMe = false;
  bool _isSaving = false;
  DateTime? _dueDate;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _personCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final payload = {
      'amount': double.parse(_amountCtrl.text.trim()),
      'person_name': _personCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'is_owed_to_me': _isOwedToMe,
      'due_date': _dueDate?.toIso8601String(),
    };
    await context.read<DuesProvider>().addDue(widget.userId, payload);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? AppTheme.surface : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Due',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // Direction toggle
              Row(
                children: [
                  const Text('Direction:', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('I Owe'),
                    selected: !_isOwedToMe,
                    onSelected: (_) => setState(() => _isOwedToMe = false),
                    selectedColor: AppTheme.danger.withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Owes Me'),
                    selected: _isOwedToMe,
                    onSelected: (_) => setState(() => _isOwedToMe = true),
                    selectedColor: AppTheme.success.withOpacity(0.8),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _personCtrl,
                decoration: const InputDecoration(
                  labelText: 'Person Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Due',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
