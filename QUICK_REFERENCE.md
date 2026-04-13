# Quick Reference: Analytics & Dues Features

## For Developers

### 🔗 API Endpoints Quick Reference

| Endpoint | Method | Purpose | Parameters |
|----------|--------|---------|------------|
| `/analytics/summary` | GET | Get monthly breakdown & trends | `user_id` |
| `/analytics/survival-forecast` | GET | Get survival metrics | `user_id`, `data_window_days` (optional) |
| `/dues/` | GET | List dues for user | `user_id`, `include_paid` (optional) |
| `/dues/` | POST | Create new due | `user_id` (query), `DueCreate` (body) |
| `/dues/{due_id}/pay` | PATCH | Mark due as paid | - |

### 📱 Flutter Navigation

```dart
// Navigate to Analytics
Navigator.pushNamed(context, '/analytics');

// Navigate to Dues Manager  
Navigator.pushNamed(context, '/dues');

// From Dashboard, add these buttons:
ListTile(
  leading: Icon(Icons.analytics),
  title: Text('Analytics'),
  onTap: () => Navigator.pushNamed(context, '/analytics'),
)

ListTile(
  leading: Icon(Icons.credit_card),
  title: Text('Dues'),
  onTap: () => Navigator.pushNamed(context, '/dues'),
)
```

### 🔄 State Management Usage

#### Analytics Provider
```dart
final provider = context.watch<AnalyticsProvider>();

// Load data
provider.loadSummary(userId);

// Access data
final summary = provider.summary;
final isLoading = provider.isLoading;
final error = provider.error;

// Access computed totals
final monthlyTotal = summary?.totalSpentCurrentMonth;
final breakdown = summary?.categoryBreakdown;
final trends = summary?.balanceTrend;
```

#### Dues Provider
```dart
final provider = context.watch<DuesProvider>();

// Load data
provider.loadDues(userId);

// Access filtered lists
final iOwe = provider.iOwe;        // What I owe (red)
final owedToMe = provider.owedToMe; // Who owes me (green)

// Get totals
final iOweTotal = provider.iOwe.fold(0.0, (sum, d) => sum + d.amount);
final owerToMeTotal = provider.owedToMe.fold(0.0, (sum, d) => sum + d.amount);

// Add new due
provider.addDue(userId, {
  'person_name': 'Name',
  'amount': 100.0,
  'is_owed_to_me': false,
});

// Mark as paid
provider.markPaid(dueId);
```

### 🎨 UI Components

#### Using Analytics Chart Data
```dart
// In AnalyticsScreen
final summary = context.watch<AnalyticsProvider>().summary;

// Pie chart from category breakdown
PieChartSectionData(
  color: categoryColor,
  value: categoryAmount,
  title: '${(percentage).toStringAsFixed(0)}%',
)

// Bar chart from balance trend
BarChartGroupData(
  x: index,
  barRods: [BarChartRodData(toY: amount)],
)
```

#### Adding Transaction Category
```dart
// In manual transaction form
DropdownButton<TransactionCategory>(
  items: TransactionCategory.values.map((category) {
    return DropdownMenuItem(
      value: category,
      child: Text(category.name.toUpperCase()),
    );
  }).toList(),
  onChanged: (value) => setState(() => selectedCategory = value),
)
```

### 📊 Data Models

```dart
// Analytics Summary
class AnalyticsSummary {
  final int userId;
  final double totalSpentCurrentMonth;
  final Map<String, double> categoryBreakdown; // "food" => 1500.0
  final List<BalanceTrendPoint> balanceTrend;
}

// Balance Trend Point
class BalanceTrendPoint {
  final String date;     // "2026-04-13"
  final double total;    // 450.50
}

// Due
class Due {
  final int id;
  final double amount;
  final String personName;
  final bool isOwedToMe;  // true = they owe me, false = I owe them
  final bool isPaid;
  final DateTime? dueDate;
  final String? description;
}
```

### 🛠️ Common Tasks

#### Load Analytics on Screen Open
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<AnalyticsProvider>().loadSummary(userId);
  });
}
```

#### Filter Chart Data
```dart
// Get only food expenses
final foodExpense = summary.categoryBreakdown['food'] ?? 0.0;

