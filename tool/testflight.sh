#!/bin/bash
# Сборка релизного IPA и заливка в TestFlight с этой машины.
#
# Нужен когда Codemagic не настроен или хочется залить руками. Ключ
# App Store Connect позволяет xcodebuild самому выпустить сертификат
# распространения и профиль — членство в команде на этой машине для
# этого не требуется.
#
# Что нужно один раз:
#   mkdir -p ~/private_keys
#   cp AuthKey_XB3J3M6383.p8 ~/private_keys/
#
# Запуск:  ./tool/testflight.sh
set -euo pipefail

KEY_ID="XB3J3M6383"
ISSUER_ID="a7b3038d-738d-4f94-81ec-00124cddfd4b"
TEAM_ID="AZWU5VAA73"
BUNDLE_ID="com.pavelhegai.volna"
KEY_PATH="$HOME/private_keys/AuthKey_${KEY_ID}.p8"

cd "$(dirname "$0")/.."

if [ ! -f "$KEY_PATH" ]; then
  echo "Нет ключа App Store Connect: $KEY_PATH"
  echo "Скачай AuthKey_${KEY_ID}.p8 и положи туда:"
  echo "  mkdir -p ~/private_keys && cp ~/Downloads/AuthKey_${KEY_ID}.p8 ~/private_keys/"
  exit 1
fi

if ! grep -q "azureOpenAiApiKey = '.\+'" lib/config/secrets.dart 2>/dev/null; then
  echo "В lib/config/secrets.dart пустой ключ Azure — облачное «выговорись»"
  echo "в этой сборке работать не будет. Прерываю; убери проверку, если так и надо."
  exit 1
fi

# Номер сборки: берём последний из TestFlight и увеличиваем. Так вторая
# заливка не отбивается по дублю.
echo "→ узнаю последний номер сборки в TestFlight"
LATEST=$(xcrun altool --list-builds \
  --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID" --output-format json 2>/dev/null \
  | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    ns=[int(b['buildVersion']) for p in d.get('builds',[]) for b in [p] if str(b.get('buildVersion','')).isdigit()]
    print(max(ns) if ns else 0)
except Exception:
    print(0)
" || echo 0)
BUILD=$((LATEST + 1))
NAME=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
echo "  версия $NAME, сборка $BUILD (в TestFlight было $LATEST)"

echo "→ проверки"
flutter analyze
flutter test

echo "→ собираю IPA"
flutter build ipa --release \
  --build-name="$NAME" \
  --build-number="$BUILD" \
  --export-options-plist=/dev/null 2>/dev/null || true

# flutter build ipa без готового export plist оставляет .xcarchive —
# экспортируем сами, чтобы xcodebuild мог выпустить профиль по ключу.
ARCHIVE=$(ls -dt build/ios/archive/*.xcarchive 2>/dev/null | head -1)
if [ -z "$ARCHIVE" ]; then
  echo "Архив не собрался — смотри вывод выше"; exit 1
fi

cat > /tmp/volna_export.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>${TEAM_ID}</string>
  <key>destination</key><string>upload</string>
  <key>uploadSymbols</key><true/>
</dict></plist>
PLIST

echo "→ экспортирую и заливаю в TestFlight"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist /tmp/volna_export.plist \
  -exportPath build/ios/ipa \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER_ID"

echo
echo "Готово. Сборка $NAME ($BUILD) для $BUNDLE_ID ушла в App Store Connect."
echo "Обработка занимает 5–20 минут, потом билд появится в TestFlight."
