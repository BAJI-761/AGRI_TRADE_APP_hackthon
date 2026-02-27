# How to Fix Gemini API 404 Errors Permanently

If you see a **404 Error** (AI Model Error), it means one of two things:
1.  **The API Key is invalid** (expired, deleted, or lacks permission).
2.  **The Model Name is incorrect** (e.g., using an old version like `gemini-pro` instead of `gemini-1.5-flash`).

## Step 1: Get a Valid API Key
To ensure you always have a working key:
1.  Go to [Google AI Studio](https://aistudio.google.com/app/apikey).
2.  Click **Create API Key**.
3.  Select your Google Cloud project (or create a new one).
4.  Copy the generated key (it starts with `AIza...`).

## Step 2: Update the App
1.  Open `lib/services/gemini_service.dart`.
2.  Find the `_apiKey` variable at the top of the class.
3.  Replace the value with your new key:
    ```dart
    static const String _apiKey = 'YOUR_NEW_API_KEY_HERE';
    ```

## Step 3: Verify Model Name
Ensure the `_baseUrl` uses a supported model. **Gemini 1.5 Flash** is recommended for speed and stability.

**Correct URL:**
```dart
static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
```

**Deprecated/Old URLs (Do NOT Use):**
- `.../models/gemini-pro:generateContent` (Often causes 404)
- `.../models/gemini-1.0-pro:generateContent` (Older version)

## Troubleshooting
- **If it still fails:** Check if "Generative Language API" is enabled in your Google Cloud Console for the project associated with the API key.
- **Quota Limits:** If you make too many requests, you might get a 429 error. Wait a few minutes and try again.
