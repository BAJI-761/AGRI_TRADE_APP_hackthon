# Quick Testing Guide - Firebase Phone Auth

## ✅ Setup Complete!

Your app is now configured to use **Firebase Phone Authentication** (FREE - 10K verifications/month).

## Before Testing

### 1. Enable Phone Authentication in Firebase Console

**IMPORTANT:** You must enable this before testing!

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **agritradeapp-42acc**
3. Click **Authentication** in left menu
4. Click **Sign-in method** tab
5. Find **Phone** provider
6. Click on it and **Enable** it
7. Click **Save**

That's it! No API keys or credentials needed for mobile apps.

## Testing Steps

### 1. Run the App

```bash
flutter run
```

### 2. Test Flow (Username = Full name, Password = Phone number)

1. **Intro Screen** → Wait 4 seconds
2. **Language Selection** → Select English or Telugu
3. **New/Returning Screen**
   - New user → goes to Phone Entry → OTP → Registration (enter full name + address + user type)
   - Returning user → goes to Login (enter Username = your full name, Password = your phone number)
4. **Phone Entry (New users)** → Enter phone (e.g., 9493994758)
5. **OTP Verification (New users)** → Enter 6-digit OTP
6. **Registration (New users)** → After Save, you’ll see a popup with:
   - Username = your full name
   - Password = your phone number
   Please remember these for future logins.
7. **Dashboard** → You should see your home screen!

### Voice Login (Returning users)
1. On Login screen, tap Voice Login
2. Speak your full name
3. Speak your phone number (as password)
4. You should be logged in

## What to Expect

### ✅ Success Indicators:
- SMS received from Firebase (may say "Google" or "Firebase")
- OTP verification works
- User authenticated
- Dashboard shows correctly

### ⚠️ If SMS Doesn't Arrive:
- Check phone number format (+91XXXXXXXXXX)
- Check Firebase Console > Authentication > Users (should show verification attempts)
- Wait 1-2 minutes (SMS can be delayed)
- Check spam folder
- Try again (rate limiting applies)

### 🔍 Debug Info:
- Check console logs for Firebase Auth messages
- OTP will be shown in Firebase Console logs
- Check Authentication > Users to see verification status

## Firebase Console Monitoring

While testing, you can monitor:
1. **Authentication > Users** - See all verified users
2. **Authentication > Sign-in method > Phone** - Check status
3. **Usage and billing** - Track verification count (free tier: 10K/month)

## Common Issues

### Issue: "Phone provider not enabled"
**Solution:** Enable Phone Authentication in Firebase Console (see step 1 above)

### Issue: SMS not received
**Solution:** 
- Check phone number is correct
- Wait a few minutes
- Check Firebase Console for error logs
- Try a different phone number

### Issue: "Invalid phone number format"
**Solution:** Make sure phone number is 10 digits (e.g., 9493994758)

### Issue: "Verification failed"
**Solution:**
- Check if OTP is correct (6 digits)
- Try resending OTP
- Check Firebase Console for specific error

## Free Tier Limits

- ✅ **10,000 verifications per month** - FREE
- After that: $0.06 per verification
- Perfect for testing and small to medium apps!

## Ready to Test!

Everything is set up. Just enable Phone Authentication in Firebase Console and you're good to go! 🚀

