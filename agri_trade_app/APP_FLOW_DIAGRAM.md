# AgriTrade App - Complete Flow Chart

## Complete User Journey Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         APP LAUNCH (main.dart)                               │
│  - Initialize Firebase                                                       │
│  - Setup Providers (Auth, Voice, Offline, Language, Twilio)                │
│  - Show IntroScreen                                                          │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        INTRO SCREEN (Splash)                                  │
│  - Animations (4 seconds)                                                    │
│  - Auto-navigate                                                             │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      AUTH WRAPPER (First Check)                              │
│  Checks: Language selected?                                                  │
└───────────┬──────────────────────────────────────────────────────────────────┘
            │
            ├─── NO ───────────────────────────┬─── YES ─────────────────────┐
            │                                    │                              │
            ▼                                    │                              │
┌───────────────────────┐                      │                              │
│ LANGUAGE SELECTION    │                      │                              │
│ SCREEN                │                      │                              │
│                       │                      │                              │
│ Options:              │                      │                              │
│ - English             │                      │                              │
│ - Telugu              │                      │                              │
│ - Skip (default EN)   │                      │                              │
└───────────┬───────────┘                      │                              │
            │                                    │                              │
            └────────────────────────────────────┴──────────────────────────────┘
                                                │
                                                ▼
                                    ┌───────────────────────────┐
                                    │  AUTH WRAPPER             │
                                    │  (Second Check)           │
                                    │  Checks: Authenticated?    │
                                    └───────────┬───────────────┘
                                                │
                    ┌───────────────────────────┴───────────────────────────┐
                    │                                                         │
                    ▼                                                         ▼
        ┌───────────────────────────┐                          ┌──────────────────────────┐
        │ NOT AUTHENTICATED         │                          │ AUTHENTICATED             │
        │                           │                          │                           │
        │ Show: NewReturningScreen  │                          │ Check UserType            │
        └───────────┬───────────────┘                          └───────────┬──────────────┘
                    │                                                    │
                    ▼                                                    │
    ┌───────────────────────────────┐                                  │
    │  NEW/RETURNING SCREEN          │                                  │
    │                                │                                  │
    │ Voice Prompt:                  │                                  │
    │ "Say New or Returning"         │                                  │
    └───────┬────────────────────────┘                                  │
            │                                                            │
    ┌───────┴───────┐                                                  │
    │               │                                                    │
    ▼               ▼                                                    │
┌──────────┐  ┌──────────────┐                                         │
│ I AM NEW │  │I AM RETURNING│                                         │
└────┬─────┘  └──────┬───────┘                                         │
     │                │                                                   │
     └────────┬───────┘                                                   │
              │                                                           │
              ▼                                                           │
┌─────────────────────────────────────────────────────────┐             │
│          PHONE NUMBER ENTRY SCREEN                       │             │
│                                                          │             │
│ Input Methods:                                           │             │
│ - Voice Input (Telugu/English number recognition)        │             │
│ - Manual Text Entry                                      │             │
│                                                          │             │
│ Action: Click "Send OTP"                                │             │
└──────────────────────┬──────────────────────────────────┘             │
                       │                                                  │
                       ▼                                                  │
┌─────────────────────────────────────────────────────────┐             │
│  TWILIO SERVICE - sendOTP()                              │             │
│                                                          │             │
│ Process:                                                 │             │
│ 1. Normalize phone → +919876543210                      │             │
│ 2. Generate 6-digit OTP                                 │             │
│ 3. Store in memory (normalized phone as key)            │             │
│ 4. Send SMS via Twilio API                              │             │
└──────────────────────┬──────────────────────────────────┘             │
                       │                                                  │
              ┌────────┴────────┐                                         │
              │                 │                                         │
              ▼                 ▼                                         │
    ┌─────────────┐   ┌─────────────────┐                                │
    │ SUCCESS     │   │ FAILURE         │                                │
    │ (201)       │   │ (400/500/error) │                                │
    │             │   │                 │                                │
    │ Navigate to │   │ Show Error      │                                │
    │ OTP Screen  │   │ Dialog          │                                │
    │             │   │ "Failed to send │                                │
    │             │   │  OTP. Try again"│                                │
    └──────┬──────┘   └────────┬─────────┘                                │
           │                   │                                           │
           └───────────────────┘                                           │
                       │                                                    │
                       ▼                                                    │
