# Analytics Suite & Dues Manager Implementation Guide

## Overview

This implementation adds a complete **Analytics Suite** and **Dues Manager** system to ScholarSpend AI, featuring:

1. **Monthly Analytics Dashboard** — Spending breakdown, category analysis, and 7-day trends
2. **Dues Tracker** — Manage "What I Owe" and "Who Owes Me" with categorized tracking
3. **Theme Provider** — Dark/Light mode toggle with persistent storage
4. **Enhanced API Endpoints** — New analytics and dues management endpoints
5. **Provider-based State Management** — Follows existing Flutter patterns

---

## Backend Updates

### 1. Database Models (`models.py`)

#### Dues Table (Already Implemented)
```python
class Dues(Base):
    __tablename__ = "dues"
    
    id: Primary Key
    user_id: Foreign Key (User)
    amount: Float (due amount)
    description: Optional string
    person_name: String (creditor/debtor name)
    due_date: Optional DateTime
    is_owed_to_me: Boolean (True = someone owes me, False = I owe someone)
    is_paid: Boolean (settlement status)
    created_at: DateTime (created timestamp)
    updated_at: DateTime (last updated)
    
    Relationships:
      - user: User (back_populates="dues")
```

#### Transaction Model Enhancement (Already Implemented)
✅ The Transaction model already includes:
- `category` field (TransactionCategory enum)
- `transacted_at` timestamp field
- Full categorization support (Food, Transport, Entertainment, Education, Health, Shopping, Utilities, Subscription, Transfer, Other)

---

### 2. API Schemas (`schemas.py`)

#### Key Schemas Implemented:

**DueCreate** — Payload for adding a new due
```python
amount: float
description: Optional[str]
person_name: str
due_date: Optional[datetime]
is_owed_to_me: bool  # True = someone owes me
```

**DueResponse** — Due record from API
```python
id: int
user_id: int
amount: float
description: Optional[str]
person_name: str
due_date: Optional[datetime]
is_owed_to_me: bool
is_paid: bool
created_at: datetime
updated_at: datetime
```

**AnalyticsSummaryResponse** — Monthly analytics data
```python
user_id: int
total_spent_current_month: float
category_breakdown: dict[str, float]  # Category → Total Amount
balance_trend: List[BalanceTrendPoint]  # 7-day daily totals
```

**BalanceTrendPoint** — Single day's trend
```python
date: str  # ISO format
total: float  # Daily debit total
```

---

### 3. API Endpoints

#### Dues Endpoints (Router: `/dues`)

