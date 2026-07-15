#!/usr/bin/env bash
# Build the Flutter web example.
# --no-tree-shake-icons is required because json_theme uses non-constant IconData.
set -e
cd "$(dirname "$0")"
flutter build web --no-tree-shake-icons "$@"
