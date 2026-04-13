# ⚡ Quick Reference - ScholarSpend AI Deployment

## 📋 One-Page Deployment Checklist

### Pre-Deployment
- [ ] Code pushed to GitHub
- [ ] All tests passing locally
- [ ] Backend runs with `docker-compose up --build`

### Railway Deployment (5 min)
- [ ] Sign up at https://railway.app/
- [ ] New Project → Deploy from GitHub
- [ ] Select `scholarspend-ai` repo
- [ ] Add PostgreSQL database
- [ ] Wait for build to complete
- [ ] Copy public URL from Railway dashboard

### Update Flutter App
- [ ] Edit: `flutter_app/lib/services/api_service.dart`
- [ ] Replace: `static const String _baseUrl = 'https://your-railway-url.app/api';`
- [ ] Save file

### Test Deployment
- [ ] Browser: `https://your-url/health` → See `{"status": "ok"}`
- [ ] Browser: `https://your-url/docs` → See Swagger UI
- [ ] Flutter: Run app and test login
- [ ] Flutter: Test all features (transactions, analytics, dues)

### Build & Deploy APK
- [ ] Terminal: `cd flutter_app`
- [ ] Terminal: `flutter pub get && flutter clean`
- [ ] Terminal: `flutter build apk --release`
- [ ] APK ready at: `build/app/outputs/apk/release/app-release.apk`
- [ ] Install on device via: `adb install build/app/outputs/apk/release/app-release.apk`

### Final Testing
- [ ] App installs on device
- [ ] App connects to cloud backend
- [ ] User login works
- [ ] Transaction creation works
- [ ] Analytics display correctly
- [ ] All screens load properly

---

## 🔗 Important URLs

### Your Railway Project
- Dashboard: https://railway.app/dashboard
- Deploy logs: https://railway.app/project/[project-id]

### Your Backend
- Health check: `https://your-railway-url.up.railway.app/health`
- Swagger docs: `https://your-railway-url.up.railway.app/docs`
- API base: `https://your-railway-url.up.railway.app/api`

### Your GitHub Repo
- Repo: https://github.com/DrNotSoStrange05/scholarspend-ai
- Commits: https://github.com/DrNotSoStrange05/scholarspend-ai/commits/main

---

## 🆘 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Build fails on Railway | Check logs in Railway dashboard |
| Can't connect from Flutter | Verify URL includes `/api` suffix |
| Database not connecting | Ensure PostgreSQL add-on is active |
| "Connection refused" error | Wait 30 seconds for backend to start |
| CORS errors | Already configured in `main.py` |
| APK installation fails | `adb install -r` to reinstall |
| App can't find backend | Check exact URL matches Railway public URL |

---

## 📱 Flutter Base URL Format

### Wrong ❌
```dart
static const String _baseUrl = 'https://your-railway-url.up.railway.app';
```

### Correct ✓
```dart
static const String _baseUrl = 'https://your-railway-url.up.railway.app/api';
```

---

## 🎯 Expected Results After Deployment

✅ Backend is live globally (accessible from anywhere)
✅ Flutter app connects to backend from mobile device
✅ Users can create accounts
✅ Transactions are saved to cloud database
✅ Analytics calculated from cloud data
✅ Charts and stats display correctly
✅ Multiple users can use the app simultaneously
✅ Data persists across app restarts

---

## 📞 Support

For detailed guides, see:
- Full guide: [`RAILWAY_SETUP.md`](./RAILWAY_SETUP.md)
- All options: [`DEPLOYMENT.md`](./DEPLOYMENT.md)
- Summary: [`DEPLOYMENT_SUMMARY.md`](./DEPLOYMENT_SUMMARY.md)

---

**Ready to go live? Start with Railway! 🚀**
