# ScholarSpend AI 🎓💸

> **A financial stability tool for students** — know exactly how many days your money will last.

## Architecture

![Architecture](docs/architecture.png)

Built with **FastAPI + Flutter**, powered by SMS parsing and NumPy linear regression.

| Layer | Stack |
|-------|-------|
| Mobile Frontend | Flutter (Provider, fl_chart) |
| Backend API | FastAPI + SQLAlchemy (async) |
| Database | PostgreSQL 16 |
| SMS Parsing | Python Regex Engine |
| Forecasting | NumPy Linear Regression |
| Infrastructure | Docker + Nginx |

---

## Core Features

- 🛡️ **Survival Counter** — `current_balance / avg_daily_spend` = days you can survive
- 📲 **SMS Auto-Import** — Parses bank SMS alerts (HDFC, SBI, ICICI, Axis, Kotak, Paytm, PhonePe) into structured transactions
- 📉 **Predictive Crash Alerts** — Linear regression forecasts your zero-balance date
- 📊 **Spending Breakdown** — Category pie chart (Food, Transport, Entertainment, Education, etc.)
- 🔄 **Subscription Tracker** — Accounts for recurring charges in the crash-date forecast

---

## Project Structure

```
scholarspend-ai/
├── docker-compose.yml
├── nginx/nginx.conf
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       ├── main.py           # FastAPI app
│       ├── models.py         # SQLAlchemy ORM
│       ├── schemas.py        # Pydantic v2 schemas
│       ├── database.py       # Async PostgreSQL engine
│       ├── crud.py           # DB operations
│       ├── sms_parser.py     # Regex SMS parser
│       ├── forecaster.py     # NumPy crash-date engine
│       └── routers/          # users, transactions, subscriptions, analytics
└── flutter_app/
    └── lib/
        ├── providers/        # TransactionProvider (SMS + API)
        ├── screens/          # Dashboard + Ledger
        ├── widgets/          # SurvivalCounterCard, SpendingChart, CrashAlertBanner
        ├── models/           # Transaction, Forecast
        └── services/         # ApiService (Dio)
```

---

## Quick Start

### Backend + Database + Nginx

```bash
docker-compose up --build
# API available at http://localhost/api
# Swagger docs at http://localhost/docs
```

### Flutter App (Android)

```bash
cd flutter_app
flutter pub get
flutter run
```

> ⚠️ Add `RECEIVE_SMS` and `READ_SMS` to `android/app/src/main/AndroidManifest.xml`

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/users/` | Register a new user |
| `POST` | `/transactions/sync` | Batch-import parsed SMS messages |
| `GET` | `/transactions/` | List transactions (paginated) |
| `POST` | `/subscriptions/` | Add a recurring subscription |
| `GET` | `/analytics/survival-forecast` | **Core endpoint** — days left & crash date |
| `GET` | `/health` | Health check |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql+asyncpg://scholar:scholar@localhost:5432/scholarspend` | PostgreSQL connection string |

---

## 🚀 Deployment

### Local Development
```bash
docker-compose up --build
# Backend: http://localhost/api
# Swagger: http://localhost/docs
```

### Cloud Deployment (Recommended for Mobile)

The backend is ready for cloud deployment! Choose your platform:

#### **Railway** (Recommended - 5 min setup)
1. Sign up at https://railway.app/ with GitHub
2. Create new project → Deploy from repo → Select `scholarspend-ai`
3. Railway adds PostgreSQL automatically
4. Get your public URL and update Flutter app

**See**: [`RAILWAY_SETUP.md`](./RAILWAY_SETUP.md) for step-by-step guide

#### **Render** (Alternative)
1. Sign up at https://render.com/ with GitHub
2. Create Web Service → Select repo → Configure with Dockerfile
3. Add PostgreSQL database
4. Deploy and get public URL

**See**: [`DEPLOYMENT.md`](./DEPLOYMENT.md) for all options

### Update Flutter App After Deployment

Edit `flutter_app/lib/services/api_service.dart`:
```dart
class ApiService {
  // Replace with your deployed URL
  static const String _baseUrl = 'https://your-deployed-url.app/api';
}
```

Then rebuild:
```bash
cd flutter_app
flutter pub get
flutter build apk --release
```

---

## 📋 Deployment Checklist

- [ ] Backend deployed to Railway/Render
- [ ] PostgreSQL database created
- [ ] API health check passes: `https://your-url/health`
- [ ] Flutter app updated with new backend URL
- [ ] All features tested on mobile device
  - [ ] User registration/login
  - [ ] Transaction creation
  - [ ] Analytics/stats display
  - [ ] Dues management

---

## Built for Hackathon 🏆

ScholarSpend AI was built as a hackathon project to help students avoid the classic "broke before month end" problem by making financial data actionable and visible.
