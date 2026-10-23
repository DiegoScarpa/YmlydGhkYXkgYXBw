#!/bin/bash
set -euo pipefail

DEVICE_ID=$(xcrun simctl list -j devices available | python3 -c 'import json,sys; groups=json.load(sys.stdin)["devices"]; print(next(device["udid"] for devices in groups.values() for device in devices if device["name"].startswith("iPhone") and device["state"] == "Shutdown"))')
APP_PATH=$(find "$HOME/Library/Developer/Xcode/DerivedData" -type d -path '*/Build/Products/Debug-iphonesimulator/Remember.app' -print -quit)
test -n "$DEVICE_ID"
test -d "$APP_PATH"

xcrun simctl boot "$DEVICE_ID"
xcrun simctl bootstatus "$DEVICE_ID" -b
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
xcrun simctl launch "$DEVICE_ID" com.diegoscarpa.Remember
sleep 3
xcrun simctl io "$DEVICE_ID" screenshot "$RUNNER_TEMP/remember-home.png"
