# App Store Submission — The Void

**App:** The Void
**Package (Android):** `com.thevoid.the_void_app`
**Bundle ID (iOS):** `com.thevoid.app` ← set this in Xcode (see iOS section)
**Version:** 1.0.0 (build 1)
**Flutter:** 3.38.6

---

## Part 1 — Google Play Store

---

### Phase 1 — Generate upload keystore (one-time, do this once, never again)

> The keystore is your permanent identity on the Play Store. Losing it means you cannot update the app under the same listing. Back it up to somewhere safe (iCloud, password manager, external drive).

**Step 1.1 — Generate the keystore**

Run from the project root:

```bash
keytool -genkey -v \
  -keystore android/upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

You'll be prompted for:
- Keystore password (make it strong, save it)
- Key password (can be same as keystore password)
- Your name, org, city, country (this goes into the cert — use real info)

✓ **Verify:** `android/upload-keystore.jks` exists and is > 2 KB.

---

**Step 1.2 — Create key.properties**

Create `android/key.properties` (already gitignored):

```
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

✓ **Verify:** Run `cat android/key.properties` and confirm the four fields are filled in with no placeholder text.

---

**Step 1.3 — Confirm signing is wired up**

`android/app/build.gradle.kts` already reads `key.properties` and uses it for release builds (done in this session). No edits needed.

✓ **Verify:** Run:
```bash
flutter build appbundle --dart-define-from-file=.env.json
```
Build should complete without "TODO: Add signing config" warnings. If you see a signing error, re-check the paths in `key.properties`.

---

### Phase 2 — Google OAuth for Android (get SHA-1 fingerprint registered)

Google Sign-In on Android requires your app's signing fingerprint registered in Google Cloud Console, otherwise OAuth will fail silently on device.

**Step 2.1 — Get your SHA-1 fingerprint**

```bash
keytool -list -v \
  -keystore android/upload-keystore.jks \
  -alias upload
```

Copy the `SHA1:` line. Looks like: `AB:CD:EF:...`

✓ **Verify:** You have a 20-byte colon-separated hex string.

---

**Step 2.2 — Register in Google Cloud Console**

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Select the project that has your OAuth credentials (the one connected to Supabase)
3. APIs & Services → Credentials → your OAuth 2.0 Client ID (Android) → Edit
4. If no Android client exists: + Create Credentials → OAuth client ID → Android
   - Package name: `com.thevoid.the_void_app`
   - SHA-1: paste from Step 2.1
5. Save

✓ **Verify:** The Android OAuth client shows your package name and SHA-1 fingerprint.

---

**Step 2.3 — Add redirect URL in Supabase**

1. Supabase Dashboard → your project → Authentication → URL Configuration
2. Under **Redirect URLs**, add: `com.thevoidapp://login-callback`
3. Save

✓ **Verify:** `com.thevoidapp://login-callback` appears in the redirect URLs list.

---

### Phase 3 — App icon

The default Flutter blue icon will get your app rejected for looking unfinished.

**Step 3.1 — Prepare a 1024×1024 PNG**

