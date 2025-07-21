#!/usr/bin/env bash

echo "🧨 Removing all Chromium containers..."

docker ps -a --format '{{.Names}}' | grep '^chromium_' | while read -r name; do
  echo "❌ Stopping and removing $name"
  docker rm -f "$name"
done

echo "✅ All chromium containers removed."
