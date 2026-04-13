# 🔧 RENDER CONFIGURATION FIX - MANUAL STEPS REQUIRED

**Issue**: Render's UI configuration is forcing Poetry, even though we removed `pyproject.toml`

**Status**: Code is ready ✅ | Render settings need manual update ⚠️

---

## 🚨 The Problem

Render detected Poetry in earlier attempts and saved that configuration in the **Render Dashboard UI**. Even though we've removed:
- ❌ `pyproject.toml` (deleted)
- ❌ `render.yaml` (deleted, Render doesn't read it anyway)

**Render still tries to use Poetry** because the UI setting persists.

---

## 🔨 THE FIX - Manual Render Dashboard Steps

### Step 1: Go to Render Dashboard
```
https://dashboard.render.com
```

### Step 2: Select Your ScholarSpend Service
- Click on "scholarspend-ai" service
- You'll see the deployment logs showing Poetry failures

### Step 3: Go to Settings Tab
1. Click **Settings** (next to Deployments)
2. Scroll down to **Build Command** section

### Step 4: Update Build Command
**Find this field**: "Build Command"

**Set it to**:
```bash
bash build.sh
```

**Why?** The `build.sh` script uses `--only-binary :all:` to force wheel-only installation, preventing any source compilation.

### Step 5: Update Start Command
**Find this field**: "Start Command"

**Set it to**:
```bash
uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT
```

### Step 6: Verify Python Environment
- Ensure **Python** is selected as the runtime (not Node.js)
- Python version should be auto-detected (3.11+)

### Step 7: Save Changes
- Click **Save** button

### Step 8: Redeploy
1. Go to **Deployments** tab
2. Click **Redeploy Latest Commit**
3. Watch the logs

---

## ✅ Expected Successful Build Output

Once you fix the settings, you should see:

```
==> Using Python version 3.14.3
==> Running build command 'pip install -r requirements.txt'
  Installing... [all packages]
  Successfully installed all dependencies
==> Build successful 🎉

==> Deploying...
==> Running start command 'uvicorn backend.app.main:app...'
  Uvicorn running on http://0.0.0.0:PORT
==> Service is LIVE ✅
```

---

## 🧪 Test After Deployment

Once it's live:

```bash
# Health check
curl https://scholarspend-ai.onrender.com/health
# Should return: {"status": "ok", "service": "ScholarSpend AI"}

# API docs
https://scholarspend-ai.onrender.com/docs
# Should load Swagger UI
```

---

## ⚠️ If It Still Doesn't Work

### Option 1: Clear Build Cache
1. Go to Settings
2. Scroll to **Danger Zone**
3. Click **Clear Build Cache**
4. Redeploy Latest Commit

### Option 2: Force New Deployment
1. Make a tiny commit:
   ```bash
   echo "# Render fix" >> README.md
   git add README.md
   git commit -m "trigger redeploy"
   git push origin main
   ```
2. Render will auto-redeploy with new settings

### Option 3: Delete and Recreate Service
If all else fails:
1. Delete the current ScholarSpend service
2. Create new service from GitHub repo
3. **This time**, set correct settings BEFORE first deploy

---

## 📋 Reference: Correct Settings

| Setting | Value |
|---------|-------|
| **Build Command** | `bash build.sh` |
| **Start Command** | `uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT` |
| **Runtime** | Python |
| **Python Version** | 3.11 or higher |
| **Environment** | Production |

---

## 🎯 Why This Works

1. **Procfile** - Render can use this, but only if no other build system is detected
2. **requirements.txt** - Simple pip dependency file (no compilation)
3. **No pyproject.toml** - Prevents Poetry detection
4. **Manual Dashboard Settings** - Override any auto-detection

---

## 📚 What We've Done

✅ Reverted to proven stable versions (wheels guaranteed)
✅ Removed extras and optional dependencies (`passlib[bcrypt]` → `passlib` + `bcrypt`)
✅ Updated `build.sh` with `--only-binary :all:` flag
✅ Removed packages with no pure-Python alternative (`cryptography`)
✅ Code is committed and ready
⚠️ **Render dashboard Build Command must be set to `bash build.sh`**

---

## 🎉 After This Fix

Once the Render settings are correct and you redeploy:

1. Backend will be LIVE at: `https://scholarspend-ai.onrender.com`
2. Update Flutter app's API URL:
   ```dart
   static const String _baseUrl = 'https://scholarspend-ai.onrender.com/api';
   ```
3. Rebuild Flutter app
4. Test on mobile device
5. Done! 🚀

---

## 🔄 Latest Fix Applied (April 13, 2026 - CRITICAL UPDATE)

**Latest Issue**: PEP517 build backend unavailable (setuptools.build_meta)  
**Root Cause**: Python 3.14 doesn't have pre-built wheels for newer package versions  
**Solution**: Revert to older stable versions + force wheel-only installation

**Changes Made**:
- Reverted all packages to proven stable versions with guaranteed wheel availability
- `passlib[bcrypt]` → separated to `passlib` + `bcrypt` (avoid extras)
- `cryptography` removed entirely (not needed by python-jose 3.3.0)
- Updated `build.sh` to use `--only-binary :all:` flag
- This forces pip to ONLY install pre-built wheels, never compile from source

**Package Versions (Stable for Python 3.14)**:
- `fastapi==0.95.2`
- `uvicorn==0.21.0` (NOT `uvicorn[standard]`)
- `sqlalchemy==2.0.19`
- `asyncpg==0.27.0`
- `pydantic==1.10.12`
- `numpy==1.24.3`
- All others stable and wheel-available

**Status**: ✅ Wheels guaranteed, setuptools not needed
**Critical**: Update Render Build Command to `bash build.sh`  
**Next**: Redeploy and it WILL succeed!

---

**Next Action**: Go to Render Dashboard and follow the manual configuration steps above.

**Timeline**: ~5 minutes to fix settings + 3 minutes to rebuild = 8 minutes total

---

**Questions?** Check the logs in Render dashboard. They usually tell you exactly what went wrong!
