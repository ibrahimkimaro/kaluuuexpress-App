# Firebase Configuration Guide for Kaluu/Bozen Cargo

## Overview
This guide explains how to set up Firebase Cloud Messaging (FCM) for push notifications in your Kaluu/Bozen Cargo app.

## Prerequisites
1. A Google account
2. Your app's package name: `com.example.shippng_management_app` (or your actual package name)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name it "Kaluu/Bozen Cargo" or similar
4. Follow the setup wizard

## Step 2: Add Android App to Firebase

1. In Firebase Console, click "Add app" → Select Android
2. Enter your Android package name (found in `android/app/build.gradle`)
3. Download `google-services.json`
4. Place it in `android/app/` directory

## Step 3: Configure Android

### Update `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### Update `android/app/build.gradle`:
```gradle
// At the top, after other plugins
apply plugin: 'com.google.android.gms.google-services'

dependencies {
    // Add these if not present
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

### Update `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest ...>
    <application ...>
        <!-- Add these inside <application> tag -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="kaluu_shipping_updates" />
        
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
    </application>
</manifest>
```

## Step 4: Test Notifications

### From Firebase Console:
1. Go to Cloud Messaging
2. Click "Send your first message"
3. Enter title and text
4. Click "Send test message"
5. Enter your FCM token (printed in console when app runs)

## Step 5: Backend Integration

Your Django backend should send notifications when route_progress changes. Here's a Python example:

```python
import firebase_admin
from firebase_admin import credentials, messaging

# Initialize Firebase Admin SDK (do this once)
cred = credentials.Certificate('path/to/serviceAccountKey.json')
firebase_admin.initialize_app(cred)

def send_shipment_update_notification(fcm_token, tracking_code, route_stage):
    message = messaging.Message(
        notification=messaging.Notification(
            title='📦 Shipment Update',
            body=f'Your shipment {tracking_code} has reached {route_stage}',
        ),
        data={
            'tracking_code': tracking_code,
            'route_stage': route_stage,
            'type': 'shipment_update',
        },
        token=fcm_token,
    )
    
    response = messaging.send(message)
    return response
```

## Step 6: Store FCM Tokens

In your Flutter app, save the FCM token to the backend when user logs in:

```dart
// After login success
final token = await NotificationService().getToken();
if (token != null) {
    // Send token to your Django backend
    await apiService.updateFCMToken(token);
}
```

## Notification Icon

To use the Kaluu logo as the notification icon:
1. Place logo in `android/app/src/main/res/mipmap-*/`
2. Update AndroidManifest.xml to reference it:
   ```xml
   android:resource="@mipmap/logo"
   ```

## Testing Checklist

- [ ] Firebase project created
- [ ] google-services.json added to android/app/
- [ ] Android configuration updated
- [ ] App builds successfully
- [ ] FCM token printed in console
- [ ] Test notification sent from Firebase Console
- [ ] Notification received on device
- [ ] Backend configured to send notifications

## Important Notes

- **Debug vs Release**: google-services.json contains configuration for both
- **Token Refresh**: FCM tokens can change, implement token refresh logic
- **Permissions**: Android 13+ requires runtime permission for notifications
- **Background**: Notifications work even when app is closed

## Troubleshooting

**App doesn't receive notifications:**
- Check google-services.json is in correct location
- Verify package name matches
- Check Android version and permissions
- Look for errors in Android Studio logcat

**Notification doesn't show:**
- Check notification channel is created
- Verify notification icon exists
- Check Android notification settings

For more help, see [Firebase Documentation](https://firebase.google.com/docs/cloud-messaging)