┌─────────────────────────────────────────────────────────┐               │
│        OTP VERIFICATION SCREEN                           │               │
│                                                          │               │
│ Features:                                                │               │
│ - Voice Input (Telugu/English OTP recognition)          │               │
│ - Manual 6-digit PIN input (auto-verify at 6 digits)    │               │
│ - Resend OTP button (60s countdown)                     │               │
│ - Back button DISABLED (WillPopScope)                   │               │
│ - Test mode shows OTP in debug box                      │               │
└──────────────────────┬──────────────────────────────────┘               │
                       │                                                    │
                       ▼                                                    │
        ┌───────────────────────────┐                                      │
        │ TWILIO SERVICE             │                                      │
        │ verifyOTP(phone, otp)      │                                      │
        │                             │                                      │
        │ - Normalize phone           │                                      │
        │ - Lookup stored OTP        │                                      │
        │ - Compare values           │                                      │
        └───────┬───────────────────┘                                      │
                │                                                            │
        ┌───────┴────────┐                                                  │
        │                │                                                  │
        ▼                ▼                                                  │
┌──────────────┐  ┌──────────────┐                                         │
│ VALID OTP    │  │ INVALID OTP  │                                         │
└──────┬───────┘  └──────┬───────┘                                         │
       │                 │                                                  │
       │                 ▼                                                  │
       │    ┌─────────────────────────┐                                    │
       │    │ Show Invalid OTP Dialog │                                    │
       │    │ "Please enter valid     │                                    │
       │    │  6-digit OTP"           │                                    │
       │    │ Options: Try Again       │                                    │
       │    └─────────────────────────┘                                    │
       │                                                                     │
       ▼                                                                     │
┌─────────────────────────────────────────────────────────┐               │
│ AUTH SERVICE                                             │               │
│ loadUserByPhone(phoneNumber)                             │               │
│                                                          │               │
│ Process:                                                 │               │
│ - Normalize phone                                        │               │
│ - Query Firestore: users/{phoneE164}                    │               │
│ - Parse document data                                    │               │
└───────┬──────────────────────────────────────────────────┘               │
        │                                                                    │
        ├──────────────────────┬───────────────────────────┐               │
        │                      │                           │               │
        ▼                      ▼                           ▼               │
┌──────────────┐    ┌──────────────────┐      ┌──────────────────────┐   │
│ USER FOUND   │    │ USER NOT FOUND   │      │ NETWORK ERROR        │   │
│              │    │ (New User)       │      │                      │   │
│ Load profile:│    │                  │      │ Show Error Dialog    │   │
│ - name       │    │ Navigate to:     │      │ Retry or Go Back     │   │
│ - address    │    │ RegistrationProfile│   └──────────────────────┘   │
│ - userType   │    │   Screen         │                                  │
│              │    │                  │                                  │
│ Set auth     │    │                  │                                  │
│ state        │    │                  │                                  │
└──────┬───────┘    └────────┬─────────┘                                  │
       │                     │                                             │
       │                     ▼                                             │
       │    ┌─────────────────────────────────────────┐                    │
       │    │ REGISTRATION PROFILE SCREEN             │                    │
       │    │                                         │                    │
       │    │ Fields:                                 │                    │
       │    │ - Full Name (required, pre-filled)     │                    │
       │    │ - Address (required, pre-filled)        │                    │
       │    │ - User Type: Farmer/Retailer (required) │                    │
       │    │                                         │                    │
       │    │ Features:                               │                    │
       │    │ - Auto-save draft (SharedPreferences)  │                    │
       │    │ - Recover draft on app restart         │                    │
       │    │ - Back button DISABLED                 │                    │
       │    │                                         │                    │
       │    │ Action: Click "Save"                    │                    │
       │    └─────────────┬───────────────────────────┘                    │
       │                  │                                                 │
       │                  ▼                                                 │
       │    ┌─────────────────────────────────────────┐                    │
       │    │ AUTH SERVICE                             │                    │
       │    │ createOrUpdateUserProfile()              │                    │
       │    │                                          │                    │
       │    │ Process:                                 │                    │
       │    │ - Normalize phone                        │                    │
       │    │ - Create/Update Firestore document      │                    │
       │    │   users/{phoneE164}                     │                    │
       │    │ - Set auth state                        │                    │
       │    │ - Clear registration draft              │                    │
       │    └─────────────┬───────────────────────────┘                    │
       │                  │                                                 │
       └──────────────────┴───────────────────────────────────────────────┘
                           │
                           ▼
           ┌───────────────────────────────────────┐
           │  CHECK USER TYPE FROM AUTH SERVICE    │
           └───────────────┬───────────────────────┘
                           │
           ┌───────────────┴───────────────┐
           │                               │
           ▼                               ▼
┌──────────────────────┐      ┌──────────────────────┐
│ USER TYPE: FARMER    │      │ USER TYPE: RETAILER  │
│                      │      │                      │
│ Navigate to:         │      │ Navigate to:         │
│ FarmerHome           │      │ RetailerHome         │
└──────────┬───────────┘      └──────────┬───────────┘
           │                             │
           └─────────────┬───────────────┘
                         │
                         ▼
