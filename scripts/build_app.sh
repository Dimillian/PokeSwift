#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

tuist generate --no-open
xcodebuild -workspace PokeSwift.xcworkspace -scheme PokeExtractCLI -configuration Debug -derivedDataPath .build/DerivedData build
xcodebuild -workspace PokeSwift.xcworkspace -scheme PokeHarness -configuration Debug -derivedDataPath .build/DerivedData build
xcodebuild -workspace PokeSwift.xcworkspace -scheme PokeMac -configuration Debug -derivedDataPath .build/DerivedData build
