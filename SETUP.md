# 🚀 Ludo Tournament App — Complete Setup Guide

---

## 1. 📦 Install Flutter Dependencies

```bash
cd ludo-tournament-app
flutter pub get
```

---

## 2. 🗄️ Supabase Setup (Online Multiplayer)

### 2.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com) → **New Project**
2. Choose region: `ap-southeast-1` (Singapore) for Nepal/South Asia
3. Note your **Project URL** and **anon key** from Settings → API

### 2.2 Set Credentials

**Option A — Hardcode (dev only):**
Edit `lib/services/supabase_service.dart`:
```dart
const String kSupabaseUrl  = 'https://xxxxxxxxxxxx.supabase.co';
const String kSupabaseAnonKey = 'eyJhbGciOi...';
```

**Option B — dart-define (recommended):**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

---

### 2.3 SQL Schema

Run in **Supabase → SQL Editor → New Query**:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles
CREATE TABLE IF NOT EXISTS profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username        TEXT UNIQUE NOT NULL,
  avatar_emoji    TEXT DEFAULT '🎮',
  level           INT DEFAULT 1,
  wins            INT DEFAULT 0,
  losses          INT DEFAULT 0,
  coins           INT DEFAULT 500,
  xp              INT DEFAULT 0,
  win_streak      INT DEFAULT 0,
  tournaments_won INT DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Online rooms