┌───────────────────────────────────────────────────────────────┐
│                        DASHBOARD (HOME)                        │
│                                                                 │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ AppBar                                                    │  │
│ │ - Title: "Farmer Dashboard" / "Retailer Dashboard"       │  │
│ │ - Notifications Icon (bell) → NotificationsScreen        │  │
│ │ - Overflow Menu (⋮)                                       │  │
│ │   ├─ Profile → RegistrationProfileScreen (edit mode)     │  │
│ │   ├─ Settings → VoiceSettingsScreen                      │  │
│ │   ├─ Help → Voice help / HelpScreen                      │  │
│ │   ├─ Feedback → FeedbackScreen                           │  │
│ │   └─ Sign Out → Confirm Dialog → Logout → NewReturning  │  │
│ └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ Welcome Card                                              │  │
│ │ - Name: "Welcome, [User Name]!"                          │  │
│ │ - Location: "[Address]"                                  │  │
│ └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ Feature Cards Grid (2 columns)                           │  │
│ │                                                           │  │
│ │ ┌───────────────┐  ┌───────────────┐                    │  │
│ │ │ Crop Pred.    │  │ Create Order  │                    │  │
│ │ │ (Farmer)      │  │ (Farmer)      │                    │  │
│ │ └───────────────┘  └───────────────┘                    │  │
│ │                                                           │  │
│ │ ┌───────────────┐  ┌───────────────┐                    │  │
│ │ │ Find Retailers│  │ Market Prices │                    │  │
│ │ │ (Farmer)      │  │ (Both)        │                    │  │
│ │ └───────────────┘  └───────────────┘                    │  │
│ │                                                           │  │
│ │ OR                                                       │  │
│ │                                                           │  │
│ │ ┌───────────────┐  ┌───────────────┐                    │  │
│ │ │ Inventory     │  │ Market Insights│                   │  │
│ │ │ (Retailer)    │  │ (Retailer)     │                    │  │
│ │ └───────────────┘  └───────────────┘                    │  │
│ │                                                           │  │
│ │ ┌───────────────┐  ┌───────────────┐                    │  │
│ │ │ Orders        │  │ Analytics     │                    │  │
│ │ │ (Retailer)    │  │ (Retailer)    │                    │  │
│ │ └───────────────┘  └───────────────┘                    │  │
│ └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ Voice Assistant Widget (bottom)                          │  │
│ │ - Green microphone button                                │  │
│ │ - Listen for voice commands                              │  │
│ │ - Visual feedback (pulse animation)                      │  │
│ │ - Command recognition                                    │  │
│ └──────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════

## DASHBOARD NAVIGATION FLOWS

### FARMER DASHBOARD ACTIONS:

Feature Cards:
├─ Crop Prediction → CropPredictionScreen
├─ Create Order/Sell Crop → CreateOrderScreen
├─ Find Retailers → RetailerSearchScreen
├─ Market Prices → MarketInsightsScreen
└─ Accessibility → AccessibilityDemoScreen

Voice Commands:
├─ "crop prediction" → CropPredictionScreen
├─ "retailer search" → RetailerSearchScreen
├─ "create order" / "sell crop" → CreateOrderScreen
├─ "market insights" → MarketInsightsScreen
└─ "help" → Voice help instructions

Overflow Menu:
├─ Profile → RegistrationProfileScreen (pre-filled, edit mode)
├─ Settings → VoiceSettingsScreen
│   ├─ Voice Features Toggle
│   ├─ Language Switch
│   ├─ Voice Context
│   ├─ Training Mode
│   ├─ Notifications Toggle (placeholder)
│   └─ Clear Offline Cache
├─ Help → Voice help / HelpScreen (role-specific commands)
├─ Feedback → FeedbackScreen → Save to Firestore
└─ Sign Out → Confirm → Clear AuthService → NewReturningScreen

### RETAILER DASHBOARD ACTIONS:

Feature Cards:
├─ Inventory → InventoryManagementScreen
├─ Market Insights → MarketInsightsScreen
├─ Orders → OrdersScreen
└─ Analytics → Placeholder (coming soon message)

Voice Commands:
├─ "inventory" → InventoryManagementScreen
├─ "orders" → OrdersScreen
├─ "market insights" → MarketInsightsScreen
└─ "help" → Voice help instructions

Overflow Menu:
└─ (Same as Farmer)

═══════════════════════════════════════════════════════════════════════

## ERROR SCENARIOS

### Phone Number Entry Errors:
┌─────────────────────────────────────────┐
│ Invalid Phone Number                    │
│ - Less than 10 digits                   │
│ → Show: "Invalid Number" Dialog        │
│ → Options: Try Again / Enter Manually  │
└─────────────────────────────────────────┘

