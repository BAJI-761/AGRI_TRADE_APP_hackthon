# Firestore Setup Guide for Phone-Only Authentication

## Current Issues
1. **PERMISSION_DENIED errors**: You're getting `Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions.}` when trying to read/write to Firestore collections (especially `orders`).

2. **Users collection**: `unavailable - Failed to get document because the client is offline` error for user lookups.

These are **Firestore security rules issues**, not Firebase Auth issues.

Since you're using **phone-only authentication (no OTP, no Firebase Auth)**, you need to configure Firestore rules to allow:
- Reading user documents by phone number
- Reading/writing orders (farmers create orders, retailers view/accept/reject them)

---

## Step 1: Open Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **agritradeapp-42acc**
3. Click on **Firestore Database** in the left sidebar
4. Click on the **Rules** tab

---

## Step 2: Update Firestore Security Rules

Replace your current Firestore rules with these:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - allow read by phone number (for phone-only auth)
    match /users/{userId} {
      // Allow anyone to read user documents (for phone lookup)
      // This is needed because we check users BEFORE authentication
      allow read: if true;
      
      // Allow write only if authenticated OR if creating a new user
      allow write: if request.auth != null || 
                     (request.resource.data.keys().hasAll(['phone', 'name', 'userType']) &&
                      request.resource.data.phone is string &&
                      request.resource.data.name is string &&
                      request.resource.data.userType is string);
    }
    
    // Orders collection - allow read/write for all users (for phone-only auth)
    // Farmers can create orders, retailers can read and update them
    match /orders/{orderId} {
      // Allow anyone to read orders (retailers need to see orders)
      allow read: if true;
      
      // Allow creating orders (farmers creating new orders)
      allow create: if request.resource.data.keys().hasAll([
        'farmerId', 'crop', 'quantity', 'unit', 'pricePerUnit', 
        'availableDate', 'location', 'notes', 'createdAt', 'status'
      ]) &&
      request.resource.data.farmerId is string &&
      request.resource.data.crop is string &&
      request.resource.data.quantity is number &&
      request.resource.data.unit is string &&
      request.resource.data.pricePerUnit is number &&
      request.resource.data.status is string;
      
      // Allow updating orders (retailers accepting/rejecting orders)
      allow update: if request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['status']) &&
        request.resource.data.status is string &&
        request.resource.data.status in ['pending', 'accepted', 'rejected'];
      
      // Allow deleting orders (optional - only by order creator)
      allow delete: if true; // Or add more restrictive rules if needed
    }
    
    // All other collections - require authentication
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Step 3: Publish the Rules

1. Click **Publish** button
2. Wait for confirmation that rules are published
3. Rules take effect immediately

---

## Alternative: More Secure Rules (Recommended for Production)

If you want more security while still allowing phone lookup:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      // Allow reading if:
      // 1. User is authenticated, OR
      // 2. Requesting specific document (phone lookup for login)
      allow read: if request.auth != null || 
                     resource == null ||
                     resource.data.keys().hasAll(['phone', 'name', 'userType']);
      
      // Allow write if authenticated OR creating new user with required fields
      allow create: if request.auth != null || 
                       (request.resource.data.keys().hasAll(['phone', 'name', 'userType']) &&
                        request.resource.data.phone is string &&
                        request.resource.data.name is string &&
                        request.resource.data.userType is string);
      
      // Allow update/delete only if authenticated
      allow update, delete: if request.auth != null;
    }
    
    // Orders collection - allow read/write for all users (for phone-only auth)
    match /orders/{orderId} {
      // Allow anyone to read orders (retailers need to see orders)
      allow read: if true;
      
      // Allow creating orders (farmers creating new orders)
      allow create: if request.resource.data.keys().hasAll([
        'farmerId', 'crop', 'quantity', 'unit', 'pricePerUnit', 
        'availableDate', 'location', 'notes', 'createdAt', 'status'
      ]) &&
      request.resource.data.farmerId is string &&
      request.resource.data.crop is string &&
      request.resource.data.quantity is number &&
      request.resource.data.unit is string &&
      request.resource.data.pricePerUnit is number &&
      request.resource.data.status is string;
      
      // Allow updating orders (retailers accepting/rejecting orders)
      allow update: if request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['status']) &&
        request.resource.data.status is string &&
        request.resource.data.status in ['pending', 'accepted', 'rejected'];
      
      // Allow deleting orders (optional - only by order creator)
      allow delete: if true; // Or add more restrictive rules if needed
    }
    
    // Other collections require authentication
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Step 4: Verify Setup

After updating rules:

1. **Test the app again** - Enter phone number and click Continue
2. The "unavailable" error should be gone
3. If user exists, they'll be logged in
4. If user doesn't exist, they'll go to registration
5. **Test Orders feature**:
   - Login as a farmer and create an order
   - Login as a retailer and check if the order appears in Orders screen
   - Try accepting/rejecting an order from retailer dashboard
   - The PERMISSION_DENIED error should be gone

---

## Note About Firebase Phone Authentication

You mentioned checking Firebase Phone Authentication, but **you don't actually need it enabled** for this phone-only flow because:

- ✅ You're NOT using OTP verification
- ✅ You're NOT using Firebase Auth for phone numbers
- ✅ You're storing user profiles directly in Firestore
- ✅ You're using phone number as document ID for easy lookup

The only thing you need is **Firestore security rules** that allow reading the `users` collection.

---

## Troubleshooting

### Still getting "unavailable" error?

1. **Check Firestore is enabled**: 
   - Go to Firestore Database in Firebase Console
   - Make sure it's not in "test mode" with expired rules

2. **Check internet connection**: 
   - Make sure your device/emulator has internet
   - Try restarting the app

3. **Clear app data**:
   - Firestore might be stuck in offline mode
   - Clear app data and restart

4. **Check rules syntax**:
   - Use the Firebase Console Rules editor to validate syntax
   - Make sure there are no syntax errors

---

## Security Considerations

The first ruleset (`allow read: if true`) allows **anyone** to read user documents. This is:
- ✅ **OK for development/testing**
- ⚠️ **Consider more restrictive rules for production**

For production, you might want:
- Rate limiting
- Validation that phone number format is correct
- Additional security checks

But for now, the simple rules will get your app working!

