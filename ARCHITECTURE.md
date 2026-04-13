# 🏗️ ScholarSpend AI - Complete Architecture Guide

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER'S ANDROID DEVICE                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Flutter Mobile App                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  • Login Screen (Authentication)                     │ │ │
│  │  │  • Dashboard (Survival Counter)                      │ │ │
│  │  │  • Add Transaction Screen                           │ │ │
│  │  │  • Analytics / Stats Screen                         │ │ │
│  │  │  • Dues Manager                                     │ │ │
│  │  │  • Ledger View                                      │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────┬───────────────────────────────────────────┘
                       │ HTTPS/TLS
                       │ (Secure)
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
   LOCAL DEV                    CLOUD DEPLOYMENT
   (Testing)                    (Production)
   
┌─────────────────┐        ┌──────────────────────────────────────┐
│  LOCAL BACKEND  │        │     RAILWAY CLOUD PLATFORM           │
│                 │        │  ┌──────────────────────────────────┐│
│ FastAPI        │        │  │  FastAPI Container (Docker)       ││
│ Port: 8000     │        │  │  • Python 3.12                    ││
│                 │        │  │  • uvicorn server                 ││
│ SQLite DB      │        │  │  • HTTPS endpoint                 ││
│                 │        │  │  • Auto-scaling                   ││
└─────────────────┘        │  │  • Health monitoring              ││
                           │  └──────────────────┬───────────────┘│
                           │                     │                │
                           │  ┌────────────────────────────────┐ │
                           │  │  PostgreSQL Database           │ │
                           │  │  • Managed by Railway          │ │
                           │  │  • Automatic backups           │ │
                           │  │  • Async asyncpg driver        │ │
                           │  │  • Schema: users, transactions,│ │
                           │  │    subscriptions, dues         │ │
                           │  └────────────────────────────────┘ │
                           └──────────────────────────────────────┘
```

---

## Request Flow: Local Development

```
User Input (Login)
        ↓
[LoginScreen] in Flutter
        ↓
Calls: ApiService.createUser()
        ↓
HTTP POST to: http://192.168.20.5:8000/api/users/
        ↓
Local FastAPI Backend
        ↓
SQLite Database
        ↓
Response: {"id": 1, "name": "John", "balance": 10000}
        ↓
[LoginScreen] stores user ID → [AuthProvider]
        ↓
Navigate to [DashboardScreen]
```

---

## Request Flow: Cloud Deployment

```
User Input (Login)
        ↓
[LoginScreen] in Flutter
        ↓
Calls: ApiService.createUser()
        ↓
HTTPS POST to: https://scholarspend-xxx.up.railway.app/api/users/
        ↓
Railway Container (FastAPI)
        ↓
PostgreSQL (Managed by Railway)
        ↓
Response: {"id": 1, "name": "John", "balance": 10000}
        ↓
[LoginScreen] stores user ID → [AuthProvider]
        ↓
Navigate to [DashboardScreen]
```

---

## Backend Architecture

### API Endpoints

```
/health
├─ GET: Health check

/users
├─ POST: Create new user
├─ GET /{id}: Get user details
└─ PATCH /{id}: Update user balance

/transactions
├─ GET: List transactions (paginated)
├─ POST: Create transaction
├─ POST /sync: Batch import SMS
└─ DELETE /{id}: Remove transaction

/subscriptions
├─ GET: List subscriptions
├─ POST: Create subscription
└─ DELETE /{id}: Remove subscription

/analytics
├─ GET /survival-forecast: Crash date prediction
├─ GET /total-spent: All-time spending
├─ GET /monthly: Monthly breakdown
├─ GET /category: Category breakdown
├─ GET /leaderboard: User spending leaderboard
└─ GET /savings-potential: Savings opportunities

/dues
├─ GET: List dues
├─ POST: Create due
└─ DELETE /{id}: Remove due
```

### Database Schema

```
users
├─ id (Primary Key)
├─ name
├─ initial_balance
├─ current_balance
└─ created_at

