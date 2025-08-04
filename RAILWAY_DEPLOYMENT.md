# 🚀 Railway Deployment Guide

## Step-by-Step Deployment Process

### 1. Create Railway Account
- Go to https://railway.app
- Sign up with GitHub (recommended)
- Verify your account

### 2. Deploy Your Backend

#### Option A: Deploy from GitHub (Recommended)
1. **Push your code to GitHub** (if not already done):
   ```bash
   git add .
   git commit -m "Prepare for Railway deployment"
   git push origin main
   ```

2. **In Railway Dashboard**:
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository
   - Select the `backend` folder as root directory

#### Option B: Deploy using Railway CLI
1. **Install Railway CLI**:
   ```bash
   npm install -g @railway/cli
   ```

2. **Login and deploy**:
   ```bash
   cd backend
   railway login
   railway init
   railway up
   ```

### 3. Configure Environment Variables
In Railway Dashboard → Your Project → Variables, add:
- `GROQ_API_KEY`: Your Groq API key
- `RAILWAY_ENVIRONMENT`: production

### 4. Get Your Backend URL
After deployment, Railway will give you a URL like:
`https://your-app-name.up.railway.app`

### 5. Update Flutter App
Replace in `lib/services/api_service.dart`:
```dart
static String _baseUrl = 'https://YOUR-ACTUAL-URL.up.railway.app';
```

### 6. Test Your Deployment
Visit: `https://your-url.up.railway.app/health`
Should return: `{"status": "healthy", ...}`

## 🔧 Troubleshooting

### Common Issues:
1. **Build fails**: Check `requirements.txt` is in backend folder
2. **App crashes**: Check environment variables are set
3. **CORS errors**: Already configured in app.py
4. **Timeout**: Increase timeout in Railway settings

### Logs:
- View logs in Railway Dashboard → Your Project → Deployments → View Logs

## 📱 Testing with Flutter

### Development:
```bash
flutter run
```

### Build APK:
```bash
flutter build apk --release
```

The APK will work with your hosted backend!

## 💰 Cost Management

### Railway Free Tier:
- $5/month credit (auto-renewed)
- 500 hours runtime
- Sleeps after 30min inactivity (wakes up automatically)

### Keep costs low:
- App sleeps when not used (saves credits)
- Monitor usage in Railway dashboard
- Optimize API calls in Flutter app

## 🚀 Going Live Checklist

- [ ] Backend deployed successfully
- [ ] Environment variables configured
- [ ] Health endpoint responding
- [ ] Flutter app updated with production URL
- [ ] APK built and tested
- [ ] Document generation working
- [ ] Diagram generation working
- [ ] App handles offline scenarios

## 📞 Support

If you encounter issues:
1. Check Railway logs
2. Test endpoints manually
3. Verify Flutter app URLs
4. Check this guide again

Your app should now work seamlessly with the hosted backend!