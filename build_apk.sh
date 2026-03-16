#!/usr/bin/env bash
# build_apk.sh — Build debug + release APKs for Ludo Tournament App
#
# Usage:
#   ./build_apk.sh                           # build both
#   ./build_apk.sh debug                     # debug only
#   ./build_apk.sh release                   # release only
#   SUPABASE_URL=https://xxx.supabase.co \
#   SUPABASE_ANON_KEY=eyJhb... ./build_apk.sh
#
# Output APKs go to: build/apk/

set -e

SUPABASE_URL="${SUPABASE_URL:-https://YOUR_PROJECT.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-YOUR_ANON_KEY}"
OUT_DIR="build/apk"
MODE="${1:-both}"

DART_DEFINES="--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"

mkdir -p "$OUT_DIR"

echo "══════════════════════════════════════════"
echo "  Ludo Tournament App — APK Builder"
echo "══════════════════════════════════════════"

# ── Debug APK ──────────────────────────────────────────────────────────────────
build_debug() {
  echo ""
  echo "▶ Building DEBUG APK..."
  flutter build apk --debug $DART_DEFINES

  SRC="build/app/outputs/flutter-apk/app-debug.apk"
  DEST="$OUT_DIR/ludo-tournament-debug.apk"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$DEST"
    SIZE=$(du -sh "$DEST" | cut -f1)
    echo "✅ Debug APK: $DEST ($SIZE)"
  else
    echo "❌ Debug APK not found at $SRC"
    exit 1
  fi
}

# ── Release APK ────────────────────────────────────────────────────────────────
build_release() {
  echo ""
  echo "▶ Building RELEASE APK..."

  # Check keystore exists
  if [ ! -f "android/keystore/release.jks" ]; then
    echo "⚠️  No keystore found — building with debug signing"
    echo "   Run: keytool -genkey -v -keystore android/keystore/release.jks ..."
  fi

  flutter build apk --release $DART_DEFINES

  SRC="build/app/outputs/flutter-apk/app-release.apk"
  DEST="$OUT_DIR/ludo-tournament-release.apk"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$DEST"
    SIZE=$(du -sh "$DEST" | cut -f1)
    echo "✅ Release APK: $DEST ($SIZE)"
  else
    echo "❌ Release APK not found at $SRC"
    exit 1
  fi

  # Also build fat universal APK
  SRC_FAT="build/app/outputs/flutter-apk/app-release.apk"
  if [ -f "$SRC_FAT" ]; then
    cp "$SRC_FAT" "$OUT_DIR/ludo-tournament-universal.apk"
    echo "✅ Universal APK: $OUT_DIR/ludo-tournament-universal.apk"
  fi
}

# ── AAB (Play Store) ───────────────────────────────────────────────────────────
build_aab() {
  echo ""
  echo "▶ Building Release AAB (Play Store)..."
  flutter build appbundle --release $DART_DEFINES

  SRC="build/app/outputs/bundle/release/app-release.aab"
  DEST="$OUT_DIR/ludo-tournament-release.aab"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$DEST"
    SIZE=$(du -sh "$DEST" | cut -f1)
    echo "✅ Release AAB: $DEST ($SIZE)"
  fi
}

# ── Run selected builds ────────────────────────────────────────────────────────
case "$MODE" in
  debug)   build_debug ;;
  release) build_release ;;
  aab)     build_aab ;;
  both)    build_debug; build_release ;;
  all)     build_debug; build_release; build_aab ;;
  *)
    echo "Unknown mode: $MODE"
    echo "Usage: $0 [debug|release|aab|both|all]"
    exit 1
    ;;
esac

echo ""
echo "══════════════════════════════════════════"
echo "  Done! APKs saved to: $OUT_DIR/"
ls -lh "$OUT_DIR"/ 2>/dev/null
echo "══════════════════════════════════════════"
