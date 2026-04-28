#!/bin/bash

# Download Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Pre-cache binaries
flutter doctor

# Enable web
flutter config --enable-web

# Build web
flutter build web --release