transactions
├─ id (Primary Key)
├─ user_id (Foreign Key)
├─ amount
├─ category (enum)
├─ description
├─ created_at
└─ updated_at

subscriptions
├─ id (Primary Key)
├─ user_id (Foreign Key)
├─ name
├─ amount_per_month
├─ due_date
├─ active
└─ created_at

dues
├─ id (Primary Key)
├─ user_id (Foreign Key)
├─ amount
├─ due_date
├─ description
└─ created_at
```

---

## Flutter App Structure

### State Management (Provider Pattern)

```
lib/
├─ providers/
│  ├─ AuthProvider
│  │  └─ Manages user login, logout, user ID storage
│  ├─ TransactionProvider
│  │  └─ Fetch, create, update transactions
│  ├─ AnalyticsProvider
│  │  └─ Fetch spending stats, forecasts, charts
│  ├─ DuesProvider
│  │  └─ Fetch, create, update dues
│  └─ ThemeProvider
│     └─ Light/dark theme management
│
├─ screens/
│  ├─ LoginScreen (Authentication)
│  ├─ DashboardScreen (Survival Counter)
│  ├─ AddTransactionScreen (Manual Entry)
│  ├─ AnalyticsScreen (Stats & Charts)
│  ├─ DuesManagerScreen (Dues Management)
│  ├─ StatsScreen (Comprehensive Analytics)
│  └─ LedgerScreen (Transaction History)
│
├─ widgets/
│  ├─ SurvivalCounterCard
│  ├─ SpendingChart
│  ├─ CrashAlertBanner
│  └─ Custom UI Components
│
├─ models/
│  ├─ User
│  ├─ Transaction
│  ├─ AnalyticsSummary
│  ├─ Due
│  └─ Forecast
│
├─ services/
│  └─ ApiService (Dio HTTP Client)
│
└─ main.dart (App Entry Point)
```

### Service Layer (ApiService)

```dart
ApiService
├─ Base URL: https://your-backend-url.app/api
├─ Dio HTTP Client with timeout configuration
├─ User Management Methods
│  ├─ createUser()
│  └─ getUser()
├─ Transaction Methods
│  ├─ fetchTransactions()
│  ├─ createTransaction()
│  └─ deleteTransaction()
├─ Analytics Methods
│  ├─ fetchSurvivalForecast()
│  ├─ fetchTotalSpent()
│  ├─ fetchMonthlyAnalytics()
│  ├─ fetchCategoryBreakdown()
│  ├─ fetchLeaderboard()
│  └─ fetchSavingsPotential()
└─ Dues Methods
   ├─ fetchDues()
   ├─ createDue()
   └─ deleteDue()
```

---

## Deployment Architecture

### Before Cloud Deployment (Local)

```
Developer's Computer
├─ Docker Container (FastAPI)
├─ SQLite Database
└─ Flutter Emulator/Device connected via LAN
```

### After Cloud Deployment (Railway)

```
Global Internet
├─ Flutter App on Any Device (worldwide)
│  └─ HTTPS to Railway
│
└─ Railway Platform
   ├─ Compute: FastAPI Container (autoscaling)
   ├─ Database: PostgreSQL (managed, backed up)
   ├─ Monitoring: Real-time logs and metrics
   ├─ Scaling: Automatically handles traffic spikes
   ├─ HTTPS: SSL/TLS certificate auto-managed
   └─ Domain: Public URL (railway.app subdomain)
```

---

## Data Flow During Analytics Calculation

```
User Opens Analytics Screen
        ↓
[AnalyticsScreen] calls [AnalyticsProvider]
        ↓
AnalyticsProvider calls ApiService.fetchMonthlyAnalytics()
        ↓
HTTP GET to: /api/analytics/monthly?user_id=123
        ↓
Backend receives request
        ↓
Queries transactions table for user_id=123
        ↓
Groups by month, calculates sum, count, average
        ↓
NumPy calculates trends and forecasts
        ↓
Returns JSON response:
{
  "monthly": [
    {"month": "2024-01", "total": 5000, "count": 25},
    {"month": "2024-02", "total": 4800, "count": 22}
  ]
}
        ↓
