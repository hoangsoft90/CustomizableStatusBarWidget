# Android Manifest & Permissions

## Purpose

Declares all required Android permissions, components (activities, receivers, services), metadata (AdMob app ID, network security config), and queries for text processing.

## Requirements

### R1: Permissions declared

6 permissions:

| Permission | Purpose |
|-----------|---------|
| `INTERNET` | AdMob, IAP network calls |
| `RECEIVE_BOOT_COMPLETED` | BootReceiver restart services |
| `POST_NOTIFICATIONS` | Android 13+ notification permission |
| `FOREGROUND_SERVICE` | FloatingBar + TimeTick services |
| `FOREGROUND_SERVICE_SPECIAL_USE` | Android 14+ foreground service type |
| `SYSTEM_ALERT_WINDOW` | Floating bar overlay permission |

**Scenario: All permissions present**
- Given `AndroidManifest.xml`
- When parsed
- Then all 6 `<uses-permission>` entries are present
- Reference: `AndroidManifest.xml:3-10`

### R2: MainActivity configuration

- `exported="true"` with MAIN/LAUNCHER intent filter
- `launchMode="singleTop"` (for deep link handling)
- `hardwareAccelerated="true"`
- NormalTheme meta-data for Flutter splash
- Standard configChanges for orientation/keyboard/etc.

**Scenario: Launch config**
- Given the app is installed
- When launcher icon is tapped
- Then `MainActivity` is launched with `singleTop` mode
- Reference: `AndroidManifest.xml:13-29`

### R3: DateTimeWidgetProvider receiver

- `exported="true"` with `APPWIDGET_UPDATE` intent filter
- `meta-data` pointing to `@xml/widget_info` (widget sizing metadata)
- Label: "Date & Time Widget" (with `&amp;` XML encoding)

**Scenario: Widget provider registered**
- Given the app is installed
- When Android widget picker lists available widgets
- Then "Date & Time Widget" is shown
- Reference: `AndroidManifest.xml:32-41`

### R4: Services declared

| Service | foregroundServiceType | exported |
|---------|----------------------|----------|
| `FloatingBarService` | `specialUse` | false |
| `TimeTickService` | `specialUse` | false |

**Scenario: FloatingBarService**
- When the service is started
- Then it runs as a foreground service with `specialUse` type
- Reference: `AndroidManifest.xml:44-46`

### R5: BootReceiver registered

`BootReceiver` with `exported="true"` and `BOOT_COMPLETED` intent filter.

**Scenario: Boot receiver active**
- Given the app is installed
- When device boots
- Then `BootReceiver.onReceive` is triggered
- Reference: `AndroidManifest.xml:52-56`

### R6: AdMob Application ID

`<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID">` with test value `ca-app-pub-3940256099942544~3347511713`.

**Scenario: AdMob ID present**
- Given the app starts
- When MobileAds initializes
- Then the Application ID is found in manifest metadata
- Reference: `AndroidManifest.xml:59-61`

### R7: Network security config

`android:networkSecurityConfig="@xml/network_security_config"` on the `<application>` tag. The XML allows cleartext HTTP traffic.

**Scenario: HTTP allowed**
- Given the network_security_config allows cleartext
- When the app makes an HTTP request
- Then it is not blocked by network security
- Reference: `AndroidManifest.xml:14`

### R8: Flutter embedding v2

`<meta-data android:name="flutterEmbedding" android:value="2" />`

**Scenario: Embedding version**
- When the app starts
- Then Flutter uses embedding v2
- Reference: `AndroidManifest.xml:67-69`

### R9: Text processing queries

`<queries>` block declares `ACTION_PROCESS_TEXT` with `text/plain` MIME type for Flutter's ProcessTextPlugin.

**Scenario: Text processing**
- Given the app needs to query text processing activities
- When the queries block is present
- Then the system allows visibility of text processing intent handlers
- Reference: `AndroidManifest.xml:72-77`

## Need to clear

1. **`usesCleartextTraffic` was removed from `<application>` tag** — previously present but removed during a build fix. HTTP access is handled solely via `network_security_config.xml`. If the XML is ever removed, HTTP will silently break in release builds.