**GET /dues/**
- Returns list of unpaid dues for a user
- Query Parameters:
  - `user_id`: int (required)
  - `include_paid`: bool (optional, default=False)
- Response: `List[DueResponse]`

**POST /dues/**
- Create a new due/debt record
- Query Parameters:
  - `user_id`: int (required)
- Body: `DueCreate`
- Response: `DueResponse` (201 Created)

**PATCH /dues/{due_id}/pay**
- Mark a due as paid/settled
- Response: `DueResponse` (updated record)

#### Analytics Endpoints (Router: `/analytics`)

**GET /analytics/summary** (ALREADY EXISTING)
- Monthly analytics snapshot
- Query Parameters:
  - `user_id`: int (required)
- Response: `AnalyticsSummaryResponse`
- Returns:
  - `total_spent_current_month`: Sum of all debits since 1st of month
  - `category_breakdown`: Dictionary of category → spent amount
  - `balance_trend`: Daily debit totals for last 7 days

**GET /analytics/survival-forecast** (ALREADY EXISTING)
- Core survival counter and crash date prediction
- Query Parameters:
  - `user_id`: int (required)
  - `data_window_days`: int (optional, default=30)
- Response: `SurvivalForecastResponse`

---

### 4. CRUD Operations (`crud.py`)

All required CRUD operations are already implemented:

```python
# Dues Management
async def get_dues(db, user_id, include_paid=False) → List[Dues]
async def get_due(db, due_id) → Optional[Dues]
async def create_due(db, user_id, payload) → Dues
async def mark_due_paid(db, due) → Dues

# Analytics
async def get_monthly_total(db, user_id) → float
async def get_category_breakdown(db, user_id, days) → List[dict]
async def get_category_breakdown_current_month(db, user_id) → dict[str, float]
async def get_balance_trend_7days(db, user_id) → List[dict]
async def get_daily_spend_last_n_days(db, user_id, days) → List[float]
```

---

## Flutter Frontend Updates

### 1. New Models

#### `lib/models/analytics.dart`
```dart
class AnalyticsSummary {
  final int userId;
  final double totalSpentCurrentMonth;
  final Map<String, double> categoryBreakdown;
  final List<BalanceTrendPoint> balanceTrend;
  // ... factory methods
}

class BalanceTrendPoint {
  final String date;
  final double total;
}
```

#### `lib/models/due.dart` (Enhanced)
```dart
class Due {
  final int id;
  final int userId;
  final double amount;
  final String? description;
  final String personName;
  final DateTime? dueDate;
  final bool isOwedToMe;  // True = someone owes me
  final bool isPaid;
  // ... factory methods
}
```

---

### 2. New Providers

#### `lib/providers/theme_provider.dart`
**ThemeService** — Manages dark/light theme with persistent storage
```dart
class ThemeService extends ChangeNotifier {
  bool get isDark         // Current theme state
  Future<void> toggleTheme()    // Switch theme
  Future<void> _load()          // Load from SharedPreferences
}
```

**Usage:**
```dart
Consumer<ThemeService>(
  builder: (context, themeService, _) {
    return MaterialApp(
      themeMode: themeService.isDark ? ThemeMode.dark : ThemeMode.light,
    );
  }
)
```

#### `lib/providers/analytics_provider.dart`
**AnalyticsProvider** — Fetches and manages analytics data
```dart
class AnalyticsProvider extends ChangeNotifier {
  AnalyticsSummary? get summary
  bool get isLoading
  String? get error
  
  Future<void> loadSummary(int userId)
}
```

#### `lib/providers/dues_provider.dart`
**DuesProvider** — Manages dues/debts
```dart
class DuesProvider extends ChangeNotifier {
  List<Due> get dues
  List<Due> get iOwe        // What I owe (red)
  List<Due> get owedToMe    // Who owes me (green)
  
  Future<void> loadDues(int userId)
  Future<void> addDue(int userId, Map<String, dynamic> payload)
  Future<void> markPaid(int dueId)
}
```

---

### 3. New Screens

#### `lib/screens/analytics_screen.dart`

**AnalyticsScreen** — Two-tab analytics dashboard

**Tab 1: Monthly Overview**
- **Total Spent Card** (gradient background)
  - Shows current month's total spending
  - Prominent ₹ display with trend color
  
- **Category Breakdown Pie Chart** (fl_chart)
  - Visual representation of spending by category
  - Hover labels show percentage
  
- **Category List View**
  - Detailed breakdown with category emoji
  - Sorted by amount (descending)
  - Shows exact amounts and category labels

**Tab 2: 7-Day Trends**
- **Daily Spending Bar Chart** (fl_chart)
  - Last 7 days of spending
  - Bar height = daily debit total
  - X-axis: ISO date labels (MMM d format)
  - Y-axis: Amount in ₹

**Features:**
- RefreshIndicator for manual refresh
- Error state with retry button
- Loading state with circular progress
- Pull-to-refresh functionality

---

#### `lib/screens/dues_manager_screen.dart`

**DuesManagerScreen** — Two-tab dues tracking

**Tab 1: What I Owe (Red)**
- **Summary Card** (red theme)
  - Shows total owed
  - Red color scheme
  
- **Dues List** (sorted by recent)
  - Person name (bold)
  - Description (optional)
  - Amount in ₹
  - Due date (if set)
  - **Mark as Paid** button
  
- **Empty State** if no debts

**Tab 2: Who Owes Me (Green)**
- Same layout as Tab 1 but with green theme
- Shows debts owed TO you
- Helps track credits to recover

**Features:**
- FAB button "Add Due"
- Add Due Dialog:
  - Person Name field (required)
  - Amount field (required, numeric validation)
  - Description field (optional)
  - Checkbox: "Someone owes ME money"
  - Validates before submission
  
- Mark as Paid:
  - PATCH request to backend
  - Removes from unpaid list
  - Shows success SnackBar
  
- Color-coded cards (Red/Green)
- Circular progress loading
- Error handling with retry

---

### 4. API Service Integration (`lib/services/api_service.dart`)

New methods already implemented:

```dart
// Analytics
Future<AnalyticsSummary> fetchAnalyticsSummary(int userId)

// Dues
Future<List<Due>> fetchDues(int userId, {bool includePaid = false})
Future<Due> createDue(int userId, Map<String, dynamic> payload)
Future<Due> markDuePaid(int dueId)
```

---

### 5. Navigation Updates

#### `lib/main.dart` - Providers & Routes

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TransactionProvider()),
    ChangeNotifierProvider(create: (_) => ThemeService()),
    ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
    ChangeNotifierProvider(create: (_) => DuesProvider()),
  ],
  // ...
)

routes: {
  '/': (_) => const DashboardScreen(),
  '/ledger': (_) => const LedgerScreen(),
  '/analytics': (_) => const AnalyticsScreen(),
  '/dues': (_) => const DuesManagerScreen(userId: 1),
},
```

---

## Integration Guide

### Backend Setup

1. **No additional migrations needed** — All models/tables already exist
2. **Verify routes** — Check `/dues` and `/analytics/summary` endpoints:
   ```bash
   curl -X GET "http://localhost/api/dues/?user_id=1"
   curl -X GET "http://localhost/api/analytics/summary?user_id=1"
   ```

### Flutter Integration

1. **Run dependencies:**
   ```bash
   cd flutter_app
   flutter pub get
   ```

2. **Verify imports in screens:**
   - All new screens use existing packages (fl_chart, provider, intl, etc.)
   - No additional pub.dev packages needed

3. **Navigation from Dashboard:**
   ```dart
   // In DashboardScreen, add navigation buttons:
   ElevatedButton(
     onPressed: () => Navigator.pushNamed(context, '/analytics'),
     child: const Text('📊 Analytics'),
   )
   
   ElevatedButton(
     onPressed: () => Navigator.pushNamed(context, '/dues'),
     child: const Text('💳 Dues'),
   )
   ```

4. **Update Transaction Creation** (manual entry form):
   ```dart
   DropdownButton(
     items: TransactionCategory.values.map((cat) => 
       DropdownMenuItem(
         value: cat,
         child: Text(cat.toString().split('.').last.toUpperCase()),
       )
     ).toList(),
     onChanged: (value) => setState(() => selectedCategory = value),
   )
   ```

---

## UI/UX Features

### Theme Integration
- Auto-switches between dark and light themes
- Persistent theme preference (SharedPreferences)
- Smooth transitions

### Color Scheme
- **Analytics**: Gradient cards (red-to-orange for spending)
- **Dues**: Red for "I Owe" (debit), Green for "Who Owes Me" (credit)
- Category emojis for visual recognition

### Responsive Design
- Charts scale with screen size
- Cards adapt to different screen densities
- Bottom navigation + FAB for easy access

### Error Handling
- Network error messages
- Retry buttons on failure
- Loading states with circular progress
- Empty state UI

---

## Testing Checklist

### Backend

- [ ] POST /dues/ — Create new due
- [ ] GET /dues/?user_id=1 — List dues
- [ ] PATCH /dues/{id}/pay — Mark as paid
- [ ] GET /analytics/summary?user_id=1 — Monthly totals
- [ ] GET /analytics/survival-forecast?user_id=1 — Survival metrics

### Frontend

- [ ] Theme toggle persists across app restart
- [ ] Analytics screen loads and displays chart data
- [ ] Dues screen shows separated "I Owe" vs "Owe to Me" lists
- [ ] Add Due form validates input
- [ ] Mark as Paid removes from unpaid list
- [ ] Navigation between tabs and screens works smoothly
- [ ] Error states show with retry buttons
- [ ] Refresh pulls latest data from API

---

## Future Enhancements

1. **Export Analytics** — PDF reports, email summaries
2. **Recurring Dues** — Auto-generate dues on interval
3. **Notifications** — Remind for due dates
4. **Splitting Expenses** — Split bills between users
5. **Budget Planning** — Set category budgets
6. **AI-Driven Categorization** — ML-based merchant recognition
7. **OCR Receipt Scanning** — Extract amounts from photos
8. **Real-time Sync** — WebSocket updates for shared expenses

---

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│        Flutter App (lib/)               │
├─────────────────────────────────────────┤
│ Screens:                                │
│ • DashboardScreen (home)               │
│ • AnalyticsScreen (charts)             │
│ • DuesManagerScreen (debts)            │
│ • LedgerScreen (transactions)          │
├─────────────────────────────────────────┤
│ Providers (State Management):           │
│ • TransactionProvider                   │
│ • AnalyticsProvider                     │
│ • DuesProvider                          │
│ • ThemeService                          │
├─────────────────────────────────────────┤
│ Services:                               │
│ • ApiService (Dio client)              │
└─────────────────────────────────────────┘
           ↓ HTTP (REST)
┌─────────────────────────────────────────┐
│      FastAPI Backend (app/)             │
├─────────────────────────────────────────┤
│ Routers:                                │
│ • /users  (authentication)             │
│ • /transactions (SMS parsing)          │
│ • /subscriptions (recurring)           │
│ • /analytics (forecasting)             │
│ • /dues (debt tracking)                │
├─────────────────────────────────────────┤
│ Services:                               │
│ • database.py (PostgreSQL/SQLite)      │
│ • sms_parser.py (regex extraction)     │
│ • forecaster.py (NumPy regression)     │
├─────────────────────────────────────────┤
│ Models (SQLAlchemy ORM):                │
│ • User                                  │
│ • Transaction                           │
│ • Subscription                          │
│ • Dues                                  │
└─────────────────────────────────────────┘
```

---

## Code Examples

### Adding a Due from Flutter

```dart
final payload = {
  'person_name': 'Rahul',
  'amount': 500.0,
  'description': 'Movie tickets',
  'is_owed_to_me': false,
};

context.read<DuesProvider>().addDue(userId, payload);
```

### Marking Due as Paid

```dart
context.read<DuesProvider>().markPaid(dueId);
```

### Accessing Analytics

```dart
final summary = context.watch<AnalyticsProvider>().summary;
if (summary != null) {
  print('Total Spent: ${summary.totalSpentCurrentMonth}');
  print('Breakdown: ${summary.categoryBreakdown}');
}
```

### Manual Transaction with Category

```dart
final transactionPayload = {
  'amount': 150.0,
  'transaction_type': 'debit',
  'merchant': 'Dominos Pizza',
  'category': 'food',  // Now required!
  'description': 'Dinner',
};

await _api.createTransaction(userId, transactionPayload);
```

---

## Troubleshooting

**Issue**: Dues not showing in UI
- **Solution**: Ensure `loadDues(userId)` called in `initState()`
- Check network connectivity
- Verify API endpoint returns data

**Issue**: Charts not rendering
- **Solution**: Ensure `fl_chart: ^0.68.0` in pubspec.yaml
- Check data is not empty before chart build
- Verify data format: `BalanceTrendPoint` must have valid date strings

**Issue**: Theme not persisting
- **Solution**: Call `SharedPreferences.getInstance()` before writing
- Ensure `ThemeService` is in MultiProvider
- Check disk space for persistent storage

**Issue**: Category not recognized
- **Solution**: Use exact enum values (lowercase): food, transport, entertainment, etc.
- Check backend sms_parser.py regex patterns
- Manually override category in transaction form

---

Generated: April 13, 2026
Last Updated: Implementation Complete ✅
