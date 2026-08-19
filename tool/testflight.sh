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

# Номер сборки берём из pubspec (часть после «+»), с возможностью
# переопределить: BUILD=42 ./tool/testflight.sh
# Apple отбивает повторную заливку с тем же номером — тогда просто
# подними «+N» в pubspec.yaml.
NAME=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
BUILD="${BUILD:-$(grep '^version:' pubspec.yaml | cut -d'+' -f2)}"
echo "→ версия $NAME, сборка $BUILD"

echo "→ проверки"
flutter analyze
flutter test

echo "→ собираю архив"
# Через xcodebuild, а не `flutter build ipa`: последний не умеет
# принимать ключ App Store Connect, а без него на этой машине нечем
# подписать — сертификата распространения команды заказчика здесь нет.
# С -allowProvisioningUpdates и ключом Xcode выпустит сертификат сам и
# оставит приватный ключ в локальной связке.
ARCHIVE="build/ios/archive/Runner.xcarchive"
rm -rf "$ARCHIVE"
xcodebuild archive \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath "$ARCHIVE" \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER_ID" \
  FLUTTER_BUILD_NAME="$NAME" \
  FLUTTER_BUILD_NUMBER="$BUILD"

if [ ! -d "$ARCHIVE" ]; then
  echo "Архив не собрался — смотри вывод выше"; exit 1
fi

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