CREATE TABLE IF NOT EXISTS online_rooms (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  room_code   TEXT UNIQUE NOT NULL,
  game_mode   TEXT DEFAULT 'classic' CHECK (game_mode IN ('classic', 'quick')),
  turn_timer  INT DEFAULT 30,
  max_players INT DEFAULT 4 CHECK (max_players BETWEEN 2 AND 4),
  status      TEXT DEFAULT 'waiting'
              CHECK (status IN ('waiting', 'starting', 'in_progress', 'finished')),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS rooms_code_idx ON online_rooms(room_code);

-- Room players
CREATE TABLE IF NOT EXISTS room_players (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id       UUID REFERENCES online_rooms(id) ON DELETE CASCADE NOT NULL,
  player_id     UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  player_name   TEXT NOT NULL,
  player_index  INT NOT NULL CHECK (player_index BETWEEN 0 AND 3),
  is_ready      BOOL DEFAULT FALSE,
  is_host       BOOL DEFAULT FALSE,
  joined_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(room_id, player_id),
  UNIQUE(room_id, player_index)
);

-- Game events  (Realtime source of truth for sync)
CREATE TABLE IF NOT EXISTS game_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id     UUID REFERENCES online_rooms(id) ON DELETE CASCADE NOT NULL,
  player_id   UUID,
  event_type  TEXT NOT NULL,
  payload     JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS events_room_idx ON game_events(room_id, created_at);

-- Spectators
CREATE TABLE IF NOT EXISTS spectators (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id      UUID REFERENCES online_rooms(id) ON DELETE CASCADE NOT NULL,
  user_id      UUID REFERENCES profiles(id) ON DELETE CASCADE,
  username     TEXT NOT NULL,
  avatar_emoji TEXT DEFAULT '👀',
  joined_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

-- Friend requests
CREATE TABLE IF NOT EXISTS friend_requests (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_id    UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  to_id      UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status     TEXT DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(from_id, to_id)
);

-- Game invites
CREATE TABLE IF NOT EXISTS game_invites (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_id    UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  to_id      UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  room_code  TEXT NOT NULL,
  game_mode  TEXT DEFAULT 'classic',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '10 minutes')
);

-- Tournaments
CREATE TABLE IF NOT EXISTS tournaments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  host_id       UUID REFERENCES profiles(id),
  status        TEXT DEFAULT 'active',
  player_names  TEXT[] DEFAULT '{}',
  champion_name TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 2.4 Row Level Security (RLS)

```sql
-- Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_read"   ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (id = auth.uid());

-- Rooms
ALTER TABLE online_rooms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rooms_read"   ON online_rooms FOR SELECT USING (true);
CREATE POLICY "rooms_insert" ON online_rooms FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "rooms_update" ON online_rooms FOR UPDATE USING (host_id = auth.uid());

-- Room players
ALTER TABLE room_players ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rp_read"   ON room_players FOR SELECT USING (true);
CREATE POLICY "rp_insert" ON room_players FOR INSERT WITH CHECK (player_id = auth.uid());
CREATE POLICY "rp_update" ON room_players FOR UPDATE USING (player_id = auth.uid());
CREATE POLICY "rp_delete" ON room_players FOR DELETE USING (player_id = auth.uid());

-- Game events
ALTER TABLE game_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ge_read"   ON game_events FOR SELECT USING (true);
CREATE POLICY "ge_insert" ON game_events FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Spectators
ALTER TABLE spectators ENABLE ROW LEVEL SECURITY;
CREATE POLICY "spec_read"   ON spectators FOR SELECT USING (true);
CREATE POLICY "spec_insert" ON spectators FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "spec_delete" ON spectators FOR DELETE USING (user_id = auth.uid());

-- Friend requests
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "fr_read"   ON friend_requests FOR SELECT
  USING (from_id = auth.uid() OR to_id = auth.uid());
CREATE POLICY "fr_insert" ON friend_requests FOR INSERT WITH CHECK (from_id = auth.uid());
CREATE POLICY "fr_update" ON friend_requests FOR UPDATE USING (to_id = auth.uid());

-- Game invites
ALTER TABLE game_invites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "gi_read"   ON game_invites FOR SELECT
  USING (from_id = auth.uid() OR to_id = auth.uid());
CREATE POLICY "gi_insert" ON game_invites FOR INSERT WITH CHECK (from_id = auth.uid());
CREATE POLICY "gi_delete" ON game_invites FOR DELETE
  USING (from_id = auth.uid() OR to_id = auth.uid());
```

---

### 2.5 Enable Realtime

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE game_events;
ALTER PUBLICATION supabase_realtime ADD TABLE room_players;
ALTER PUBLICATION supabase_realtime ADD TABLE spectators;
ALTER PUBLICATION supabase_realtime ADD TABLE game_invites;
```

Or via Dashboard: **Database → Replication → Tables** → toggle each table.

### 2.6 Auth Settings

**Authentication → Providers:**
- ✅ Email/Password
- ✅ Anonymous sign-ins (for guest mode)

---

## 3. 🎵 Audio Assets

Place `.mp3` files in `assets/audio/`:

| File | Used for |
|------|----------|
| `dice_roll.mp3` | Dice rolling |
| `token_move.mp3` | Token moving on board |
| `token_cut.mp3` | Token getting cut |
| `token_home.mp3` | Token reaching home |
| `game_win.mp3` | Win fanfare |
| `game_lose.mp3` | Loss sound |
| `bg_music.mp3` | Background music loop |
| `button_tap.mp3` | UI button tap |

Free sources: [freesound.org](https://freesound.org) · [mixkit.co](https://mixkit.co/free-sound-effects/)

---

## 4. 🔤 Font Assets

Place in `assets/fonts/`:
- `Fredoka-Regular.ttf`, `Fredoka-Bold.ttf`
- `Nunito-Regular.ttf`, `Nunito-Bold.ttf`

Download: [fonts.google.com](https://fonts.google.com)

---

## 5. 📦 Build APK

### Debug APK

```bash
flutter build apk --debug \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
# → build/app/outputs/flutter-apk/app-debug.apk
```

### Generate Release Keystore (once)

```bash
mkdir -p android/keystore
keytool -genkey -v \
  -keystore android/keystore/release.jks \
  -alias ludo_tournament \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass YOUR_STORE_PASS \
  -keypass YOUR_KEY_PASS \
  -dname "CN=SSiT Nexus,OU=Mobile,O=SSiT Nexus,L=Kathmandu,ST=Bagmati,C=NP"
```

Create `android/key.properties` (**add to `.gitignore`**):
```properties
storePassword=YOUR_STORE_PASS
keyPassword=YOUR_KEY_PASS
keyAlias=ludo_tournament
storeFile=../keystore/release.jks
```

Add to `android/app/build.gradle` (inside `android {}`):
```groovy
def keystoreProperties = new Properties()
def kpFile = rootProject.file('key.properties')
if (kpFile.exists()) keystoreProperties.load(new FileInputStream(kpFile))

signingConfigs {
    release {
        keyAlias     keystoreProperties['keyAlias']
        keyPassword  keystoreProperties['keyPassword']
        storeFile    keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### Release APK

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
# → build/app/outputs/flutter-apk/app-release.apk
```

### Play Store Bundle (AAB)

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
# → build/app/outputs/bundle/release/app-release.aab
```

---

## 6. ✅ Pre-launch Checklist

- [ ] Supabase URL + anon key configured
- [ ] SQL schema applied in Supabase SQL Editor
- [ ] RLS policies applied
- [ ] Realtime enabled on `game_events`, `room_players`, `spectators`, `game_invites`
- [ ] Anonymous sign-ins enabled in Auth settings
- [ ] Audio files in `assets/audio/`
- [ ] Font files in `assets/fonts/`
- [ ] `applicationId` updated (`android/app/build.gradle`)
- [ ] Release keystore generated + `key.properties` created
- [ ] Tested on device: `flutter run --release`
- [ ] Tested LAN/Hotspot mode
- [ ] Tested online: create room on one device, join on another

---

## 7. 🛠️ Useful Commands

```bash
flutter run                          # debug
flutter run --release                # release mode on device
flutter analyze                      # static analysis
flutter test                         # unit tests
flutter clean && flutter pub get     # reset build cache
flutter pub outdated                 # check for dep updates
```

---

*Built by SSiT Nexus · [ssitnexus.com](https://ssitnexus.com)*