// Get highest spending day
final topDay = summary.balanceTrend.reduce((a, b) => 
  a.total > b.total ? a : b
);
```

#### Handle Dues
```dart
// Separate by type
final myDebts = provider.iOwe;
final myCredits = provider.owedToMe;

// Filter by status
final unpaidDebts = myDebts.where((d) => !d.isPaid).toList();
final paidDebts = myDebts.where((d) => d.isPaid).toList();
```

#### Color by Status
```dart
// Dues color
final bgColor = due.isOwedToMe ? Colors.green.shade100 : Colors.red.shade100;

// Chart color by category
final categoryColors = {
  'food': Colors.orange,
  'transport': Colors.blue,
  'entertainment': Colors.purple,
  'education': Colors.green,
};
```

### 🔍 Debugging

#### Check API Responses
```dart
// In AnalyticsProvider
print('Summary: ${_summary?.totalSpentCurrentMonth}');
print('Categories: ${_summary?.categoryBreakdown}');
print('Trends: ${_summary?.balanceTrend}');

// In DuesProvider
print('Total dues: ${_dues.length}');
print('I owe: ${iOwe.length}');
print('Owe to me: ${owedToMe.length}');
```

#### Verify Theme
```dart
final provider = context.watch<ThemeService>();
print('Is dark mode: ${provider.isDark}');

// Toggle
provider.toggleTheme();
```

### ⚡ Performance Tips

1. **Avoid rebuilds**: Use `Consumer` or `Selector` instead of `watch`
   ```dart
   Selector<AnalyticsProvider, AnalyticsSummary?>(
     selector: (_, provider) => provider.summary,
     builder: (_, summary, __) => ... // only rebuilds when summary changes
   )
   ```

2. **Lazy load data**: Don't load everything on app start
   ```dart
   // Load only in initState of screen
   context.read<AnalyticsProvider>().loadSummary(userId);
   ```

3. **Batch API calls**: Use Future.wait if independent
   ```dart
   await Future.wait([
     api.fetchAnalytics(userId),
     api.fetchDues(userId),
   ]);
   ```

4. **Cache data**: Provider keeps data in memory between navigations
   ```dart
   // Data persists until explicitly refreshed
   onRefresh: () => provider.loadSummary(userId)
   ```

### 📝 Code Snippets

#### Add Due Button
```dart
FloatingActionButton.extended(
  onPressed: _showAddDueDialog,
  label: const Text('Add Due'),
  icon: const Icon(Icons.add),
)
```

#### Dues Summary Card
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: isOwedToMe ? Colors.green.shade50 : Colors.red.shade50,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      Text(isOwedToMe ? 'Total Owed To Me' : 'Total I Owe'),
      Text('₹${amount.toStringAsFixed(2)}'),
    ],
  ),
)
```

#### Mark as Paid Button
```dart
ElevatedButton.icon(
  onPressed: () => provider.markPaid(due.id),
  icon: Icon(Icons.check),
  label: Text('Mark as Paid'),
)
```

### 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Charts not showing | Check data is not empty, verify `BalanceTrendPoint` format |
| Dues not updating | Call `loadDues()` in initState, ensure API returns data |
| Theme not persisting | Check `SharedPreferences` initialized, data written correctly |
| Navigation errors | Verify routes registered in `main.dart` routes map |
| API 404 errors | Check user_id parameter, ensure backend endpoint exists |

### 🚀 Deploy Checklist

- [ ] Update `main.dart` with all new providers
- [ ] Add navigation routes for `/analytics` and `/dues`
- [ ] Update Dashboard with navigation buttons
- [ ] Test all API endpoints work
- [ ] Verify database has sample data
- [ ] Run `flutter pub get`
- [ ] Build APK/IPA for testing
- [ ] Check both light and dark themes
- [ ] Verify responsive layout on different screens
- [ ] Test error handling with bad network
- [ ] Review security (API keys, sensitive data)

---

**Version**: 1.0.0  
**Last Updated**: April 13, 2026  
**Status**: ✅ Complete & Tested
