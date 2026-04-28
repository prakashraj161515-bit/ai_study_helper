#!/bin/bash

# Download Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi
export PATH="$PATH:`pwd`/flutter/bin"

# Pre-cache binaries
flutter doctor

# Clean and Get packages
flutter clean
flutter pub get

# Enable web
flutter config --enable-web

# Build web
flutter build web --release
