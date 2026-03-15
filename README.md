# 🎲 Ludo Tournament App

A full-featured Flutter Ludo game with **Tournament Mode** — inspired by Ludo King, built by [SSiT Nexus](https://ssitnexus.com).

---

## ✨ Features

### 🎮 Core Game (Ludo King Parity)
- Classic Ludo rules — roll dice, move tokens, cut opponents
- 2–4 players: Human vs Human or Human vs AI
- Safe zones (star squares), home column, token cutting
- 3 consecutive sixes → lose turn
- Turn timer (15s / 30s / 45s)
- Multiple game modes: Classic, Quick, Master

### 🤖 AI Engine
- **Easy** — random moves
- **Medium** — prioritizes cuts and unlocks
- **Hard** — scored decision tree with danger awareness

### 🏆 Tournament Mode (Exclusive Feature)
- **5–16 players** in bracket-style competition
- Auto-divides into groups of 4
- Bots fill empty slots automatically
- Group Stage → Finals → Champion
- Offline (single device), Hotspot LAN, Online modes
- Live bracket visualization

### 🎨 UI/UX
- Dark / Light theme
- 5 board themes: Classic, Neon, Space, Forest, Diwali
- Smooth animations (flutter_animate)
- Confetti on win
- Player profiles, XP, coins, achievements

---

## 🏗 Project Structure

```
lib/
├── core/
│   ├── constants/       # Board paths, game constants
│   ├── router/          # GoRouter navigation
│   └── theme/           # App theme & colors
├── models/              # Game, Player, Token, Tournament
├── game_engine/         # Core Ludo logic engine
├── ai/                  # AI bot decision engine
├── providers/           # Riverpod state management
├── screens/
│   ├── home/            # Splash, Home
│   ├── game/            # Lobby, Game board, Result
│   ├── tournament/      # Setup, Bracket
│   └── settings/        # Settings, Profile
└── widgets/
    ├── board/           # Ludo board painter & tokens
    └── dice/            # Animated dice widget
```

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.10+ |
| State | Riverpod 2.x |
| Navigation | GoRouter |
| Storage | Hive + SharedPreferences |
| Animations | flutter_animate + Lottie |
| Audio | audioplayers |
| Fonts | Google Fonts (Fredoka + Nunito) |
| Confetti | confetti |

---

## 🚀 Getting Started

```bash
# Clone repo
git clone https://github.com/Shri5Ambare/ludo-tournament-app.git
cd ludo-tournament-app

# Install deps
flutter pub get

# Run
flutter run
```

### Requirements
- Flutter SDK ≥ 3.10.0
- Dart ≥ 3.0.0
- Android SDK 21+ / iOS 12+

---

## 🗺 Roadmap

- [x] Phase 1: Core game engine + board
- [x] Phase 2: Local multiplayer
- [x] Phase 3: AI bots (Easy/Medium/Hard)
- [x] Phase 4: Tournament Mode (offline)
- [ ] Phase 5: Hotspot LAN multiplayer
- [ ] Phase 6: Online backend (Supabase)
- [ ] Phase 7: UI polish, themes, sounds

---

## 👨‍💻 Built By

**SSiT Nexus** — *Building Tomorrow's Technology Today*  
🌐 [ssitnexus.com](https://ssitnexus.com) | 🇳🇵 Kathmandu, Nepal

---

## 📄 License

MIT License — free to use and modify.
