# How to Switch SMS Providers

## Quick Switch Guide

Your app now uses an abstraction layer, making it easy to switch between providers.

### Step 1: Choose Your Provider

Based on the comparison guide (`OTP_PROVIDER_COMPARISON.md`):
- **For India:** Use MSG91 (recommended)
- **For Global:** Use Plivo or Vonage
- **For Budget:** Use TextLocal or Fast2SMS

### Step 2: Update `main.dart`

Simply change one line:

**Current (Twilio):**
```dart
Provider(create: (context) => TwilioService()),
```

**New (MSG91):**
```dart
Provider(create: (context) => MSG91Service()),
```

### Step 3: Update Environment Variables

**For MSG91:**
```bash
flutter run --dart-define=MSG91_AUTH_KEY=your_auth_key --dart-define=MSG91_SENDER_ID=your_sender_id
```

**For Production:**
- Add to your CI/CD pipeline
- Or use environment configuration files

### Step 4: Test

That's it! The rest of your app (phone input, OTP verification screens) will work exactly the same.

## MSG91 Setup (Recommended for India)

1. **Sign Up:** Go to https://msg91.com and create account
2. **Get Credentials:**
   - Auth Key (from dashboard)
   - Sender ID (register 6-digit ID after DLT approval)
3. **DLT Registration:**
   - Register your entity
   - Get template approved
   - Use template ID in code
4. **Update Code:**
   - Replace `'your_template_id'` in `msg91_service.dart` with your actual template ID
   - Update `_senderId` with your 6-digit sender ID

## Advantages of Switching to MSG91

✅ **No Number Verification Needed** - Works immediately for all Indian numbers
✅ **Better Delivery Rates** - Optimized for Indian networks
✅ **Much Cheaper** - ₹0.15 per SMS vs $0.0075 (Twilio)
✅ **DLT Compliant** - Proper support for Indian regulations
✅ **Better Support** - Indian company, local support

## Cost Comparison (1000 SMS/month)

| Provider | Cost per SMS | Monthly Cost (1000 SMS) |
|----------|-------------|-------------------------|
| Twilio   | $0.0075     | $7.50 (~₹625)          |
| MSG91    | ₹0.15       | ₹150 (~$1.80)          |
| TextLocal| ₹0.10       | ₹100 (~$1.20)          |
| Fast2SMS | ₹0.05       | ₹50 (~$0.60)           |

**Savings:** Switching to MSG91 saves ~75% compared to Twilio!

## Testing

Even without setting up MSG91 account, the service will work in test mode:
- OTP is stored in memory
- Verification works
- No actual SMS sent until you configure credentials

## Current Status

Your app currently:
- ✅ Works with in-memory OTP (test mode)
- ✅ Shows OTP on screen when SMS fails
- ✅ Ready to switch to any provider

Just update `main.dart` and add environment variables!