[AnalyticsProvider] updates UI with data
        ↓
Charts render with fl_chart
        ↓
User sees beautiful analytics visualizations!
```

---

## Security Architecture

### Transport Security
- ✅ HTTPS/TLS on Railway (auto-managed)
- ✅ No HTTP (only HTTPS in production)
- ✅ Certificate renewal automatic

### Application Security
- ✅ CORS configured (allows Flutter app)
- ✅ Input validation (Pydantic)
- ✅ SQL injection prevention (SQLAlchemy ORM)
- ✅ Environment variables for secrets
- ✅ No hardcoded credentials

### Database Security
- ✅ Managed PostgreSQL (Railway)
- ✅ Automatic backups
- ✅ Network isolation
- ✅ Encrypted at rest

### Recommended for Production
- 🔐 Implement JWT tokens for authentication
- 🔐 Rate limiting on API endpoints
- 🔐 Database encryption keys
- 🔐 API key management
- 🔐 Audit logging

---

## Scaling Considerations

### Current Architecture (Good for MVP)
- ✅ Works for 100-1000 users
- ✅ < 100k transactions
- ✅ < 1MB daily data growth

### If You Need to Scale
1. **Add Caching**: Redis for popular queries
2. **Database Optimization**: Indexes on user_id, created_at
3. **CDN**: CloudFlare for static assets
4. **Load Balancing**: Railway auto-handles (horizontal scaling)
5. **Background Jobs**: Celery for long-running tasks
6. **Analytics Warehouse**: Move analytics to BigQuery/Snowflake

---

## Monitoring & Observability

### What Railway Provides
- ✅ Live logs (view in dashboard)
- ✅ Deployment history
- ✅ Build status
- ✅ Resource usage metrics
- ✅ Auto-restart on failure

### Recommended Additions (Optional)
- 📊 Error tracking: Sentry
- 📊 Performance monitoring: DataDog
- 📊 Uptime monitoring: StatusPage.io
- 📊 Analytics: Mixpanel, Segment

---

## Disaster Recovery

### Database Backups
- ✅ Railway manages PostgreSQL backups automatically
- ✅ Point-in-time recovery available
- ✅ Geographic redundancy available (paid tier)

### Code Disaster Recovery
- ✅ Git repository (GitHub) - source of truth
- ✅ Docker image (Railway) - container registry
- ✅ Environment variables (Railway secrets) - encrypted

### Recovery Procedure
1. Code backup: Just `git push`
2. Database backup: Railway auto-backs up
3. Disaster recovery: Redeploy from GitHub → automatic rebuild

---

## Cost Breakdown (Monthly)

| Item | Railway | Render | Vercel |
|------|---------|--------|--------|
| FastAPI Container | Free ($5 credit) | $7 | ❌ Not suitable |
| PostgreSQL | Included | $7 | N/A |
| Storage (10GB) | Included | Included | N/A |
| Bandwidth | Generous | Generous | N/A |
| **Total** | **~Free** | **~$14** | **N/A** |

---

## Deployment Success Criteria

After deploying to Railway:

✅ Backend builds without errors
✅ PostgreSQL database creates tables automatically
✅ Health check endpoint responds
✅ Swagger UI accessible at `/docs`
✅ Flutter app connects without errors
✅ User can log in
✅ Transactions save to database
✅ Analytics calculate correctly
✅ Charts render properly
✅ App works on physical device

**If all ✅, deployment is successful!** 🎉

---

## Next Steps

1. **Follow** [`RAILWAY_SETUP.md`](./RAILWAY_SETUP.md) to deploy
2. **Update** Flutter app with new backend URL
3. **Test** all features on physical device
4. **Monitor** Railway dashboard for issues
5. **Celebrate** - Your app is live in the cloud! 🚀

---

**Questions?** Check [`DEPLOYMENT.md`](./DEPLOYMENT.md) or [`QUICK_DEPLOY.md`](./QUICK_DEPLOY.md)

Happy deploying! ☁️✨
