# ScholarSpend AI - Railway Deployment (Step-by-Step)

## ✅ What You Need
- ✅ GitHub account with `scholarspend-ai` repo
- ✅ Code already pushed to GitHub
- ✅ Railway.app account (free signup)

## 🚀 Quick Deployment (5 minutes)

### Step 1: Sign in to Railway
1. Go to **https://railway.app/**
2. Click **Start Free**
3. Click **Sign up with GitHub**
4. Authorize Railway to access your GitHub account

### Step 2: Create a New Project
1. On Dashboard, click **New Project**
2. Click **Deploy from GitHub repo**
3. Search for and select **scholarspend-ai** repository
4. Click **Deploy Now**

### Step 3: Configure the Backend Service
Railway should automatically detect your Dockerfile. If not:
1. Click on the **backend** service
2. Verify:
   - Root Directory: `backend` ✓
   - Dockerfile: `Dockerfile` ✓

### Step 4: Add a PostgreSQL Database
1. In the project, click **New**
2. Select **Add Database → PostgreSQL**
3. Let Railway create and configure it
4. Railway automatically adds `DATABASE_URL` to your backend environment

### Step 5: Watch the Deployment
1. Go to the **Deployments** tab
2. Watch the build progress
3. Once done (green checkmark), your backend is live! 🎉

### Step 6: Get Your URL
1. Click on the **backend** service card
2. Look for the **Public URL** (e.g., `https://scholarspend-ai-prod-xxx.up.railway.app`)
3. Copy this URL

### Step 7: Update Your Flutter App

Edit **`flutter_app/lib/services/api_service.dart`**:

```dart
class ApiService {
  // REPLACE with your Railway URL
  static const String _baseUrl = 'https://your-railway-url.up.railway.app/api';
  
  // Keep the rest the same...
}
```

### Step 8: Test the Connection
Open a browser and visit:
```
https://your-railway-url.up.railway.app/health
```

You should see:
```json
{"status": "ok", "service": "ScholarSpend AI"}
```

### Step 9: Rebuild Flutter App
```bash
cd flutter_app
flutter pub get
flutter clean
flutter run
```

Or build APK:
```bash
flutter build apk --release
```

### Step 10: Test Everything
1. Login (create new user)
2. Add transaction
3. Check analytics
4. Verify all features work

---

## 📊 After Deployment

Every time you push code to GitHub:
```bash
git add .
git commit -m "Update backend"
git push origin main
```

Railway automatically rebuilds and deploys! ✨

---

## 🔗 Useful Links
- **Railway Dashboard**: https://railway.app/dashboard
- **Your Project Deployments**: https://railway.app/project/[project-id]
- **Backend Service URL**: Check in Railway dashboard under service details
- **Health Check**: `{your-url}/health`
- **Swagger API Docs**: `{your-url}/docs`

---

## ❓ Troubleshooting

### "Build failed" error
- Check Railway logs (click Deployments tab)
- Look for error messages
- Common issues:
  - Missing dependencies in `requirements.txt`
  - Dockerfile syntax error
  - Environment variables not set

### "Cannot connect to backend"
- Verify the URL in `api_service.dart`
- Test in browser: `https://your-url/health`
- Check that URL matches Railway public URL exactly
- Ensure no typos

### "Database connection error"
- Verify PostgreSQL add-on is active
- Check `DATABASE_URL` is set in Railway environment
- Wait a few seconds after creating database

### Backend works but Flutter can't connect
- Make sure Flutter app URL has `/api` suffix
- Example: `https://your-url.up.railway.app/api` ✓
- NOT: `https://your-url.up.railway.app` ✗

---

## 💰 Cost
**Railway Free Tier**: $5/month credit (plenty for testing!)

---

## 🎉 Done!
Your ScholarSpend AI backend is now live in the cloud! 🚀
