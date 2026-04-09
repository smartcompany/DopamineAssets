#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.6}"
BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux"
ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

echo "[vercel-build] Flutter ${FLUTTER_VERSION}"
curl -fsSL "${BASE_URL}/${ARCHIVE}" -o /tmp/flutter.tar.xz
tar -xf /tmp/flutter.tar.xz -C /tmp
export PATH="/tmp/flutter/bin:${PATH}"

# Vercel은 root로 빌드됨. Flutter SDK가 내부적으로 git을 쓰는데, Git 2.35+ 가
# "dubious ownership" 으로 거절하면 flutter --version 단계에서 exit 128 난다.
git config --global --add safe.directory /tmp/flutter

# private git dependency 시 (선택): Vercel 에 GITHUB_TOKEN 등 설정 후 주석 해제
# git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"

flutter --version
flutter config --no-analytics --enable-web
flutter pub get
flutter build web --release