Create or export your icon as a square PNG, 1024×1024, no transparency (Play Store doesn't allow alpha on the main icon layer — use a solid background).

**Step 3.2 — Generate all densities**

Add to `pubspec.yaml` under `dev_dependencies`:
```yaml
flutter_launcher_icons: ^0.14.0
```

Add to the bottom of `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: false          # handle iOS separately
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 23
  adaptive_icon_background: "#0D0B14"   # The Void background colour
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

Place your icon at `assets/icon/app_icon.png`, then run:
```bash
flutter pub get
dart run flutter_launcher_icons
```

✓ **Verify:** Open `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` — it should show your icon, not the blue Flutter logo.

---

### Phase 4 — Build the release App Bundle

```bash
flutter build appbundle \
  --dart-define-from-file=.env.json \
  --build-name=1.0.0 \
  --build-number=1
```

Output: `build/app/outputs/bundle/release/app-release.aab`

✓ **Verify:**
- File exists and is > 10 MB (anything smaller means assets didn't bundle)
- Run `flutter build appbundle --analyze-size` to check nothing unexpected is bloated

---

### Phase 5 — Play Console submission

**Step 5.1 — Create Play Console account**

1. Go to [play.google.com/console](https://play.google.com/console)
2. Pay the one-time $25 registration fee
3. Complete identity verification (takes up to 48 hours for new accounts)

✓ **Verify:** You can access the Play Console dashboard and see "Create app".

---

**Step 5.2 — Create the app**

1. Play Console → Create app
   - App name: `The Void`
   - Default language: English (United States)
   - App or game: App
   - Free or paid: Free
2. Agree to declarations → Create app

✓ **Verify:** App dashboard is visible with setup checklist.

---

**Step 5.3 — Upload to Internal Testing first**

Do not go straight to Production. Internal Testing lets you install it on your own device with no review.

1. Release → Testing → Internal testing → Create new release
2. Upload `app-release.aab`
3. Add release notes: "Initial internal test"
4. Save and publish

✓ **Verify:** Release status shows "Available to internal testers". Install it on your Android device via the opt-in link. Test: record voice, rescue gem, sign in with Google, confirm gem appears.

---

**Step 5.4 — Complete store listing (required before Production)**

Play Console → Store presence → Main store listing:

| Field | What to fill in |
|---|---|
| App name | The Void |
| Short description | Speak. Rescue what matters. Let the rest go. |
| Full description | Write 3–5 paragraphs about what the app does |
| App icon | Upload 512×512 PNG |
| Feature graphic | 1024×500 PNG (required) |
| Screenshots | At least 2 phone screenshots (record from internal test) |

✓ **Verify:** No red "Required" banners remain in Main store listing.

---

**Step 5.5 — Content rating questionnaire**

Play Console → Policy → App content → Content rating → Start questionnaire
Category: Productivity. Answer the questions (no violence, no user-generated content that others can see, etc.)

✓ **Verify:** Rating shows as "Everyone" or similar — no adult content flags.

---

**Step 5.6 — Privacy policy**

The full policy text is in Part 4 of this doc. Publish it as a public web page (a simple site, GitHub Gist, or Notion page all work), then:

1. Replace `[YOUR EMAIL]` and `[EFFECTIVE DATE]` in the policy text
2. Publish at a stable public URL
3. Play Console → Policy → App content → Privacy policy → enter the URL

✓ **Verify:** URL is publicly accessible, loads without login, and contains your email address and an effective date.

---

**Step 5.7 — Promote to Production**

Once internal testing passes on your device:

1. Release → Production → Create new release
2. Select the same AAB (or re-upload)
3. Rollout percentage: start at 20% (lets you catch crashes before full rollout)
4. Submit for review

✓ **Verify:** Status changes to "Under review". First-time reviews typically take 3–7 days. You'll get an email when it's approved or if changes are required.

---

## Part 2 — Apple App Store

---

### Phase 1 — Apple Developer account + Xcode setup

**Step 1.1 — Enrol in Apple Developer Program**

1. Go to [developer.apple.com/enroll](https://developer.apple.com/enroll)
2. Sign in with your Apple ID
3. Enrol as Individual ($99/year)
4. Complete identity verification (usually instant with credit card, up to 48 hours otherwise)

✓ **Verify:** [developer.apple.com/account](https://developer.apple.com/account) shows your membership as Active.

---

**Step 1.2 — Set bundle identifier in Xcode**

```bash
open ios/Runner.xcworkspace
```

1. Click **Runner** (top of file tree) → Runner target → **General** tab
2. Bundle Identifier: change from the default to `com.thevoid.app`
3. Display Name: `The Void` (verify it shows correctly, not `the_void_app`)
4. Version: `1.0.0`, Build: `1`

✓ **Verify:** Bundle Identifier field shows `com.thevoid.app` with no red error.

---

**Step 1.3 — Set deployment target**

In Xcode → Runner target → General → Minimum Deployments: set to **iOS 16.0**
(speech_to_text and supabase_flutter both require iOS 13+; 16 is a safe modern minimum)

✓ **Verify:** No "minimum deployment target" warnings in the build log.

---

**Step 1.4 — Set up signing in Xcode**

1. Xcode → Runner target → **Signing & Capabilities**
2. Team: select your Apple Developer account
3. Check **Automatically manage signing**

Xcode will create a provisioning profile automatically.

✓ **Verify:** No red signing errors. A provisioning profile appears under your team.

---

### Phase 2 — Apple Sign-In + Supabase OAuth for iOS

**Step 2.1 — Enable Sign in with Apple capability**

1. Xcode → Runner target → Signing & Capabilities → + Capability
2. Add **Sign in with Apple**

✓ **Verify:** "Sign in with Apple" appears as an entitlement in the Signing & Capabilities tab.

---

**Step 2.2 — Register redirect URL in Supabase**

`com.thevoidapp://login-callback` is already in Supabase from the Android step. No additional URL needed — iOS uses the same custom scheme.

✓ **Verify:** Confirm `com.thevoidapp://login-callback` is still in Supabase → Auth → URL Configuration → Redirect URLs.

---

**Step 2.3 — Configure Apple OAuth in Supabase**

1. Supabase Dashboard → Authentication → Providers → Apple → Enable
2. You'll need a **Services ID**, **Team ID**, **Key ID**, and a **private key** from Apple Developer
3. In Apple Developer → Certificates, Identifiers & Profiles:
   - Register a Services ID: `com.thevoid.app.signin`
   - Enable Sign in with Apple, configure with your domain and `https://YOUR_SUPABASE_PROJECT.supabase.co/auth/v1/callback` as the return URL
   - Create a Sign in with Apple key → download the `.p8` file
4. Paste credentials into Supabase Apple provider settings

✓ **Verify:** Supabase shows Apple provider as "Enabled" with no missing field warnings.

---

### Phase 3 — App icon for iOS

**Step 3.1 — Generate iOS icons**

Update `pubspec.yaml` flutter_launcher_icons config to include iOS:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  ...
```

Then run:
```bash
dart run flutter_launcher_icons
```

✓ **Verify:** In Xcode → Runner → Assets.xcassets → AppIcon — all slots should be filled with your icon (no empty grey boxes).

---

### Phase 4 — Build the IPA

**Step 4.1 — Build**

```bash
flutter build ipa \
  --dart-define-from-file=.env.json \
  --build-name=1.0.0 \
  --build-number=1
```

Output: `build/ios/ipa/the_void_app.ipa`

✓ **Verify:**
- Build completes with no errors (warnings are OK)
- `.ipa` file exists and is > 5 MB

---

**Step 4.2 — Upload to App Store Connect via Xcode**

1. Open Xcode → Product → Archive
   (this re-builds and creates an Archive — don't skip this, the `flutter build ipa` output is for direct upload only)
2. Organizer window opens → Distribute App → App Store Connect → Upload
3. Follow prompts, keep defaults

Or via command line:
```bash
xcrun altool --upload-app \
  -f build/ios/ipa/the_void_app.ipa \
  -t ios \
  -u YOUR_APPLE_ID_EMAIL \
  -p YOUR_APP_SPECIFIC_PASSWORD
```

(App-specific password: appleid.apple.com → Security → App-Specific Passwords)

✓ **Verify:** App Store Connect → your app → TestFlight → build appears (takes ~5 minutes to process after upload).

---

### Phase 5 — App Store Connect submission

**Step 5.1 — Create app record**

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. My Apps → + → New App
   - Platform: iOS
   - Name: The Void
   - Primary language: English (U.S.)
   - Bundle ID: `com.thevoid.app` (select from dropdown — appears after Xcode registers it)
   - SKU: `thevoid-ios-1` (internal only, anything unique)

✓ **Verify:** App record is created and visible in My Apps.

---

**Step 5.2 — TestFlight internal test**

1. App Store Connect → your app → TestFlight → your build → enable for internal testing
2. Add yourself as internal tester
3. Install via TestFlight app on your iPhone

✓ **Verify:** App launches, mic permission prompt appears, voice recording works, Google/Apple sign-in works, gem saves and appears after re-launch.

---

**Step 5.3 — Complete App Store listing**

App Store Connect → your app → App Store → iOS App → 1.0 Prepare for Submission:

| Field | What to fill in |
|---|---|
| Screenshots | At least 1 for 6.5" (iPhone 14 Pro Max) and 5.5" (iPhone 8 Plus) — take from TestFlight |
| Promotional text | Optional, appears above description |
| Description | What the app does, why it's different |
| Keywords | voice notes, ephemeral, transcription, thought capture (100 char limit) |
| Support URL | Your website or GitHub repo |
| Privacy Policy URL | Same one from Play Store |
| Version | 1.0.0 |
| Copyright | © 2026 [Your Name] |

✓ **Verify:** No orange "Missing" badges remain in the submission form.

---

**Step 5.4 — Answer export compliance**

When submitting: uses encryption? → **Yes** (HTTPS/TLS counts)
Exempt from EAR? → **Yes** (standard HTTPS, not custom crypto)

✓ **Verify:** Encryption compliance section shows no warnings.

---

**Step 5.5 — Submit for review**

1. Select your uploaded build in the submission form
2. Submit for Review

✓ **Verify:** Status changes to "Waiting for Review". First review typically takes 24–48 hours. Apple emails when approved or if they have questions (check the Resolution Center in App Store Connect).

---

---

## Part 3 — In-app requirements (both stores)

---

### Privacy policy in-app

Both stores accept a URL for the listing, but Apple **rejects apps with account creation that don't surface the privacy policy from within the app**. Add a tappable link in the app's settings or auth screen.

**What to build:** A "Privacy Policy" `TextButton` somewhere accessible without being logged in (the auth sheet is a good place — add it below the "Not now" button). It opens the URL in the system browser via `url_launcher`.

Add dependency:
```yaml
# pubspec.yaml
url_launcher: ^6.3.0
```

Minimum implementation in `auth_screen.dart`, below the "Not now" button:
```dart
TextButton(
  onPressed: () => launchUrl(Uri.parse('https://YOUR_PRIVACY_POLICY_URL')),
  child: Text(
    'Privacy Policy',
    style: TextStyle(
      color: VoidColors.textFaded,
      fontSize: 12,
      fontFamily: 'serif',
    ),
  ),
),
```

✓ **Verify:** Tapping "Privacy Policy" in the auth sheet opens your policy page in the browser. Works without being signed in.

---

### Delete account (Apple hard requirement)

Apple rejects any app that offers account creation but doesn't provide a way to delete the account from within the app. This is enforced at review — there is no workaround.

**What to build:** A "Delete account" option in a Settings or Profile screen. When tapped:
1. Confirm with an alert ("This will permanently delete your account and all saved gems.")
2. Delete all gems from Supabase + audio from Storage
3. Call `supabase.auth.admin.deleteUser()` — or preferably a Supabase Edge Function so the service role key stays server-side
4. Sign out and return to the main screen

> **Note:** `supabase.auth.admin.deleteUser()` requires the service role key, which must never be in the client app. The correct approach is a Supabase Edge Function (one-liner) that deletes the calling user's own account using `auth.uid()`. This is a separate build task before iOS submission.

✓ **Verify:** After tapping "Delete account" and confirming, the user is signed out, their row is gone from the `gems` table, and re-opening the app shows no saved gems and no authenticated session.

---

### Google Play — Data Safety section

Play Console → Policy → App content → Data Safety. Fill in accurately:

| Question | Answer for The Void |
|---|---|
| Does your app collect or share any of the required user data types? | Yes |
| Is all of the user data collected by your app encrypted in transit? | Yes |
| Do you provide a way for users to request that their data is deleted? | Yes |
| **Audio files** | Collected · Stored · Not shared · User can delete |
| **Personal identifiers** (email from OAuth) | Collected · Account management · Not shared |
| **App activity** (transcripts) | Collected · App functionality · Not shared |

✓ **Verify:** Data Safety section shows no incomplete fields and the summary matches what the app actually does.

---

## Quick reference — rebuild & resubmit for future updates

Every time you ship an update:

1. Bump version in `pubspec.yaml` (e.g. `1.0.1+2`)
2. Android: `flutter build appbundle --dart-define-from-file=.env.json`  → upload new AAB to Play Console → new release
3. iOS: Product → Archive in Xcode → Distribute → upload to App Store Connect → new TestFlight build → submit

---

## Checklist summary

### Both stores (do these first)
- [ ] Privacy policy page published at a public URL
- [ ] Privacy policy link accessible in-app without being signed in (`url_launcher`)
- [ ] "Delete account" flow built and tested (required by Apple; good practice for Play too)

### Play Store
- [ ] Keystore generated + backed up
- [ ] `key.properties` filled in
- [ ] SHA-1 registered in Google Cloud Console
- [ ] `com.thevoidapp://login-callback` in Supabase redirect URLs
- [ ] App icon replaced (not the Flutter blue logo)
- [ ] AAB builds clean
- [ ] Internal test passes on real Android device
- [ ] Store listing complete (icon, screenshots, description, privacy policy URL)
- [ ] Content rating complete
- [ ] Data Safety section filled in accurately
- [ ] Submitted for Production review

### App Store
- [ ] Apple Developer account active ($99/yr paid)
- [ ] Bundle ID set to `com.thevoid.app` in Xcode
- [ ] Sign in with Apple capability added
- [ ] Apple OAuth + Services ID configured in Supabase
- [ ] Supabase Edge Function for account deletion deployed (keeps service role key off client)
- [ ] App icon fills all Xcode slots (no grey boxes)
- [ ] IPA / Archive builds clean
- [ ] TestFlight internal test passes on real iPhone
- [ ] Store listing complete (screenshots for 6.5" + 5.5", description, privacy policy URL)
- [ ] Export compliance answered
- [ ] Submitted for review

---

## Part 4 — Privacy Policy

> Copy this text to your privacy policy page. Replace `[YOUR EMAIL]` and `[EFFECTIVE DATE]` before publishing. The URL to that page is what you paste into both store listings and link to from within the app.

---

### Privacy Policy — The Void

**Effective date:** [EFFECTIVE DATE]

---

#### What is The Void?

The Void is a voice note app. You speak, it listens, transcribes your words, and gives you a moment to decide whether to save or discard them. That's it. There are no ads, no analytics, no social features, and no selling of your data.

---

#### What data we collect and why

**When you use the microphone**

The Void records audio while you are actively holding the record button. This audio is:
- Sent to your device's built-in speech recognition service (Google on Android, Apple on iOS) to produce a text transcript. This processing happens via the operating system — The Void does not send your audio to any server it controls.
- Optionally uploaded to our secure cloud storage if you choose to save the recording as a gem. If you do not tap "Rescue", the audio is discarded immediately and never leaves your device.

**When you save a gem**

Saving a gem requires signing in. When you save:
- The text transcript is stored in our database.
- The audio recording is stored in our private cloud storage.
- Both are associated with your account and are only accessible by you.

We store gems so you can access them across your devices.

**When you sign in**

We use Google Sign-In and Apple Sign-In. We receive from them:
- Your email address (used as your account identifier)
- A unique user ID from Google or Apple

We do not receive your password. We do not store your password. Authentication is handled entirely by Google and Apple.

**When you delete a gem**

Deleted gems are removed from our database and from cloud storage immediately. There are no soft-deletes or backups that retain your content after deletion.

**What we do not collect**

- We do not use any analytics or crash-reporting SDKs.
- We do not collect device identifiers, advertising IDs, or location data.
- We do not track how you use the app.
- We do not share any data with third parties for advertising purposes.

---

#### Third-party services

The Void uses the following services to function:

| Service | Purpose | Their privacy policy |
|---|---|---|
| Supabase | Database and file storage for saved gems | [supabase.com/privacy](https://supabase.com/privacy) |
| Google Sign-In | Authentication | [policies.google.com/privacy](https://policies.google.com/privacy) |
| Apple Sign-In | Authentication | [apple.com/legal/privacy](https://www.apple.com/legal/privacy) |
| Android SpeechRecognizer | On-device speech-to-text | [policies.google.com/privacy](https://policies.google.com/privacy) |
| Apple Speech framework | On-device speech-to-text | [apple.com/legal/privacy](https://www.apple.com/legal/privacy) |

We do not control how these services handle data on their end. We recommend reviewing their policies if you have questions about their practices.

---

#### Where your data is stored

Saved gems (transcripts and audio) are stored on Supabase infrastructure. Supabase uses AWS data centres. Data is encrypted in transit (TLS) and at rest.

Your data is logically isolated to your account. No other user can access your gems. Our database has row-level security rules that enforce this at the database layer — not just at the application layer.

---

#### Your rights

**Access:** You can view all your saved gems at any time inside the app.

**Deletion:** You can delete individual gems from within the app. You can delete your entire account — including all gems and audio — from the app's settings. Account deletion is permanent and immediate.

**Export:** If you want a copy of your data before deleting, copy the transcripts from within the app. We do not currently offer an automated export tool.

---

#### Children

The Void is not directed at children under 13 and we do not knowingly collect data from children under 13. If you believe a child has created an account, contact us and we will delete it.

---

#### Changes to this policy

If we make material changes to this policy, we will update the effective date at the top and, where appropriate, notify you via the app or email. Continued use of the app after changes constitutes acceptance.

---

#### Contact

Questions about this policy or your data:

**Email:** [YOUR EMAIL]
