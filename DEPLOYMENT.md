# ScholarSpend AI - Backend Deployment Guide

This guide walks you through deploying the FastAPI backend to a public cloud service.

## Option 1: Railway (Recommended - Easiest)

Railway is the easiest option for FastAPI deployment with a generous free tier.

### Prerequisites
- GitHub account (where your code is stored)
- Railway account: https://railway.app/

### Steps

1. **Sign up for Railway**
   - Go to https://railway.app/
   - Click "Start Free" → Sign up with GitHub
   - Authorize Railway to access your GitHub

2. **Create a Railway Project**
   - Go to Dashboard → New Project → Deploy from GitHub repo
   - Select `scholarspend-ai` repository
   - Choose the repository (if prompted)

3. **Configure Environment Variables**
   - Railway will ask which service to deploy
   - Select the `backend` folder (or let it auto-detect the Dockerfile)
   - Add environment variables:
     - `DATABASE_URL`: Railway will create a PostgreSQL plugin
     - `PORT`: Set to `8000`

4. **Add PostgreSQL Database**
   - Click "Add → Add Database → PostgreSQL"
   - Railway automatically configures `DATABASE_URL`

5. **Deploy**
   - Railway automatically deploys when you push to GitHub
   - Monitor the deployment in the Dashboard
   - Once deployed, you'll see a public URL like: `https://scholarspend-ai-production-xxxx.up.railway.app`

6. **Update Flutter App**
   - Replace the `_baseUrl` in `api_service.dart`:
     ```dart
     static const String _baseUrl = 'https://scholarspend-ai-production-xxxx.up.railway.app/api';
     ```
   - Rebuild and test

---

## Option 2: Render (Alternative)

Render is also excellent and offers a simple deployment process.

### Prerequisites
- GitHub account
- Render account: https://render.com/

### Steps

1. **Sign up for Render**
   - Go to https://render.com/ → Sign up with GitHub
   - Authorize Render to access your GitHub

2. **Create a Web Service**
   - Dashboard → New → Web Service
   - Select the `scholarspend-ai` repository
   - Configure:
     - **Name**: `scholarspend-ai`
     - **Root Directory**: `backend`
     - **Environment**: Docker
     - **Build Command**: (leave default)
     - **Start Command**: (leave default)

3. **Add Environment Variables**
   - Add a PostgreSQL database first (Render → New → PostgreSQL)
   - Copy the connection string from the database
   - In the Web Service settings, add `DATABASE_URL` environment variable

4. **Deploy**
   - Click "Deploy"
   - Render deploys from your GitHub repo
   - Once done, you'll get a public URL like: `https://scholarspend-ai.onrender.com`

5. **Update Flutter App**
   - Replace the `_baseUrl` in `api_service.dart`:
     ```dart
     static const String _baseUrl = 'https://scholarspend-ai.onrender.com/api';
     ```
   - Rebuild and test

---

## Option 3: Vercel (For Next.js/Static) - NOT RECOMMENDED for FastAPI

Vercel is designed for serverless functions, not long-running FastAPI apps. Skip this.

---

## Updating Your Flutter App After Deployment

Once your backend is deployed, update the API service:

### File: `flutter_app/lib/services/api_service.dart`

```dart
class ApiService {
  // Replace with your deployed backend URL
  static const String _baseUrl = 'https://your-deployed-url.app/api';

  // Rest of the code stays the same...
}
```

Then:
1. Rebuild the Flutter app: `flutter pub get && flutter run`
2. Test all endpoints (login, transactions, analytics, etc.)
3. Build and deploy the APK with the new backend URL

---

## Post-Deployment Checklist

- [ ] Backend deploys successfully to cloud service
- [ ] Database is created and accessible
- [ ] API health check passes: `https://your-url/health`
- [ ] Flutter app connects to new backend URL
- [ ] User creation works (login screen)
- [ ] Transaction endpoints work
- [ ] Analytics endpoints work
- [ ] Dues endpoints work
- [ ] APK rebuilt with new URL and deployed to device
- [ ] All features tested on physical device with cloud backend

---

## Troubleshooting

### Backend fails to start
- Check logs in Railway/Render dashboard
- Ensure `requirements.txt` has all dependencies
- Verify `DATABASE_URL` environment variable is set
- Check that Dockerfile is correct

### Flutter can't connect to backend
- Verify the URL in `api_service.dart` is correct
- Check that API endpoints match backend routes
- Add CORS headers if needed (already configured in main.py)
- Test the URL in a browser: `https://your-url/health`

### Database connection errors
- Verify `DATABASE_URL` environment variable format
- Check database is running and accessible
- For Railway/Render, ensure PostgreSQL add-on is active

---

## CI/CD Setup (Optional)

Both Railway and Render automatically deploy when you push to GitHub. To make this automatic:

1. Push code to GitHub: `git push origin main`
2. Railway/Render automatically detects changes and redeploys
3. Monitor in dashboard for deployment status

---

## Cost Breakdown

### Railway
- **Free tier**: $5/month credit (plenty for testing)
- **PostgreSQL**: Included in free tier
- **Overage**: $0.08/hour for compute

### Render
- **Free tier**: Limited (single shared instance)
- **Starter tier**: $7/month (recommended for production)
- **PostgreSQL**: $7/month (recommended)

Both are highly affordable for a student project!

---

## Next Steps

1. Choose **Railway** (recommended) or **Render**
2. Follow the deployment steps above
3. Update `api_service.dart` with the new backend URL
4. Rebuild and test the Flutter app
5. Deploy APK to device
6. Perform end-to-end testing

Good luck! 🚀
