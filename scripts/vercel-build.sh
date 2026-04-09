#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.6}"
BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux"
ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

echo "[vercel-build] Flutter ${FLUTTER_VERSION}"
curl -fsSL "${BASE_URL}/${ARCHIVE}" -o /tmp/flutter.tar.xz
tar -xf /tmp/flutter.tar.xz -C /tmp
export PATH="/tmp/flutter/bin:${PATH}"

# private git dependency 시 (선택): Vercel 에 GITHUB_TOKEN 등 설정 후 주석 해제
# git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"

flutter --version
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release