### OTP Sending Errors:
┌─────────────────────────────────────────┐
│ Twilio API Errors                       │
│                                         │
│ 21608: Unverified number (Trial)       │
│ → Show: "Failed to send OTP" Dialog   │
│ → User must verify number in Twilio    │
│                                         │
│ 401: Invalid credentials               │
│ → Show: "Failed to send OTP" Dialog   │
│ → Check Twilio credentials             │
│                                         │
│ Network Error                          │
│ → Show: "Failed to send OTP" Dialog   │
│ → Retry option                         │
└─────────────────────────────────────────┘

### OTP Verification Errors:
┌─────────────────────────────────────────┐
│ Invalid OTP                             │
│ - Wrong digits                          │
│ - Expired OTP (cleared after 5 min)    │
│ - OTP already verified                  │
│                                         │
│ → Show: "Invalid OTP" Dialog           │
│ → Options: Try Again / Resend OTP      │
└─────────────────────────────────────────┘

### Firestore Errors:
┌─────────────────────────────────────────┐
│ Network Error                           │
│ - No internet connection               │
│ → Show: Error message                  │
│ → Use offline data if available        │
│                                         │
│ Permission Error                        │
│ - Firestore rules block access         │
│ → Show: Error message                  │
│ → Check Firestore rules                │
└─────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════

## DATA PERSISTENCE & RECOVERY

### Registration Draft Recovery:
┌─────────────────────────────────────────┐
│ If app closes during registration:      │
│ - Draft saved to SharedPreferences      │
│ - Key: profile_draft_{phoneNumber}      │
│                                         │
│ On return to RegistrationProfileScreen: │
│ - Auto-load draft                      │
│ - Pre-fill all fields                  │
│ - User continues where left off        │
└─────────────────────────────────────────┘

### Language Preference:
┌─────────────────────────────────────────┐
│ Saved to: SharedPreferences            │
│ Key: app_language                      │
│ Values: 'en' or 'te'                   │
│                                         │
│ Persists across app restarts           │
└─────────────────────────────────────────┘

### Voice Settings:
┌─────────────────────────────────────────┐
│ Saved to: SharedPreferences            │
│ Keys:                                  │
│ - voice_enabled                         │
│ - voice_language                        │
│ - confidence_threshold                   │
│ - voice_context                         │
│ - voice_history                         │
└─────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════

## VOICE INTEGRATION FLOW

### Voice Input Flow:
User speaks
  ↓
SpeechToText listens (VoiceService)
  ↓
Convert to text (Telugu/English)
  ↓
Extract numbers (for phone/OTP)
  ↓
Normalize format
  ↓
Match to command (if on dashboard)
  ↓
Execute action OR fill input field

### Voice Output Flow:
App event (success/error/prompt)
  ↓
Get localized text (LanguageService)
  ↓
TextToSpeech speak (VoiceService)
  ↓
Play audio
  ↓
User hears instruction

═══════════════════════════════════════════════════════════════════════

## AUTHENTICATION STATE MACHINE

```
States:
- NOT_AUTHENTICATED
- AUTHENTICATING (during OTP verification)
- AUTHENTICATED (user logged in)
- AUTHENTICATION_FAILED

Transitions:
NOT_AUTHENTICATED
  → (OTP verified + user found) → AUTHENTICATED
  → (OTP verified + user not found) → REGISTRATION → AUTHENTICATED
  → (OTP invalid) → NOT_AUTHENTICATED (retry)
  → (Network error) → AUTHENTICATION_FAILED

AUTHENTICATED
  → (Sign out) → NOT_AUTHENTICATED
  → (Profile update) → AUTHENTICATED (refresh)
```

═══════════════════════════════════════════════════════════════════════

## COMPLETE FLOW SUMMARY

### First-Time User Journey:
1. App Launch → IntroScreen
2. Language Selection → Select EN/TE
3. NewReturningScreen → Select "I am New"
4. Phone Entry → Enter/voice phone number
5. OTP Verification → Enter 6-digit OTP
6. Registration → Fill name, address, user type
7. Dashboard → FarmerHome or RetailerHome

### Returning User Journey:
1. App Launch → IntroScreen
2. Language Selection (skip if already set)
3. NewReturningScreen → Select "I am Returning"
4. Phone Entry → Enter/voice phone number
5. OTP Verification → Enter 6-digit OTP
6. Auto-load profile from Firestore
7. Dashboard → FarmerHome or RetailerHome

### Already Logged In:
1. App Launch → IntroScreen
2. AuthWrapper → Check auth state
3. Dashboard → Direct to FarmerHome/RetailerHome

═══════════════════════════════════════════════════════════════════════

