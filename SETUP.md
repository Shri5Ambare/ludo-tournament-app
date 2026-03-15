# 🚀 Setup & Deployment Guide — Ludo Tournament App

Complete guide to configure Supabase backend, build APK, and deploy.

---

## 1. 📦 Install Dependencies

```bash
cd ludo-tournament-app
flutter pub get
```

---

## 2. 🗄️ Supabase Setup (Online Multiplayer)

### 2.1 Create Supabase Project
1. Go to [supabase.com](https://supabase.com) → New Project
2. Note your **Project URL** and **anon key**

### 2.2 Update Credentials
Edit `lib/services/supabase_service.dart`:
```dart
const String kSupabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
const String kSupabaseAnonKey = 'YOUR_ANON_KEY_HERE';
```

### 2.3 Run SQL Schema
Execute in Supabase SQL Editor:

```sql
-- User profiles
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  avatar_emoji TEXT DEFAULT '🎮',
  level INT DEFAULT 1,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  coins INT DEFAULT 500,
  xp INT DEFAULT 0,
  win_streak INT DEFAULT 0,
  tournaments_won INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Online rooms
CREATE TABLE online_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID REFERENCES profiles(id),
  room_code TEXT UNIQUE NOT NULL,
  game_mode TEXT DEFAULT 'classic',
  turn_timer INT DEFAULT 30,
  max_players INT DEFAULT 4,
  status TEXT DEFAULT 'waiting',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Room players
CREATE TABLE room_players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES online_rooms(id) ON DELETE CASCADE,
  player_id UUID REFERENCES profiles(id),
  player_index INT NOT NULL,
  is_ready BOOLEAN DEFAULT FALSE,
  joined_at TIMESTAMPTZ DEFAULT NOW()
);

-- Game events (real-time dice/move sync)
CREATE TABLE game_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES online_rooms(id) ON DELETE CASCADE,
  player_id UUID,
  event_type TEXT NOT NULL,   -- 'roll', 'move', 'cut', 'win', 'chat'
  payload JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tournaments
CREATE TABLE tournaments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  host_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'setup',
  player_names TEXT[],
  champion_name TEXT,
  game_mode TEXT DEFAULT 'classic',
  turn_timer INT DEFAULT 30,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Realtime on game_events and room_players
ALTER PUBLICATION supabase_realtime ADD TABLE game_events;
ALTER PUBLICATION supabase_realtime ADD TABLE room_players;

-- Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE online_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_events ENABLE ROW LEVEL SECURITY;

-- Policies (public read, authenticated write)
CREATE POLICY "Public read profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Own profile write" ON profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "Public read rooms" ON online_rooms FOR SELECT USING (true);
CREATE POLICY "Host manages room" ON online_rooms FOR ALL USING (auth.uid() = host_id);
CREATE POLICY "Public read events" ON game_events FOR SELECT USING (true);
CREATE POLICY "Auth insert events" ON game_events FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
```

### 2.4 Add Supabase Flutter Package
Add to `pubspec.yaml`:
```yaml
dependencies:
  supabase_flutter: ^2.3.0
```

Then initialize in `main.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );
  
  // ... rest of init
  runApp(const ProviderScope(child: LudoTournamentApp()));
}
```

---

## 3. 🔔 Push Notifications (FCM)

### 3.1 Firebase Setup
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project → Add Android app
3. Download `google-services.json` → place in `android/app/`

### 3.2 Add Dependencies
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.2
```

### 3.3 Request Permission (iOS)
```dart
await FirebaseMessaging.instance.requestPermission(
  alert: true, badge: true, sound: true,
);
```

---

## 4. 📱 Build APK

### 4.1 Debug APK (quick test)
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### 4.2 Release APK (for distribution)

**Step 1 — Create keystore:**
```bash
keytool -genkey -v \
  -keystore android/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ludo-key
```

**Step 2 — Create `android/key.properties`:**
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=ludo-key
storeFile=../keystore.jks
```

**Step 3 — Build:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 4.3 App Bundle (Google Play)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 4.4 Split APKs (smaller downloads)
```bash
flutter build apk --split-per-abi
# Creates: app-arm64-v8a-release.apk, app-armeabi-v7a-release.apk, etc.
```

---

## 5. 🍎 iOS Build

```bash
# Open in Xcode
open ios/Runner.xcworkspace

# Build from command line
flutter build ios --release
```

Required:
- Apple Developer account ($99/year)
- Certificates and provisioning profiles in Xcode

---

## 6. 🌐 Environment Configuration

Create `lib/config/env.dart`:
```dart
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://YOUR_PROJECT.supabase.co');
  static const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue: 'YOUR_ANON_KEY');
}
```

Build with env vars:
```bash
flutter build apk --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
```

---

## 7. 📊 Analytics (Optional)

Add `firebase_analytics` for player behavior tracking:
```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'game_complete',
  parameters: {'winner': winnerName, 'mode': gameMode},
);
```

---

## 8. ✅ Pre-launch Checklist

- [ ] Supabase project created and SQL schema applied
- [ ] `kSupabaseUrl` and `kSupabaseAnonKey` updated
- [ ] Keystore created and `key.properties` configured
- [ ] App icon added to `android/app/src/main/res/`
- [ ] Splash screen assets added to `assets/images/`
- [ ] Audio files added to `assets/audio/`
- [ ] Fonts added to `assets/fonts/`
- [ ] `google-services.json` added for FCM (optional)
- [ ] ProGuard rules verified
- [ ] Release APK tested on physical device
- [ ] Play Store listing created (screenshots, description)

---

## 9. 🗂️ Project Structure

```
ludo-tournament-app/
├── lib/
│   ├── ai/                 # AI bot engine
│   ├── core/               # Constants, router, theme
│   ├── game_engine/        # Core Ludo rules
│   ├── models/             # Data models + Hive adapters
│   ├── providers/          # Riverpod state
│   ├── screens/            # All UI screens
│   │   ├── game/           # Lobby, Game, Result, Hotspot
│   │   ├── home/           # Home, Splash, Shop, Rewards, Leaderboard
│   │   ├── online/         # Online room lobby
│   │   ├── settings/       # Settings, Profile
│   │   └── tournament/     # Setup, Bracket, History
│   ├── services/           # Supabase, Audio, LAN, Notifications
│   ├── utils/              # Share utils
│   └── widgets/            # Board, Dice, Token, Common, Tournament
├── android/                # Android build config
├── ios/                    # iOS build config
├── assets/                 # Images, audio, fonts
└── test/                   # Unit & widget tests
```

---

Built with ❤️ by **SSiT Nexus** · [ssitnexus.com](https://ssitnexus.com)
