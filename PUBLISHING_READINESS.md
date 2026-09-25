# EventEase - Publishing & Release Readiness Audit

This document details the checklist of **technical** and **product** requirements that must be resolved prior to compiling and releasing EventEase to the Google Play Store, Apple App Store, and the Web.

---

## 🛠️ Section 1: Technical Readiness Audit

### 🔑 1. Secrets, Environment Variables & Credential Scrubbing
During code inspection, several production secrets and sandbox keys were found hardcoded in codebase configuration files. These must be migrated to a dynamic environment or remote secrets vault.

- **[XenditConfig API Key](file:///c:/Users/Faiz/Downloads/eventease_new/lib/core/config/xendit_config.dart#L3)**:
  - **Issue**: Sandbox key `xnd_development_YOUR_SANDBOX_SECRET_KEY` is hardcoded.
  - **Remediation**: Create production API credentials. Retrieve the key at runtime using dynamic env variables (e.g., via `flutter_dotenv`) or utilize Supabase Edge secrets using `Deno.env.get()` if routing solely through edge functions.
- **[Billplz Configuration](file:///c:/Users/Faiz/Downloads/eventease_new/lib/core/config/billplz_config.dart)**:
  - **Issue**: Sandbox mode is hardcoded (`isSandbox = true`) and placeholder apiKeys are used.
  - **Remediation**: Switch `isSandbox` to `false` in production. Ensure API keys are loaded securely.
- **Supabase Edge Environment Secrets**:
  - **Issue**: Webhooks and edge functions (e.g. `push-notifications`, `xendit-webhook`) rely on environment keys.
  - **Remediation**: Run `supabase secrets set` command to set secrets in the Supabase Cloud console:
    ```bash
    supabase secrets set XENDIT_CALLBACK_TOKEN="your_callback_token"
    supabase secrets set FIREBASE_SERVICE_ACCOUNT_KEY="your_service_account_json"
    ```
- **CORS Proxies on Web Platform**:
  - **Issue**: `PaymentService.getXenditInvoice` uses a public fallback proxy: `https://corsproxy.io/?...`.
  - **Remediation**: Do not rely on free public CORS proxies in production. Route web payment queries exclusively through Supabase Edge Functions which act as a secure, CORS-compliant backend-to-backend middleware.

---

### 📱 2. Android Build Configuration & Firebase Linkage
The Android build configuration still contains boilerplate values that will cause build rejection by the Google Play console.

- **[Namespace & Application ID](file:///c:/Users/Faiz/Downloads/eventease_new/android/app/build.gradle.kts#L12)**:
  - **Issue**: Currently set to standard boilerplate `com.example.eventease_new`.
  - **Remediation**: Change both `namespace` and `applicationId` to a unique organizational domain (e.g. `com.eventease.app`). Perform a global refactor of directories under `android/app/src/main/kotlin/`.
- **[Firebase config package mismatch](file:///c:/Users/Faiz/Downloads/eventease_new/android/app/google-services.json#L12)**:
  - **Issue**: Changing the applicationId to `com.eventease.app` will mismatch with the current `google-services.json` package name `com.example.eventease_new`, breaking compiling or push notifications.
  - **Remediation**: Obtain a matching production `google-services.json` from the Firebase console under the new package name and swap it prior to release compiling.
- **[Signing Configuration](file:///c:/Users/Faiz/Downloads/eventease_new/android/app/build.gradle.kts#L41)**:
  - **Issue**: Release builds are currently configured to sign with debug keys.
  - **Remediation**: Create a secure release Keystore:
    ```bash
    keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    ```
    Create an `android/key.properties` file (add to `.gitignore`) containing keystore passwords, and update `build.gradle.kts` to dynamically read this properties file for the `release` signing config.
- **Android Manifest App Permissions**:
  - **Issue**: Location and camera permissions.
  - **Remediation**: Check `android/app/src/main/AndroidManifest.xml` and make sure it has `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />` and `<uses-permission android:name="android.permission.CAMERA" />` mapped with appropriate prompt descriptors.

---

### 🍎 3. iOS Build Configuration & Permission Blocker
The iOS plist configurations lack crucial native key descriptions, which will cause immediate crashes when accessing hardware features.

- **[Xcode Bundle Identifier](file:///c:/Users/Faiz/Downloads/eventease_new/ios/Runner/Info.plist)**:
  - **Issue**: Placeholder app identifier.
  - **Remediation**: Change Bundle Identifier to match the unique application ID (e.g. `com.eventease.app`) in Xcode Runner settings. Set up Apple Developer Team IDs and generate production Provisioning Profiles.
- **[Missing Info.plist Hardware Description Keys](file:///c:/Users/Faiz/Downloads/eventease_new/ios/Runner/Info.plist)**:
  - **Issue**: The app accesses Location, Camera (QR scanning), and Photo Gallery (file picking), but `Info.plist` only includes `NSContactsUsageDescription`. Trying to initialize the camera or location services on iOS devices will trigger an immediate app crash.
  - **Remediation**: Append these descriptions into the `Info.plist` dictionary:
    ```xml
    <key>NSCameraUsageDescription</key>
    <string>EventEase requires access to your camera to scan ticket QR codes at event entrances.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>EventEase uses your location to show venues and vendors close to you.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>EventEase requires access to your photo library to let you upload event banner artwork.</string>
    ```

---

### 🏛️ 4. Codebase Architecture Integrity (Dead Code Overhead)
- **Unused sqflite Local Cache System**:
  - **Issue**: Local database SQLite helper ([DatabaseHelper](file:///c:/Users/Faiz/Downloads/eventease_new/lib/core/database/database_helper.dart)) is initialized on boot, and repositories interface ([DatabaseService](file:///c:/Users/Faiz/Downloads/eventease_new/lib/core/database/database_service.dart)) is configured, but they are **never** integrated inside any of the live marketplace feature providers (like `VendorProvider`, `CustomerProvider`, or `OrderProvider`). These providers bypass SQLite and query Supabase directly.
  - **Remediation**: Remove SQLite initialization and associated dead code scripts to streamline compilations and reduce storage load, OR map repository fallbacks inside providers to enable actual offline search/caching capabilities.

---

### 🌐 5. Web Build Configuration & SEO
- **Root Index Titles & Metatags**:
  - **Issue**: Standard titles and default metadata in `web/index.html`.
  - **Remediation**: Add search-engine crawler descriptors:
    - `<title>EventEase - Streamlined Event Planning & Marketplace</title>`
    - Meta description tags summarizing features for Event Hosts, Vendors, and Organizers.
    - Set up server routing in Vercel/Netlify config files (`vercel.json`, `netlify.toml`) to handle Flutter single-page app (SPA) fallback routing to `index.html`.

---

### ⚙️ 6. Build Hardening & Development Flags
- **Global Error Interceptors & Overflow Snackbars**:
  - **Issue**: [main.dart](file:///c:/Users/Faiz/Downloads/eventease_new/lib/main.dart#L150) overrides `FlutterError.onError` to show dialogs and snackbars on screen overflows.
  - **Remediation**: Ensure this block is strictly enclosed in `if (kDebugMode)` checks (as it currently is) so users never see developer error logs, overflow messages, or technical dialogs in production builds.
- **[Flutter Skill Binding](file:///c:/Users/Faiz/Downloads/eventease_new/lib/main.dart#L92)**:
  - **Issue**: Binds local accessibility controller in debug mode.
  - **Remediation**: Ensure it remains disabled during production builds (`kDebugMode` condition) to block automated interface tampering on live builds.

---

## 🤵 Section 2: Product & Compliance Readiness Audit

### 🛡️ 1. User Generated Content (UGC) Policy Compliance
Apple App Store Review Guidelines (Section 1.2) and Google Play Policy require apps hosting UGC (like user posts, event descriptions, group chats, images) to implement content moderation tools.

- **Content Moderation Database Tables**:
  - **Status**: Database support is ready (we have RLS policies and admin activities schema).
  - **Requirement**: Build a user-facing **Report Button** on profiles, event details, and reviews. Reported accounts/events must automatically flag records in Supabase (updating a `banned_status` or triggering a support ticket) for admin review.
- **Account Deletion Flow**:
  - **Status**: [SecurityService.softDeleteAccount()](file:///c:/Users/Faiz/Downloads/eventease_new/lib/core/services/security_service.dart#L30) is implemented.
  - **Requirement**: Apple requires a simple way for users to delete their account in the app. Place a prominent "Delete Account" button in the Customer Profile and Vendor Settings views. Ensure it invokes the soft-delete sequence and triggers `SupabaseClient.auth.signOut(scope: SignOutScope.global)`.

---

### 👥 2. Onboarding & Hardcoded Development Mock IDs
- **[Mock customer1 Identifiers](file:///c:/Users/Faiz/Downloads/eventease_new/lib/features/customer/presentation/views/customer/search_screen.dart#L3259)**:
  - **Issue**: Multiple features (like Calendar, Appointments, Search, and Account Screens) hardcode customer ID queries to `'customer1'` when performing actions, instead of dynamically accessing the active session.
  - **Remediation**: Map all customer inputs to fetch `Provider.of<AuthProvider>(context).userId` securely.
- **[Mock Guest Chat Senders](file:///c:/Users/Faiz/Downloads/eventease_new/lib/features/guest/presentation/views/guest/guest_chat_screen_fixed.dart#L36)**:
  - **Issue**: Guest chat uses hardcoded `senderId: 'current_user_id'` and stores messages only in memory list state.
  - **Remediation**: Integrate guest chat with database storage and fetch active user credentials.
- **Disable Sample Data Seeders**:
  - **Issue**: The application currently auto-injects mock data on launch if lists are empty:
    - [main.dart](file:///c:/Users/Faiz/Downloads/eventease_new/lib/main.dart#L323): `vendorProvider.loadSampleVendors()`.
    - [main_customer_vendor.dart](file:///c:/Users/Faiz/Downloads/eventease_new/lib/main_customer_vendor.dart#L50): Loads mock networking details.
  - **Remediation**: Create a production build flavor or environment configuration switch (`AppConfig.isProduction`). In production builds, bypass these seeder methods entirely. The app must fetch live listings from Supabase Postgres databases.

---

### 🔔 3. Push Notifications & Real-Time Setup
- **Firebase Messaging credentials**:
  - **Issue**: The current messaging tokens map to development targets.
  - **Remediation**: Generate APNs push certificates (P12 files) or APNs Auth keys via Apple Developer portal. Upload them to Firebase console. Generate production service account credentials for Supabase Edge Functions.

---

### 💰 4. Financial Regulations & Webhooks
- **Production Webhook Endpoints**:
  - **Issue**: Currently sandbox endpoints are used.
  - **Remediation**: Re-configure Xendit and Billplz dashboard webhook settings to point to production Supabase Edge Functions URL:
    `https://<production-project-ref>.supabase.co/functions/v1/xendit-webhook`
  - **Installments Policy**: Verify that global platform commission settings are configured under `commission_payments` table in production PostgreSQL database.
