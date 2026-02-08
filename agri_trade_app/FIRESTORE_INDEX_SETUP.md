# Firestore Index Setup for Notifications

## Problem
The notifications feature requires a Firestore composite index to query notifications by `userId` and order by `createdAt`.

## Solution Options

### Option 1: Create Index via Firebase Console (Recommended - Fastest)

1. Click this link (from the error message):
   ```
   https://console.firebase.google.com/v1/r/project/agritradeapp-42acc/firestore/indexes?create_composite=Clhwcm9qZWN0cy9hZ3JpdHJhZGVhcHAtNDJhY2MvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL25vdGlmaWNhdGlvbnMvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg
   ```

2. Or manually:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project: **agritradeapp-42acc**
   - Go to **Firestore Database** → **Indexes** tab
   - Click **Create Index**
   - Set:
     - Collection ID: `notifications`
     - Fields to index:
       - `userId` (Ascending)
       - `createdAt` (Descending)
   - Click **Create**

3. Wait for the index to build (usually 1-5 minutes)
4. The app will automatically use the index once it's ready

### Option 2: Deploy Index via Firebase CLI

If you have Firebase CLI installed:

```bash
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not already done)
firebase init firestore

# Deploy the index
firebase deploy --only firestore:indexes
```

The `firestore.indexes.json` file is already created in the project root with the correct index definition.

## Verify Index is Created

1. Go to Firebase Console → Firestore Database → Indexes
2. You should see an index for `notifications` collection with:
   - `userId` (Ascending)
   - `createdAt` (Descending)
3. Status should be "Enabled" (green checkmark)

## Notes

- The index creation usually takes 1-5 minutes
- The app will work once the index is created
- You only need to create this index once
- The index is required for the notifications query to work efficiently

